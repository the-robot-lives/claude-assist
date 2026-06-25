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
                if (c.Kind == ElementKind.Field) { ctx.Attributes.Add(c.Name); ctx.AttributeComments.Add(c.Description ?? ""); }
                else if (c.Kind == ElementKind.Function) { ctx.Operations.Add(c.Name); ctx.OperationComments.Add(c.Description ?? ""); }
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

        // --- public entry points ---

        /// <summary>
        /// Generate source for a single element: open the viewer seeded with the deterministic skeleton, then
        /// (when an endpoint is configured) refine it asynchronously via the LLM.
        /// </summary>
        public void GenerateCodeForElement(ElementId id)
        {
            CloseMenu();
            if (!_model.TryGet(id, out var el)) { Flash("nothing to generate"); return; }

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
                id, Generate, el.Language, 0, gutterStart);

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
                ElementId.None, null);

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
            "Use the attached notes and relationships to inform the implementation.";

        /// <summary>True when the element carries an original imported source file we can edit surgically (overlay mode).</summary>
        private static bool HasOverlaySource(CodeGenContext ctx) => !string.IsNullOrEmpty(ctx.OriginalSource);

        /// <summary>System role for an overlay edit: return the FULL file with only the modeled changes applied.</summary>
        private static string OverlaySystemPromptFor(string language) =>
            $"You are an expert {language} engineer performing a surgical edit of an existing source file. " +
            "You will be given the ORIGINAL file and an updated UML model of ONE element in it. " +
            "Return the COMPLETE updated file with ONLY the modeled changes applied — add, rename, or adjust the " +
            "modeled type and its members (and their doc-comments) to match the model, and otherwise PRESERVE " +
            "everything else verbatim: formatting, imports, comments, other declarations, and any code not described " +
            "by the model. Output ONLY the full file source — no markdown fences and no commentary.";

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
            int gutterStartLine = 1)
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

        /// <summary>Edit the OpenAI-compatible endpoint settings (base URL, API key, model) persisted in PlayerPrefs.</summary>
        public void ShowLlmSettings(Vector2 screenPos)
        {
            CloseMenu();
            LlmSettings.Load(out var baseUrl, out var apiKey, out var model);

            float w = 480f, h = 300f;
            var panel = BeginModal(w, h, "LLM settings   —   OpenAI-compatible endpoint");

            float y = -50f;
            FormLabel(panel, "Base URL   (e.g. http://localhost:1234/v1)", ref y, w);
            var urlInput = MakeInput(panel, new Vector2(16f, y), w - 32f, baseUrl, LlmSettings.DefaultBaseUrl);
            y -= 44f;

            FormLabel(panel, "API key   (leave blank for a local server)", ref y, w);
            var keyInput = MakeInput(panel, new Vector2(16f, y), w - 32f, apiKey, "sk-…  (optional)");
            keyInput.contentType = InputField.ContentType.Password;
            y -= 44f;

            FormLabel(panel, "Model", ref y, w);
            var modelInput = MakeInput(panel, new Vector2(16f, y), w - 32f, model, LlmSettings.DefaultModel);

            void Submit()
            {
                LlmSettings.Save(urlInput.text, keyInput.text, modelInput.text);
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
    }
}
