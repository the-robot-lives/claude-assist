using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using UnityEngine;
using UnityEngine.Networking;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.CodeGen;
using TheRobotDraft.Llm;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// The "Generate code" feature: turns a UML element into source. A deterministic offline skeleton
    /// (<see cref="CodeSkeleton"/>) is shown immediately, then — if an LLM endpoint is configured
    /// (<see cref="LlmSettings"/>) — an OpenAI-compatible chat request refines it in place. The generation
    /// context (<see cref="CodeGenContext"/>) folds in the element's members, its Description, the text of any
    /// UML notes attached to it, and its relationships (collaborators it uses / is used by, plus the base
    /// classes and interfaces it extends / implements, each carrying the collaborator's member API). Reuses the
    /// canvas's model (<c>_model</c>) and modal/menu helpers from the other partials.
    /// </summary>
    public sealed partial class UmlCanvas
    {
        // --- context builder ---

        /// <summary>
        /// Gather everything the generator needs for one element: its identity + Description, its attribute /
        /// operation members, the text of notes anchored to it, and its relationships (uses / used-by / extends /
        /// implements) with each collaborator's own member API.
        /// </summary>
        private CodeGenContext BuildCodeContext(ElementId id)
        {
            var ctx = new CodeGenContext();
            if (!_model.TryGet(id, out var el)) return ctx;

            ctx.Name = el.Name;
            ctx.Kind = el.Kind;
            ctx.Language = el.Language;
            ctx.Stereotype = el.Stereotype;
            ctx.IsAbstract = el.IsAbstract;
            ctx.Description = el.Description;
            ctx.CodeDoc = el.CodeDoc;
            ctx.DeepLinkUuid = el.DeepLinkUuid;
            ctx.DeepLinkCode = el.DeepLinkCode;
            ctx.EmbedDeepLinkCode = el.EmbedDeepLinkCode;

            // The original imported source (overlay round-trip), keyed by the element's source-file path.
            if (!string.IsNullOrEmpty(el.SourceFile) && _sourceFiles.TryGetValue(el.SourceFile, out var orig))
            {
                ctx.OriginalSource = orig;
                ctx.OriginalSourcePath = el.SourceFile;
            }

            // Members (attributes / operations) live as child elements; their UML signature is the child's Name,
            // and the member's doc-comment is its Description. Keep the comment lists index-aligned with the members.
            foreach (var childId in el.ChildIds)
            {
                if (!_model.TryGet(childId, out var c)) continue;
                string doc = !string.IsNullOrWhiteSpace(c.CodeDoc) ? c.CodeDoc : c.Description;
                if (c.Kind == ElementKind.Field)
                {
                    ctx.Attributes.Add(c.Name);
                    ctx.AttributeComments.Add(doc ?? "");
                    ctx.AttributeDeepLinks.Add(new CodeGenContext.MemberDeepLink
                    {
                        Uuid = c.DeepLinkUuid,
                        Code = c.DeepLinkCode,
                        Embed = c.EmbedDeepLinkCode,
                        Name = c.Name,
                        Kind = c.Kind,
                    });
                }
                else if (c.Kind == ElementKind.Function)
                {
                    ctx.Operations.Add(c.Name);
                    ctx.OperationComments.Add(doc ?? "");
                    ctx.OperationDeepLinks.Add(new CodeGenContext.MemberDeepLink
                    {
                        Uuid = c.DeepLinkUuid,
                        Code = c.DeepLinkCode,
                        Embed = c.EmbedDeepLinkCode,
                        Name = c.Name,
                        Kind = c.Kind,
                    });
                }
            }

            // Walk every edge touching this element to fold in notes + relationships.
            foreach (var edge in _model.Edges)
            {
                bool fromMe = edge.From == id;
                bool toMe = edge.To == id;
                if (!fromMe && !toMe) continue;

                ElementId otherId = fromMe ? edge.To : edge.From;
                if (!_model.TryGet(otherId, out var other)) continue;

                // A note anchored to this element → fold its text in (regardless of edge direction).
                if (edge.Kind == EdgeKind.NoteLink)
                {
                    if (other.Kind == ElementKind.Note && !string.IsNullOrWhiteSpace(other.Name))
                        ctx.AttachedNotes.Add(other.Name);
                    continue;
                }

                // Supertype / interface — only meaningful in the outgoing (from==id) direction.
                if (fromMe && edge.Kind == EdgeKind.Generalization)
                {
                    ctx.Relationships.Add(MakeRelationship(
                        CodeGenContext.RelKind.Extends, CodeGenContext.RelDirection.Out, edge, other));
                    continue;
                }
                if (fromMe && edge.Kind == EdgeKind.Realization)
                {
                    ctx.Relationships.Add(MakeRelationship(
                        CodeGenContext.RelKind.Implements, CodeGenContext.RelDirection.Out, edge, other));
                    continue;
                }

                // Collaborators / dependencies. Outgoing = something this element uses; incoming = a caller.
                if (IsCollaboratorEdge(edge.Kind))
                {
                    var kind = fromMe ? CodeGenContext.RelKind.Uses : CodeGenContext.RelKind.UsedBy;
                    var dir = fromMe ? CodeGenContext.RelDirection.Out : CodeGenContext.RelDirection.In;
                    ctx.Relationships.Add(MakeRelationship(kind, dir, edge, other));
                }
            }

            return ctx;
        }

        /// <summary>Class-diagram relationships that read as "collaborates with" (not inheritance, not a note anchor).</summary>
        private static bool IsCollaboratorEdge(EdgeKind k) =>
            k == EdgeKind.Association || k == EdgeKind.DirectedAssociation || k == EdgeKind.Dependency
            || k == EdgeKind.Aggregation || k == EdgeKind.Composition;

        /// <summary>Build one <see cref="CodeGenContext.Relationship"/>, including the other element's member API.</summary>
        private CodeGenContext.Relationship MakeRelationship(
            CodeGenContext.RelKind kind, CodeGenContext.RelDirection dir, ModelEdge edge, ModelElement other)
        {
            var rel = new CodeGenContext.Relationship
            {
                Kind = kind,
                Direction = dir,
                Edge = edge.Kind,
                OtherName = other.Name,
                OtherKind = other.Kind,
                Label = edge.Label,
                SrcMultiplicity = edge.SourceMultiplicity,
                TgtMultiplicity = edge.TargetMultiplicity,
            };
            foreach (var childId in other.ChildIds)
            {
                if (!_model.TryGet(childId, out var c)) continue;
                if (c.Kind == ElementKind.Field) rel.OtherAttributes.Add(c.Name);
                else if (c.Kind == ElementKind.Function) rel.OtherOperations.Add(c.Name);
            }
            return rel;
        }

        // --- wireframe (Screen / Panel) generation ---

        /// <summary>Build the widget inventory for a Screen/Panel region, in authored child order.</summary>
        private WireframeContext BuildWireframeContext(ElementId id)
        {
            var wf = new WireframeContext();
            if (!_model.TryGet(id, out var el)) return wf;
            wf.Name = el.Name;
            wf.RegionKind = el.Kind;
            foreach (var childId in el.ChildIds)
            {
                if (!_model.TryGet(childId, out var c) || !KindInfo.IsWireframeWidget(c.Kind)) continue;
                var w = new WireframeContext.Widget { Kind = c.Kind, Label = c.Name };
                // Element-owned items are the widget's options/rows/columns; Field children are legacy fallback.
                foreach (var item in c.Items)
                    if (!string.IsNullOrWhiteSpace(item))
                        w.Items.Add(item);
                foreach (var itemId in c.ChildIds)
                    if (_model.TryGet(itemId, out var item) && item.Kind == ElementKind.Field)
                        w.Items.Add(item.Name);
                wf.Widgets.Add(w);
            }
            return wf;
        }

        /// <summary>Open the viewer seeded with an HTML mockup, with a PlantUML salt block as the LLM seed.</summary>
        private void GenerateWireframeForElement(ElementId id)
        {
            var wf = BuildWireframeContext(id);
            WireframeSkeleton.ThemeRootVars = ThemeCssRootVars(); // inline the resolved styleguide tokens, if any
            string html = WireframeSkeleton.GenerateHtml(wf);
            string salt = WireframeSkeleton.GenerateSalt(wf);

            // Seed the viewer with the HTML (the primary handoff artifact); carry the salt as the LLM refinement seed
            // so a configured endpoint can polish the mockup into a fuller page.
            string title = $"Wireframe — {(string.IsNullOrWhiteSpace(wf.Name) ? "screen" : wf.Name)}";
            ShowCodeViewer(title, html, "HTML mockup (PlantUML salt in Console log)", id, null, "html");
            Flash(wf.Widgets.Count > 0
                ? $"wireframe: {wf.Widgets.Count} widgets  (HTML + PlantUML salt)"
                : "empty screen — add widgets first");
            // The salt is emitted to the log so it can be copy-pasted into a PlantUML renderer; the viewer shows HTML.
            if (!string.IsNullOrEmpty(LlmSettings.BaseUrl))
                Debug.Log("[WireframeSkeleton] salt:\n" + salt);
        }

        /// <summary>Resolved styleguide CSS-var block for the loaded theme (or null when no theme is active).</summary>
        private static string ThemeCssRootVars() => null; // wired by the theme feature once loaded (Feature B)

        // --- public entry points ---

        /// <summary>
        /// Generate source for a single element: open the viewer seeded with the deterministic skeleton, then
        /// (when an endpoint is configured) refine it asynchronously via the LLM.
        /// </summary>
        public void GenerateCodeForElement(ElementId id)
        {
            CloseMenu();
            if (!_model.TryGet(id, out var el)) { Flash("nothing to generate"); return; }

            // A wireframe region (Screen / Panel) generates an HTML mockup + PlantUML salt block instead of a class
            // skeleton — the artifacts that make a wireframe usable for handoff.
            if (KindInfo.IsWireframeRegion(el.Kind))
            {
                GenerateWireframeForElement(id);
                return;
            }

            var ctx = BuildCodeContext(id);
            string skeleton = CodeSkeleton.Generate(ctx);

            System.Action<string, string> setText = null;

            // (Re)run generation into the open viewer: seed with the skeleton, then refine via the LLM if configured.
            void Generate()
            {
                setText(skeleton, "generating with LLM…");
                if (string.IsNullOrEmpty(LlmSettings.BaseUrl))
                {
                    setText(skeleton, "LLM not configured — showing skeleton (LLM settings… on the canvas menu)");
                    Flash("LLM not configured — showing skeleton");
                    return;
                }
                StartCoroutine(RunLlmCodeGen(ctx, setText, skeleton));
            }

            // Existing code, in priority: approved/saved Code on the node, else the imported source file's original
            // text. Open the viewer on it (don't auto-clobber) — "View code". A bare node generates fresh.
            bool showingImported = string.IsNullOrEmpty(el.Code) && !string.IsNullOrEmpty(el.SourceFile)
                && _sourceFiles.ContainsKey(el.SourceFile);
            string existing = !string.IsNullOrWhiteSpace(el.Code) ? el.Code
                : showingImported ? _sourceFiles[el.SourceFile]
                : null;
            bool hasExisting = !string.IsNullOrWhiteSpace(existing);
            string title = (hasExisting ? "View code — " : "Generate code — ") + el.Name;

            // For an imported node we only want THIS element's slice of the (possibly huge) file, not the whole file:
            // extract its definition block and number the gutter from the block's real start line.
            int gutterStart = 1;
            if (showingImported && hasExisting)
            {
                int declLine = FindDeclarationLine(existing, el.Name);
                if (declLine > 0) existing = ExtractDefinitionSection(existing, declLine, out gutterStart);
            }

            setText = ShowCodeViewer(title,
                hasExisting ? existing : skeleton,
                hasExisting
                    ? (string.IsNullOrEmpty(el.Code) ? "imported from " + el.SourceFile + " — read-only; Approve to save, or Regenerate"
                                                     : "saved code — read-only; Approve to save, or Regenerate")
                    : "generating with LLM…",
                id, Generate, el.Language, 0, gutterStart,
                onAudit: code => RunAudit(code, el.Language));

            if (!hasExisting) Generate();
        }

        /// <summary>
        /// Generate source for every selected element, concatenating each one's skeleton (and, when configured,
        /// its LLM refinement) into a single viewer with separators.
        /// </summary>
        public void GenerateCodeForSelection()
        {
            CloseMenu();
            var ids = new List<ElementId>();
            foreach (var sid in SelectedIds)
                if (_model.TryGet(sid, out var e) && KindInfo.IsDiagramNode(e.Kind) && e.Kind != ElementKind.Note)
                    ids.Add(sid);
            if (ids.Count == 0) { Flash("select 2+ elements to generate code for"); return; }

            var contexts = new List<CodeGenContext>(ids.Count);
            var sb = new StringBuilder();
            foreach (var id in ids)
            {
                var ctx = BuildCodeContext(id);
                contexts.Add(ctx);
                AppendSection(sb, ctx.Name, CodeSkeleton.Generate(ctx));
            }

            // Batch output spans multiple elements, so there's no single node to save onto and no regenerate hook.
            var setText = ShowCodeViewer($"Generate code — {ids.Count} elements", sb.ToString(), "generating with LLM…",
                ElementId.None, null, onAudit: code => RunAudit(code, ""));

            if (string.IsNullOrEmpty(LlmSettings.BaseUrl))
            {
                setText(sb.ToString(), "LLM not configured — showing skeletons");
                Flash("LLM not configured — showing skeletons");
                return;
            }
            StartCoroutine(RunLlmCodeGenBatch(contexts, setText));
        }

        private static void AppendSection(StringBuilder sb, string name, string code)
        {
            if (sb.Length > 0) sb.Append('\n');
            sb.Append("// ===== ").Append(name).Append(" =====\n");
            sb.Append(code);
            if (!code.EndsWith("\n")) sb.Append('\n');
        }

        // --- LLM coroutines ---

        private static string LanguageOf(CodeGenContext ctx) =>
            string.IsNullOrWhiteSpace(ctx.Language) ? "C#" : ctx.Language.Trim();

        private static string SystemPromptFor(string language) =>
            $"You are an expert {language} engineer. Output ONLY valid, idiomatic, compilable {language} source — " +
            "no markdown fences, no commentary, and absolutely NO other programming language. " +
            $"Model the described UML element the natural {language} way (for example, in Elixir use " +
            "defmodule/defstruct/def and @behaviour, NOT a class; in Go use structs + interfaces). " +
            "Use the attached notes and relationships to inform the implementation. " +
            "When the UML model includes a doc-pointer with embed:true, include that exact ⟦code⟧ declaration " +
            "and uuid5 value in the generated documentation comment for the described type/member.";

        /// <summary>True when the element carries an original imported source file we can edit surgically (overlay mode).</summary>
        private static bool HasOverlaySource(CodeGenContext ctx) => !string.IsNullOrEmpty(ctx.OriginalSource);

        /// <summary>System role for an overlay edit: return the FULL file with only the modeled changes applied.</summary>
        private static string OverlaySystemPromptFor(string language) =>
            $"You are an expert {language} engineer performing a surgical edit of an existing source file. " +
            "You will be given the ORIGINAL file and an updated UML model of ONE element in it. " +
            "Return the COMPLETE updated file with ONLY the modeled changes applied — add, rename, or adjust the " +
            "modeled type and its members (and their doc-comments) to match the model, and otherwise PRESERVE " +
            "everything else verbatim: formatting, imports, comments, other declarations, and any code not described " +
            "by the model. Preserve existing ⟦code⟧ doc-pointer declarations; when the model includes a doc-pointer " +
            "with embed:true, include that exact declaration and uuid5 value in the relevant doc-comment. " +
            "Output ONLY the full file source — no markdown fences and no commentary.";

        /// <summary>User role for an overlay edit: the original file followed by the element's current model.</summary>
        private static string BuildOverlayUserPrompt(CodeGenContext ctx) =>
            "ORIGINAL FILE:\n" + ctx.OriginalSource +
            "\n\nUPDATED UML MODEL FOR ONE ELEMENT IN THIS FILE:\n" + ctx.ToPromptString() +
            "\nApply the model to the file surgically and return the full updated file.";

        private IEnumerator RunLlmCodeGen(CodeGenContext ctx, System.Action<string, string> setText, string skeleton)
        {
            string language = LanguageOf(ctx);
            bool overlay = HasOverlaySource(ctx);
            string sysPrompt = overlay ? OverlaySystemPromptFor(language) : SystemPromptFor(language);
            string userPrompt = overlay ? BuildOverlayUserPrompt(ctx) : ctx.ToPromptString();
            using (var req = LlmClient.BuildChatRequest(sysPrompt, userPrompt))
            {
                yield return req.SendWebRequest();

                if (req.result != UnityWebRequest.Result.Success)
                {
                    setText(skeleton, "LLM request failed: " + req.error + " — showing skeleton");
                    Flash("LLM request failed — showing skeleton");
                    yield break;
                }

                if (LlmClient.TryParseContent(req.downloadHandler.text, out var content, out var error))
                {
                    string verb = overlay ? "overlaid onto " + System.IO.Path.GetFileName(ctx.OriginalSourcePath ?? "") : "generated with";
                    setText(StripFences(content), (overlay ? "surgically " + verb + " via " : "generated with ") + LlmSettings.Model);
                    Flash(overlay ? "source overlay applied" : "code generated");
                }
                else
                {
                    setText(skeleton, "LLM parse failed: " + error + " — showing skeleton");
                    Flash("LLM parse failed — showing skeleton");
                }
            }
        }

        private IEnumerator RunLlmCodeGenBatch(List<CodeGenContext> contexts, System.Action<string, string> setText)
        {
            var sb = new StringBuilder();
            int ok = 0;
            for (int i = 0; i < contexts.Count; i++)
            {
                var ctx = contexts[i];
                string language = LanguageOf(ctx);
                setText(sb.Length == 0 ? "generating…" : sb.ToString(),
                    $"generating {i + 1}/{contexts.Count}: {ctx.Name}…");

                string section = CodeSkeleton.Generate(ctx); // fallback for this element
                using (var req = LlmClient.BuildChatRequest(SystemPromptFor(language), ctx.ToPromptString()))
                {
                    yield return req.SendWebRequest();
                    if (req.result == UnityWebRequest.Result.Success
                        && LlmClient.TryParseContent(req.downloadHandler.text, out var content, out _))
                    {
                        section = StripFences(content);
                        ok++;
                    }
                }
                AppendSection(sb, ctx.Name, section);
                setText(sb.ToString(), $"generating {i + 1}/{contexts.Count}…");
            }

            setText(sb.ToString(), $"generated {ok}/{contexts.Count} with {LlmSettings.Model}");
            Flash($"code generated ({ok}/{contexts.Count})");
        }

        /// <summary>Strip a leading/trailing markdown code fence (```lang … ```) if the model added one anyway.</summary>
        private static string StripFences(string code)
        {
            if (string.IsNullOrEmpty(code)) return code;
            string s = code.Trim();
            if (!s.StartsWith("```")) return code;

            int firstNl = s.IndexOf('\n');
            if (firstNl < 0) return code;
            s = s.Substring(firstNl + 1); // drop the opening ```lang line

            int lastFence = s.LastIndexOf("```");
            if (lastFence >= 0) s = s.Substring(0, lastFence);
            return s.TrimEnd('\n');
        }

        // --- code viewer modal ---

        /// <summary>
        /// Open a modal showing generated source as a read-only, syntax-highlighted listing with a line-number
        /// gutter, a real vertical scrollbar, and a goto-line control. The RAW (untagged) source is held in a
        /// closure variable so Copy and Approve never see the colour markup; the gutter + highlighted display are
        /// rebuilt from it whenever the text changes. <paramref name="language"/> selects the highlighter palette;
        /// <paramref name="initialLine"/> (1-based, 0 = top) scrolls that line near the top on open — used to jump
        /// to an imported node's declaration. Returns a setter the LLM coroutine calls to replace the code + status.
        /// </summary>
        /// <summary>Max characters the legacy UI Text mesh can show before it overflows its vertex budget and renders
        /// nothing — we cap the DISPLAY to stay safely under it (the raw text is kept whole for Copy/Approve).</summary>
        private const int MaxViewerChars = 12000;

        private System.Action<string, string> ShowCodeViewer(string title, string code, string status,
            ElementId saveTarget, System.Action onRegenerate, string language = null, int initialLine = 0,
            int gutterStartLine = 1, System.Action<string> onSaveToFile = null, System.Action<string> onAudit = null,
            string saveToFileLabel = null)
        {
            float w = 760f, h = 560f;
            var panel = BeginModal(w, h, title);

            const float pad = 16f, scrollbarW = 12f, sbGap = 4f;
            const float gutterW = 46f, gutterGap = 8f, textPadL = 8f, fontSize = 14f;
            float bodyTop = -46f;
            float bodyH = h - 46f - 92f; // leave room for the status line + buttons at the bottom
            float bodyW = w - pad * 2f;
            float viewportW = bodyW - scrollbarW - sbGap;
            var bg = new Color(0.10f, 0.11f, 0.14f, 1f);

            // Scroll view wrapping the highlighted listing so long source scrolls within the dialog.
            var viewportGo = new GameObject("CodeViewport", typeof(RectTransform));
            var vpRt = (RectTransform)viewportGo.transform;
            vpRt.SetParent(panel, false);
            vpRt.anchorMin = vpRt.anchorMax = new Vector2(0f, 1f);
            vpRt.pivot = new Vector2(0f, 1f);
            vpRt.sizeDelta = new Vector2(viewportW, bodyH);
            vpRt.anchoredPosition = new Vector2(pad, bodyTop);
            viewportGo.AddComponent<Image>().color = bg;
            viewportGo.AddComponent<RectMask2D>();
            var scroll = viewportGo.AddComponent<ScrollRect>();
            scroll.horizontal = false;
            scroll.vertical = true;
            scroll.movementType = ScrollRect.MovementType.Clamped;
            scroll.scrollSensitivity = 28f;

            // Vertical scrollbar to the right of the viewport (Permanent so it never resizes the viewport).
            var scrollbar = BuildVerticalScrollbar(panel,
                new Vector2(pad + viewportW + sbGap, bodyTop), new Vector2(scrollbarW, bodyH));
            scroll.verticalScrollbar = scrollbar;
            scroll.verticalScrollbarVisibility = ScrollRect.ScrollbarVisibility.Permanent;

            var contentGo = new GameObject("CodeContent", typeof(RectTransform));
            var contentRt = (RectTransform)contentGo.transform;
            contentRt.SetParent(vpRt, false);
            contentRt.anchorMin = new Vector2(0f, 1f);
            contentRt.anchorMax = new Vector2(1f, 1f);
            contentRt.pivot = new Vector2(0.5f, 1f);
            contentRt.sizeDelta = new Vector2(0f, bodyH);
            contentRt.anchoredPosition = Vector2.zero;
            contentGo.AddComponent<Image>().color = bg;

            // Right-aligned line-number gutter, then the code to its right — same font/size/spacing so rows align.
            var gutter = MakeText(contentRt, "", new Vector2(textPadL, -6f), new Vector2(gutterW, bodyH - 12f),
                (int)fontSize, new Color(0.42f, 0.47f, 0.55f, 1f), TextAnchor.UpperRight);
            gutter.horizontalOverflow = HorizontalWrapMode.Overflow;
            gutter.verticalOverflow = VerticalWrapMode.Overflow;

            float codeX = textPadL + gutterW + gutterGap;
            float codeW = viewportW - codeX - 8f;
            var codeText = MakeText(contentRt, "", new Vector2(codeX, -6f), new Vector2(codeW, bodyH - 12f),
                (int)fontSize, new Color(0.82f, 0.86f, 0.90f, 1f), TextAnchor.UpperLeft);
            codeText.supportRichText = true;
            // No wrap: wrapping would break gutter alignment, so long lines clip horizontally instead.
            codeText.horizontalOverflow = HorizontalWrapMode.Overflow;
            codeText.verticalOverflow = VerticalWrapMode.Overflow;

            scroll.viewport = vpRt;
            scroll.content = contentRt;

            string rawCode = code ?? "";
            float contentHeight = bodyH;
            float lineHeight = fontSize;

            // Rebuild the gutter + highlighted display + content height from the raw source. Called on open and by
            // the coroutine setter whenever the LLM replaces the text.
            void Rebuild(string newRaw)
            {
                rawCode = newRaw ?? ""; // full text kept for Copy / Approve
                // Cap the DISPLAYED text so the legacy Text mesh can't overflow its vertex budget and blank out.
                string display = rawCode;
                if (display.Length > MaxViewerChars)
                {
                    int cut = display.LastIndexOf('\n', Mathf.Min(MaxViewerChars, display.Length - 1));
                    if (cut < MaxViewerChars / 2) cut = MaxViewerChars;
                    display = display.Substring(0, cut) + "\n… (truncated — use Copy code for the full text)";
                }
                int lineCount = CountLines(display);
                gutter.text = BuildGutter(lineCount, gutterStartLine);
                codeText.text = CodeHighlighter.Highlight(display, language);

                float textH = Mathf.Max(codeText.preferredHeight, gutter.preferredHeight);
                contentHeight = Mathf.Max(bodyH, textH + 12f);
                contentRt.sizeDelta = new Vector2(0f, contentHeight);
                gutter.rectTransform.sizeDelta = new Vector2(gutterW, contentHeight - 12f);
                codeText.rectTransform.sizeDelta = new Vector2(codeW, contentHeight - 12f);
                lineHeight = lineCount > 0 ? textH / lineCount : fontSize;
            }

            // Scroll so 1-based line N sits near the top of the viewport.
            void ScrollToLine(int line)
            {
                if (line < 1) line = 1;
                float scrollable = Mathf.Max(0f, contentHeight - bodyH);
                if (scrollable <= 0f) { scroll.verticalNormalizedPosition = 1f; return; }
                float offset = Mathf.Clamp((line - 1) * lineHeight, 0f, scrollable);
                scroll.verticalNormalizedPosition = 1f - offset / scrollable;
            }

            Rebuild(code);

            // Status line just below the viewport.
            float statusY = bodyTop - bodyH - 6f;
            var statusText = MakeText(panel, status, new Vector2(pad, statusY), new Vector2(w - 340f, 20f), 13,
                new Color(0.60f, 0.66f, 0.76f, 1f), TextAnchor.MiddleLeft);

            // Goto-line control on the status row, right-aligned above the button strip.
            MakeText(panel, "Go to line", new Vector2(w - 312f, statusY), new Vector2(70f, 20f), 12,
                LabelColor, TextAnchor.MiddleRight);
            var gotoInput = MakeInput(panel, new Vector2(w - 236f, statusY + 6f), 62f, "", "#");
            gotoInput.contentType = InputField.ContentType.IntegerNumber;
            void DoGoto()
            {
                if (int.TryParse(gotoInput.text, out var ln) && ln > 0) ScrollToLine(ln);
            }
            gotoInput.onSubmit.AddListener(_ => DoGoto());
            MakeButton(panel, "Go", new Vector2(w - 168f, statusY + 8f), new Vector2(40f, 26f),
                new Color(0.22f, 0.24f, 0.29f, 1f), DoGoto);

            // Buttons.
            float yBtn = -(h - 46f);
            MakeButton(panel, "Copy code", new Vector2(pad, yBtn), new Vector2(118f, 34f),
                new Color(0.20f, 0.42f, 0.52f, 1f), () =>
                {
                    GUIUtility.systemCopyBuffer = rawCode;
                    if (statusText != null) statusText.text = "copied to clipboard";
                    Flash("code copied to clipboard");
                });
            if (onRegenerate != null)
                MakeButton(panel, "Regenerate", new Vector2(pad + 126f, yBtn), new Vector2(120f, 34f),
                    new Color(0.30f, 0.30f, 0.16f, 1f), () => onRegenerate());
            // Save-to-file affordance (used by the Liquibase changelog viewer, which has no node save target).
            if (onSaveToFile != null)
                MakeButton(panel, string.IsNullOrEmpty(saveToFileLabel) ? "Save to file…" : saveToFileLabel,
                    new Vector2(w - 308f, yBtn), new Vector2(196f, 34f),
                    new Color(0.18f, 0.46f, 0.30f, 1f), () => onSaveToFile(rawCode));
            if (saveTarget.IsValid && onAudit == null)
                MakeButton(panel, "Open in VS Code", new Vector2(pad + 254f, yBtn), new Vector2(136f, 34f),
                    new Color(0.24f, 0.28f, 0.34f, 1f), () => EditCodeInVsCode(saveTarget));
            // On-request LLM audit/review of the shown code (the wizard / review step).
            if (onAudit != null)
                MakeButton(panel, "Audit (LLM)…", new Vector2(pad + 254f, yBtn), new Vector2(132f, 34f),
                    new Color(0.34f, 0.26f, 0.42f, 1f), () => onAudit(rawCode));
            // Approve & save the code onto the node — the round-trip counterpart to import.
            if (saveTarget.IsValid)
                MakeButton(panel, "Approve & save to node", new Vector2(w - 308f, yBtn), new Vector2(196f, 34f),
                    new Color(0.18f, 0.46f, 0.30f, 1f), () =>
                    {
                        _ctl.SetCode(saveTarget, rawCode);
                        // If this node round-trips a stored source file, update the overlay so the next edit builds on it.
                        if (_model.TryGet(saveTarget, out var st) && !string.IsNullOrEmpty(st.SourceFile)
                            && _sourceFiles.ContainsKey(st.SourceFile))
                            _sourceFiles[st.SourceFile] = rawCode;
                        Flash("saved code to node");
                        CloseMenu();
                    });
            MakeButton(panel, "Close", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);

            // Jump to the declaration line once the content has laid out (one frame after build).
            if (initialLine > 0)
                StartCoroutine(DeferOneFrame(() => ScrollToLine(initialLine)));

            // The setter the coroutine uses to replace the displayed code + status after the async call.
            return (newCode, newStatus) =>
            {
                if (codeText != null) Rebuild(newCode);
                if (statusText != null) statusText.text = newStatus ?? "";
            };
        }

        /// <summary>Run <paramref name="action"/> one frame later, after the just-built layout has settled.</summary>
        private IEnumerator DeferOneFrame(System.Action action)
        {
            yield return null;
            action?.Invoke();
        }

        /// <summary>Number of display rows in <paramref name="code"/> (newline count + 1).</summary>
        private static int CountLines(string code)
        {
            if (string.IsNullOrEmpty(code)) return 1;
            int lines = 1;
            for (int i = 0; i < code.Length; i++) if (code[i] == '\n') lines++;
            return lines;
        }

        /// <summary>Right-aligned "1\n2\n…\nN" gutter string for <paramref name="lineCount"/> rows.</summary>
        private static string BuildGutter(int lineCount, int startLine = 1)
        {
            var sb = new StringBuilder(lineCount * 5);
            for (int i = 0; i < lineCount; i++)
            {
                if (i > 0) sb.Append('\n');
                sb.Append(startLine + i);
            }
            return sb.ToString();
        }

        /// <summary>Build a uGUI vertical Scrollbar (track + sliding area + handle) wired for a ScrollRect.</summary>
        private Scrollbar BuildVerticalScrollbar(RectTransform parent, Vector2 topLeft, Vector2 size)
        {
            var go = new GameObject("CodeScrollbar", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 1f);
            rt.pivot = new Vector2(0f, 1f);
            rt.sizeDelta = size;
            rt.anchoredPosition = topLeft;
            go.AddComponent<Image>().color = new Color(0.16f, 0.18f, 0.22f, 1f);
            var scrollbar = go.AddComponent<Scrollbar>();
            scrollbar.direction = Scrollbar.Direction.BottomToTop;

            var areaGo = new GameObject("Sliding Area", typeof(RectTransform));
            var areaRt = (RectTransform)areaGo.transform;
            areaRt.SetParent(rt, false);
            areaRt.anchorMin = Vector2.zero;
            areaRt.anchorMax = Vector2.one;
            areaRt.sizeDelta = Vector2.zero;
            areaRt.anchoredPosition = Vector2.zero;

            var handleGo = new GameObject("Handle", typeof(RectTransform));
            var handleRt = (RectTransform)handleGo.transform;
            handleRt.SetParent(areaRt, false);
            handleRt.anchorMin = Vector2.zero;
            handleRt.anchorMax = Vector2.one;
            handleRt.sizeDelta = Vector2.zero;
            handleRt.anchoredPosition = Vector2.zero;
            var handleImg = handleGo.AddComponent<Image>();
            handleImg.color = new Color(0.36f, 0.40f, 0.48f, 1f);

            scrollbar.targetGraphic = handleImg;
            scrollbar.handleRect = handleRt;
            return scrollbar;
        }

        /// <summary>
        /// Find the 1-based line in <paramref name="source"/> where <paramref name="name"/> is declared: the first
        /// line that mentions <paramref name="name"/> as a whole word AND reads like a declaration (carries a
        /// declaration keyword, or the name is immediately followed by '(' / ':' / '{'). Returns 0 if not found.
        /// </summary>
        /// <summary>
        /// Extract just the element's definition block from a larger file: a few preceding doc/attribute lines, the
        /// declaration line, and the brace-matched body (or a line window for brace-less languages), capped at
        /// <paramref name="maxLines"/>. <paramref name="startLine1"/> returns the block's 1-based start line in the
        /// original file so the viewer's gutter can number it correctly.
        /// </summary>
        private static string ExtractDefinitionSection(string source, int declLine1, out int startLine1, int maxLines = 400)
        {
            startLine1 = 1;
            if (string.IsNullOrEmpty(source)) return source;
            var lines = source.Replace("\r\n", "\n").Replace('\r', '\n').Split('\n');
            if (declLine1 < 1 || declLine1 > lines.Length)
                return string.Join("\n", lines, 0, Mathf.Min(lines.Length, maxLines));

            // Pull in up to 4 preceding comment / attribute / decorator lines as context.
            int start = declLine1 - 1;
            while (start > 0 && (declLine1 - 1) - (start - 1) <= 4)
            {
                string t = lines[start - 1].TrimStart();
                if (t.StartsWith("//") || t.StartsWith("/*") || t.StartsWith("*") || t.StartsWith("#")
                    || t.StartsWith("[") || t.StartsWith("@")) start--;
                else break;
            }
            startLine1 = start + 1;

            // Brace-match the body from the declaration line; fall back to a window if the language is brace-less.
            int end = declLine1 - 1;
            int depth = 0; bool sawBrace = false;
            for (int i = declLine1 - 1; i < lines.Length && i < start + maxLines; i++)
            {
                foreach (char c in lines[i])
                {
                    if (c == '{') { depth++; sawBrace = true; }
                    else if (c == '}') depth--;
                }
                end = i;
                if (sawBrace && depth <= 0) break;
            }
            if (!sawBrace) end = Mathf.Min(lines.Length - 1, (declLine1 - 1) + 120);
            end = Mathf.Min(end, start + maxLines - 1, lines.Length - 1);

            var sb = new StringBuilder();
            for (int i = start; i <= end; i++) { if (i > start) sb.Append('\n'); sb.Append(lines[i]); }
            return sb.ToString();
        }

        private static int FindDeclarationLine(string source, string name)
        {
            if (string.IsNullOrEmpty(source) || string.IsNullOrEmpty(name)) return 0;
            var lines = source.Replace("\r\n", "\n").Replace('\r', '\n').Split('\n');
            for (int i = 0; i < lines.Length; i++)
            {
                int idx = IndexOfWord(lines[i], name, 0);
                if (idx < 0) continue;
                if (LooksLikeDeclaration(lines[i], name, idx)) return i + 1;
            }
            return 0;
        }

        private static readonly string[] DeclarationKeywords =
        {
            "class", "interface", "struct", "enum", "record", "def", "defmodule", "defstruct",
            "func", "fn", "type", "public", "private", "protected"
        };

        /// <summary>True when <paramref name="line"/> looks like a declaration of <paramref name="name"/> at <paramref name="idx"/>.</summary>
        private static bool LooksLikeDeclaration(string line, string name, int idx)
        {
            foreach (var kw in DeclarationKeywords)
                if (IndexOfWord(line, kw, 0) >= 0) return true;

            int after = idx + name.Length;
            while (after < line.Length && line[after] == ' ') after++;
            if (after < line.Length)
            {
                char c = line[after];
                if (c == '(' || c == ':' || c == '{') return true;
            }
            return false;
        }

        /// <summary>Index of <paramref name="word"/> in <paramref name="s"/> at or after <paramref name="from"/> with identifier boundaries, else -1.</summary>
        private static int IndexOfWord(string s, string word, int from)
        {
            if (string.IsNullOrEmpty(word)) return -1;
            int i = from;
            while ((i = s.IndexOf(word, i, System.StringComparison.Ordinal)) >= 0)
            {
                bool leftOk = i == 0 || !IsWordChar(s[i - 1]);
                int end = i + word.Length;
                bool rightOk = end >= s.Length || !IsWordChar(s[end]);
                if (leftOk && rightOk) return i;
                i = end;
            }
            return -1;
        }

        private static bool IsWordChar(char c) => char.IsLetterOrDigit(c) || c == '_';

        // --- LLM settings dialog ---

        /// <summary>A known OpenAI-compatible provider: a display name, its endpoint, and the env var its key lives in.</summary>
        private readonly struct LlmProvider
        {
            public readonly string Name, BaseUrl, EnvVar;
            public LlmProvider(string name, string baseUrl, string envVar) { Name = name; BaseUrl = baseUrl; EnvVar = envVar; }
        }

        private static readonly LlmProvider[] DefaultLlmProviders =
        {
            new LlmProvider("LM Studio (local)", "http://localhost:1234/v1", null),
            new LlmProvider("Ollama (local)",    "http://localhost:11434/v1", null),
            new LlmProvider("OpenAI",            "https://api.openai.com/v1", "OPENAI_API_KEY"),
            new LlmProvider("OpenRouter",        "https://openrouter.ai/api/v1", "OPENROUTER_API_KEY"),
            new LlmProvider("Groq",              "https://api.groq.com/openai/v1", "GROQ_API_KEY"),
            new LlmProvider("Together",          "https://api.together.xyz/v1", "TOGETHER_API_KEY"),
            new LlmProvider("Mistral",           "https://api.mistral.ai/v1", "MISTRAL_API_KEY"),
            new LlmProvider("DeepSeek",          "https://api.deepseek.com/v1", "DEEPSEEK_API_KEY"),
            new LlmProvider("Cerebras",          "https://api.cerebras.ai/v1", "CEREBRAS_API_KEY"),
            new LlmProvider("z.ai",              "https://api.z.ai/api/paas/v4", "ZAI_API_KEY"),
        };

        private static List<LlmProvider> CurrentLlmProviders()
        {
            var providers = new List<LlmProvider>();
            foreach (var p in GlobalCatalog.LlmProviders)
                if (!string.IsNullOrWhiteSpace(p.name) && !string.IsNullOrWhiteSpace(p.baseUrl))
                    providers.Add(new LlmProvider(p.name.Trim(), p.baseUrl.Trim(), string.IsNullOrWhiteSpace(p.envVar) ? null : p.envVar.Trim()));
            if (providers.Count == 0) providers.AddRange(DefaultLlmProviders);
            providers.Sort((a, b) => string.Compare(a.Name, b.Name, StringComparison.OrdinalIgnoreCase));
            return providers;
        }

        /// <summary>The env var holding a key for a base URL (so the dialog can prefill it), or null.</summary>
        private static string EnvVarForUrl(string baseUrl)
        {
            string u = (baseUrl ?? "").TrimEnd('/');
            foreach (var p in CurrentLlmProviders())
                if (!string.IsNullOrEmpty(p.EnvVar) && string.Equals(p.BaseUrl.TrimEnd('/'), u, StringComparison.OrdinalIgnoreCase))
                    return p.EnvVar;
            return null;
        }

        private static string ProviderNameForUrl(string baseUrl)
        {
            if (string.IsNullOrWhiteSpace(baseUrl)) return "Custom provider";
            try
            {
                var uri = new Uri(baseUrl.Trim());
                return "Custom " + uri.Host;
            }
            catch
            {
                return "Custom " + baseUrl.Trim().TrimEnd('/');
            }
        }

        private static string ProviderNameForSelection(string selectedName, string baseUrl, List<LlmProvider> knownProviders)
        {
            if (selectedName != "Custom…")
                foreach (var provider in knownProviders)
                    if (provider.Name == selectedName
                        && string.Equals(provider.BaseUrl.TrimEnd('/'), (baseUrl ?? "").TrimEnd('/'), StringComparison.OrdinalIgnoreCase))
                        return selectedName;
            return ProviderNameForUrl(baseUrl);
        }

        /// <summary>
        /// Edit the OpenAI-compatible endpoint settings. Provides a provider preset dropdown (which fills the base URL
        /// and, when its key is exported in the environment, the API key), a "Test connection" button, and a model
        /// dropdown populated by fetching <c>/models</c> from the provider.
        /// </summary>
        public void ShowLlmSettings(Vector2 screenPos)
        {
            CloseMenu();
            LlmSettings.Load(out var baseUrl, out var apiKey, out var model);

            const float w = 520f, h = 392f;
            var panel = BeginModal(w, h, "LLM settings   —   OpenAI-compatible endpoint");

            float y = -50f;
            FormLabel(panel, "Provider preset", ref y, w);
            // The status line (test-connection / fetch results) — declared early so the closures below can write it.
            var status = MakeText(panel, "", new Vector2(16f, -(h - 78f)), new Vector2(w - 32f, 18f), 13,
                LabelColor, TextAnchor.MiddleLeft);

            InputField urlInput = null, keyInput = null;
            DropdownHandle modelDd = null;
            var knownProviders = CurrentLlmProviders();

            var providerNames = new List<string> { "Custom…" };
            foreach (var p in knownProviders) providerNames.Add(p.Name);
            string currentProvider = "Custom…";
            foreach (var p in knownProviders)
                if (string.Equals(p.BaseUrl.TrimEnd('/'), (baseUrl ?? "").TrimEnd('/'), StringComparison.OrdinalIgnoreCase))
                    currentProvider = p.Name;

            var providerDd = MakeDropdown(panel, new Vector2(16f, y), w - 32f, providerNames, currentProvider, sel =>
            {
                foreach (var p in knownProviders)
                    if (p.Name == sel)
                    {
                        if (urlInput != null) urlInput.text = p.BaseUrl;
                        if (keyInput != null && !string.IsNullOrEmpty(p.EnvVar))
                        {
                            string envKey = Environment.GetEnvironmentVariable(p.EnvVar);
                            if (!string.IsNullOrEmpty(envKey)) { keyInput.text = envKey; status.text = $"API key loaded from ${p.EnvVar}"; }
                            else status.text = $"{p.EnvVar} not set in the environment — paste a key below";
                        }
                        else if (keyInput != null && string.IsNullOrEmpty(p.EnvVar)) status.text = "local provider — no API key needed";
                        break;
                    }
            });
            y -= 42f;

            FormLabel(panel, "Base URL   (e.g. http://localhost:1234/v1)", ref y, w);
            urlInput = MakeInput(panel, new Vector2(16f, y), w - 146f, baseUrl, LlmSettings.DefaultBaseUrl);
            MakeButton(panel, "Save provider", new Vector2(w - 124f, y), new Vector2(108f, 32f),
                new Color(0.20f, 0.40f, 0.34f, 1f), () =>
                {
                    string name = ProviderNameForSelection(providerDd.Get(), urlInput.text, knownProviders);
                    GlobalCatalog.RememberLlmProvider(name, urlInput.text, EnvVarForUrl(urlInput.text));
                    status.text = "provider saved globally";
                });
            y -= 42f;

            FormLabel(panel, "API key   (auto-filled from the provider's env var when set)", ref y, w);
            keyInput = MakeInput(panel, new Vector2(16f, y), w - 200f, apiKey, "sk-…  (optional for local)");
            keyInput.contentType = InputField.ContentType.Password;
            // Offer to pull the key from the environment for the current URL on open.
            string envForCurrent = EnvVarForUrl(baseUrl);
            if (string.IsNullOrEmpty(apiKey) && envForCurrent != null)
            {
                string envKey = Environment.GetEnvironmentVariable(envForCurrent);
                if (!string.IsNullOrEmpty(envKey)) { keyInput.text = envKey; status.text = $"API key loaded from ${envForCurrent}"; }
            }
            MakeButton(panel, "Test connection", new Vector2(w - 176f, y), new Vector2(160f, 32f),
                new Color(0.22f, 0.40f, 0.34f, 1f), () => StartCoroutine(TestLlmConnection(urlInput.text, keyInput.text, status)));
            y -= 42f;

            FormLabel(panel, "Model   (Fetch to list the provider's models)", ref y, w);
            var models = GlobalCatalog.LlmModels;
            if (!string.IsNullOrEmpty(model) && !ContainsIgnoreCase(models, model)) models.Add(model);
            models.Sort(StringComparer.OrdinalIgnoreCase);
            modelDd = MakeDropdown(panel, new Vector2(16f, y), w - 200f, models, string.IsNullOrEmpty(model) ? "(fetch models)" : model, _ => { });
            MakeButton(panel, "↻ Fetch models", new Vector2(w - 176f, y), new Vector2(160f, 32f),
                new Color(0.22f, 0.34f, 0.46f, 1f),
                () => StartCoroutine(FetchLlmModels(urlInput.text, keyInput.text, modelDd, status)));
            y -= 46f;

            void Submit()
            {
                string selectedModel = modelDd.Get();
                if (string.IsNullOrWhiteSpace(selectedModel) || selectedModel == "(fetch models)")
                    selectedModel = LlmSettings.DefaultModel;
                GlobalCatalog.RememberLlmProvider(ProviderNameForSelection(providerDd.Get(), urlInput.text, knownProviders),
                    urlInput.text, EnvVarForUrl(urlInput.text));
                GlobalCatalog.RememberLlmModel(selectedModel);
                LlmSettings.Save(urlInput.text, keyInput.text, selectedModel);
                CloseMenu();
                Flash("LLM settings saved");
            }

            float yBtn = -(h - 46f);
            MakeButton(panel, "Save", new Vector2(w - 198f, yBtn), new Vector2(84f, 34f),
                new Color(0.20f, 0.42f, 0.52f, 1f), Submit);
            MakeButton(panel, "Cancel", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);

            FocusInput(urlInput);
        }

        /// <summary>GET {baseUrl}/models to verify reachability + auth, reporting into the dialog's status line.</summary>
        private IEnumerator TestLlmConnection(string baseUrl, string apiKey, Text status)
        {
            if (status != null) status.text = "testing…";
            if (string.IsNullOrWhiteSpace(baseUrl)) { if (status != null) status.text = "set a base URL first"; yield break; }
            using (var req = LlmClient.BuildModelsRequest(baseUrl, apiKey))
            {
                req.timeout = 15;
                yield return req.SendWebRequest();
                if (req.result != UnityWebRequest.Result.Success)
                { if (status != null) status.text = "✗ " + req.error; yield break; }
                if (LlmClient.TryParseModels(req.downloadHandler.text, out var models, out var err))
                { if (status != null) status.text = $"✓ connected — {models.Count} models available"; }
                else { if (status != null) status.text = "✓ reachable, but: " + err; }
            }
        }

        /// <summary>GET {baseUrl}/models and load the ids into the model dropdown.</summary>
        private IEnumerator FetchLlmModels(string baseUrl, string apiKey, DropdownHandle modelDd, Text status)
        {
            if (status != null) status.text = "fetching models…";
            if (string.IsNullOrWhiteSpace(baseUrl)) { if (status != null) status.text = "set a base URL first"; yield break; }
            using (var req = LlmClient.BuildModelsRequest(baseUrl, apiKey))
            {
                req.timeout = 20;
                yield return req.SendWebRequest();
                if (req.result != UnityWebRequest.Result.Success)
                { if (status != null) status.text = "✗ " + req.error; yield break; }
                if (LlmClient.TryParseModels(req.downloadHandler.text, out var models, out var err))
                {
                    foreach (var model in models) GlobalCatalog.RememberLlmModel(model);
                    modelDd?.SetOptions(models);
                    if (status != null) status.text = $"loaded {models.Count} models — pick one above";
                }
                else if (status != null) status.text = "✗ " + err;
            }
        }

        // --- LLM error toast (shown when an AI feature can't reach the endpoint) ---

        /// <summary>
        /// A small action toast for LLM connection failures: explains the problem and offers a button to open the
        /// LLM settings dialog (plus any extra actions the caller supplies, e.g. "use basic layout").
        /// </summary>
        public void ShowLlmErrorToast(string detail, params (string label, Action act)[] extraActions)
        {
            CloseMenu();
            const float w = 460f;
            var actions = new List<(string, Action)> { ("Open LLM settings…", () => ShowLlmSettings(Input.mousePosition)) };
            if (extraActions != null) actions.AddRange(extraActions);
            actions.Add(("Dismiss", CloseMenu));

            float h = 96f + actions.Count * 40f;
            var panel = NewPanel("LlmToast",
                new Vector2((Screen.width - w) * 0.5f, Screen.height * 0.72f), new Vector2(w, h),
                new Color(0.16f, 0.12f, 0.13f, 0.98f));
            var rt = (RectTransform)panel.transform;
            _menu = panel;

            MakeText(rt, "⚠  LLM endpoint unreachable", new Vector2(14f, -10f), new Vector2(w - 28f, 22f), 16,
                new Color(0.97f, 0.82f, 0.55f, 1f), TextAnchor.MiddleLeft).fontStyle = FontStyle.Bold;
            MakeText(rt, detail + "\nConfigure or fix the endpoint, or use a basic layout.",
                new Vector2(14f, -38f), new Vector2(w - 28f, 50f), 13,
                new Color(0.86f, 0.88f, 0.92f, 1f), TextAnchor.UpperLeft);

            float by = -96f;
            foreach (var a in actions)
            {
                var act = a.Item2;
                MakeButton(rt, a.Item1, new Vector2(14f, by), new Vector2(w - 28f, 32f),
                    new Color(0.22f, 0.30f, 0.42f, 1f), () => act());
                by -= 40f;
            }
        }

        // --- a lightweight custom dropdown (button + toggled option list; no UnityEngine.UI.Dropdown template) ---

        /// <summary>Live handle to a dropdown: read the value, set it, or replace the option list (e.g. after a fetch).</summary>
        private sealed class DropdownHandle
        {
            public Func<string> Get;
            public Action<List<string>> SetOptions;
        }

        private DropdownHandle MakeDropdown(RectTransform parent, Vector2 topLeft, float width,
            List<string> options, string current, Action<string> onSelect)
        {
            string value = current ?? "";
            var opts = new List<string>(options ?? new List<string>());

            var go = new GameObject("Dropdown", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 1f);
            rt.pivot = new Vector2(0f, 1f);
            rt.sizeDelta = new Vector2(width, 32f);
            rt.anchoredPosition = topLeft;
            var img = go.AddComponent<Image>();
            img.color = new Color(0.20f, 0.22f, 0.27f, 1f);
            var btn = go.AddComponent<Button>();
            btn.targetGraphic = img;
            var label = MakeText(rt, value, new Vector2(8f, 0f), new Vector2(width - 26f, 32f), 15,
                new Color(0.94f, 0.96f, 1f, 1f), TextAnchor.MiddleLeft);
            MakeText(rt, "▾", new Vector2(width - 20f, 0f), new Vector2(16f, 32f), 14,
                new Color(0.7f, 0.74f, 0.8f, 1f), TextAnchor.MiddleCenter);

            GameObject list = null;
            void CloseList() { if (list != null) { Destroy(list); list = null; } }

            void OpenList()
            {
                CloseList();
                if (opts.Count == 0) return;
                // uGUI paints in sibling order: raise the whole dropdown above the form fields created after it so the
                // open list isn't drawn behind them.
                rt.SetAsLastSibling();
                const float ih = 28f; float lh = Mathf.Min(opts.Count, 8) * ih + 4f;
                list = new GameObject("DDList", typeof(RectTransform));
                var lrt = (RectTransform)list.transform;
                lrt.SetParent(rt, false);
                lrt.anchorMin = lrt.anchorMax = new Vector2(0f, 1f);
                lrt.pivot = new Vector2(0f, 1f);
                lrt.sizeDelta = new Vector2(width, lh);
                lrt.anchoredPosition = new Vector2(0f, -34f);
                list.AddComponent<Image>().color = new Color(0.13f, 0.15f, 0.19f, 0.99f);
                list.AddComponent<RectMask2D>();
                var content = new GameObject("C", typeof(RectTransform));
                var crt = (RectTransform)content.transform;
                crt.SetParent(lrt, false);
                crt.anchorMin = new Vector2(0f, 1f); crt.anchorMax = new Vector2(1f, 1f);
                crt.pivot = new Vector2(0.5f, 1f);
                crt.sizeDelta = new Vector2(0f, opts.Count * ih);
                crt.anchoredPosition = Vector2.zero;
                var scroll = list.AddComponent<ScrollRect>();
                scroll.content = crt; scroll.viewport = lrt; scroll.horizontal = false; scroll.movementType = ScrollRect.MovementType.Clamped;
                float iy = 0f;
                foreach (var o in opts)
                {
                    var ov = o;
                    var igo = new GameObject("I", typeof(RectTransform));
                    var irt = (RectTransform)igo.transform;
                    irt.SetParent(crt, false);
                    irt.anchorMin = irt.anchorMax = new Vector2(0f, 1f);
                    irt.pivot = new Vector2(0f, 1f);
                    irt.sizeDelta = new Vector2(width, ih);
                    irt.anchoredPosition = new Vector2(0f, iy);
                    var iimg = igo.AddComponent<Image>();
                    iimg.color = new Color(0.18f, 0.20f, 0.25f, 1f);
                    var ibtn = igo.AddComponent<Button>();
                    ibtn.targetGraphic = iimg;
                    ibtn.onClick.AddListener(() => { value = ov; label.text = ov; CloseList(); onSelect?.Invoke(ov); });
                    MakeText(irt, ov, new Vector2(8f, 0f), new Vector2(width - 12f, ih), 14,
                        new Color(0.9f, 0.93f, 0.98f, 1f), TextAnchor.MiddleLeft);
                    iy -= ih;
                }
            }

            btn.onClick.AddListener(() => { if (list != null) CloseList(); else OpenList(); });

            return new DropdownHandle
            {
                Get = () => value,
                SetOptions = newOpts =>
                {
                    opts = new List<string>(newOpts ?? new List<string>());
                    if (!opts.Contains(value) && opts.Count > 0) { value = opts[0]; label.text = value; onSelect?.Invoke(value); }
                    CloseList();
                },
            };
        }
    }
}
