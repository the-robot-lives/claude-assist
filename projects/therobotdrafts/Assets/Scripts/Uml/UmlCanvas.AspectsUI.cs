using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.Authoring.State;
using TheRobotDraft.Authoring.Interchange;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// Wave-3 aspect UX: an inspector summary + a per-element aspect editor modal, and a registry/history panel. This
    /// is the human surface over the engine-free core (<see cref="AspectRegistry"/>, <see cref="AspectAttachment"/>,
    /// <see cref="AspectResolution"/>) — all write-back goes through <c>AuthoringController.SetElementAspects</c>
    /// (one undo step) and <c>AspectRegistry.Save</c> (versioned registry). Pure Unity uGUI, matching the canvas's own
    /// modal/input helpers.
    /// </summary>
    public sealed partial class UmlCanvas
    {
        // --- inspector summary (rendered by RefreshInspector via InspectorAspectSummary) ---

        /// <summary>One-line count of effective aspects + freeform on the selected element, or null when none.</summary>
        private string AspectSummary(ModelElement el)
        {
            if (el == null) return null;
            var eff = AspectAttachment.ResolveElement(el, GraphType.Unspecified);
            int scoped = eff.Count(e => e.FromScope); // List<T> has no Count(predicate); LINQ provides it
            int authored = eff.Count - scoped;
            int free = el.AspectSet?.Freeform?.Count ?? 0;
            if (authored == 0 && free == 0) return null; // only scope defaults — nothing the user added
            return $"Aspects: {authored} authored · {scoped} scope · {free} freeform";
        }

        /// <summary>Render the inspector's Aspects row (summary + Edit button). Returns the vertical space consumed.</summary>
        private void InspectorAspectRow(ModelElement el, ElementId id, ref float y)
        {
            string summary = AspectSummary(el) ?? "Aspects: none authored";
            MakeText(_inspectorContent, summary, new Vector2(12f, y), new Vector2(InspectorWidth - 24f, 18f), 12,
                new Color(0.62f, 0.68f, 0.78f, 1f), TextAnchor.MiddleLeft);
            y -= 22f;
            MakeButton(_inspectorContent, "Edit aspects", new Vector2(12f, y), new Vector2(120f, 28f),
                new Color(0.30f, 0.24f, 0.42f, 1f), () => ShowAspectEditorModal(id));
            MakeButton(_inspectorContent, "Registry", new Vector2(138f, y), new Vector2(90f, 28f),
                new Color(0.20f, 0.34f, 0.42f, 1f), () => ShowAspectRegistryModal());
            y -= 36f;
        }

        // --- per-element aspect editor modal ---

        /// <summary>Open the per-element aspect editor. Lists each effective aspect with its fields (locked ones shown
        /// read-only), per-aspect emit-flag checkboxes (locked flags hidden), the freeform key/value list, and a Save
        /// that writes the whole set back as one undo step.</summary>
        private void ShowAspectEditorModal(ElementId id)
        {
            if (!id.IsValid || !_model.TryGet(id, out var el)) { Flash("nothing selected"); return; }
            const float w = 460f, h = 560f;
            var rt = BeginModal(w, h, "Aspects — " + el.Name);

            // We edit on a working clone so Cancel is free and Save is atomic.
            var working = AspectResolution.Clone(el.AspectSet);
            if (working == null) working = new AspectSet();
            // seed scope defaults so the user sees + can fill every aspect in scope for this element
            AspectAttachment.EnsureScoped(el, GraphType.Unspecified);
            foreach (var ea in AspectAttachment.ResolveElement(el, GraphType.Unspecified))
            {
                if (ea.Def == null || !ea.FromScope) continue;
                bool present = false;
                foreach (var a in working.Aspects) if (a.DefName == ea.Def.Name) { present = true; break; }
                if (!present) working.Aspects.Add(new AspectInstance { DefName = ea.Def.Name, DefVersion = ea.Def.Version, Overrides = new Dictionary<string, string>() });
            }

            var content = MakeScrollContent(rt, w, h - 60f);
            float y = -52f;

            // per-aspect field editors + emit checkboxes
            var fieldInputs = new List<(AspectInstance inst, string field, InputField input, bool locked)>();
            var emitChecks = new List<(AspectInstance inst, char flag, System.Func<bool> get)>();
            for (int i = 0; i < working.Aspects.Count; i++)
            {
                var inst = working.Aspects[i];
                var def = AspectRegistry.Get(inst.DefName);
                FormLabel(content, def != null ? $"{def.Name} (v{def.Version})" : inst.DefName + " (def missing)", ref y, w - 32f);
                if (def == null) { y -= 4f; continue; }
                // fields
                foreach (var f in def.Fields)
                {
                    if (f == null) continue;
                    bool locked = f.Locked || !AspectResolution.IsFieldEditable(def, f.Name);
                    string cur = AspectResolution.EffectiveValue(def, inst, f.Name);
                    var input = MakeInput(content, new Vector2(28f, y), w - 60f, cur ?? "",
                        locked ? f.Default + " (locked)" : (f.Default ?? ""));
                    if (locked) input.interactable = false;
                    fieldInputs.Add((inst, f.Name, input, locked));
                    y -= 40f;
                }
                // emit flags (only unlocked ones are offered)
                var locks = def.EmitLocks;
                if (!locks.Annotate) { emitChecks.Add((inst, 'A', MakeCheckbox(content, new Vector2(28f, y), "Annotate", EmitOverrideHasFlag(inst, 'A') ?? def.Emit.Annotate))); y -= 30f; }
                if (!locks.DocTag) { emitChecks.Add((inst, 'D', MakeCheckbox(content, new Vector2(28f, y), "Doc tag", EmitOverrideHasFlag(inst, 'D') ?? def.Emit.DocTag))); y -= 30f; }
                if (!locks.Comment) { emitChecks.Add((inst, 'C', MakeCheckbox(content, new Vector2(28f, y), "Comment", EmitOverrideHasFlag(inst, 'C') ?? def.Emit.Comment))); y -= 30f; }
                if (!locks.Meta) { emitChecks.Add((inst, 'M', MakeCheckbox(content, new Vector2(28f, y), "Meta sidecar", EmitOverrideHasFlag(inst, 'M') ?? def.Emit.Meta))); y -= 30f; }
                y -= 6f;
            }

            // freeform key/values
            FormLabel(content, "Freeform (key = value, one per row)", ref y, w - 32f);
            var freeformText = MakeMultilineInput(content, new Vector2(28f, y), w - 60f, 90f,
                FreeformToText(working.Freeform), "key = value");
            y -= 100f;

            content.sizeDelta = new Vector2(0f, Mathf.Max(h - 80f, -y + 20f));

            void Save()
            {
                // field overrides
                foreach (var fi in fieldInputs)
                {
                    if (fi.locked) continue;
                    string v = fi.input.text.Trim();
                    if (string.IsNullOrEmpty(v)) fi.inst.Overrides.Remove(fi.field);
                    else fi.inst.Overrides[fi.field] = v;
                }
                // emit overrides — only record when the user toggled something off the def default
                foreach (var ec in emitChecks)
                {
                    var def2 = AspectRegistry.Get(ec.inst.DefName);
                    if (def2 == null) continue;
                    bool defVal = EmitFlagDefault(def2.Emit, ec.flag);
                    bool now = ec.get();
                    if (now != defVal) EnsureEmitOverride(ec.inst, ec.flag, now, def2);
                    else ClearEmitFlag(ec.inst, ec.flag);
                }
                // normalize each against its def, then commit
                var cleanedAspects = new List<AspectInstance>();
                foreach (var inst in working.Aspects)
                {
                    var def = AspectRegistry.Get(inst.DefName);
                    if (def != null) { AspectResolution.Normalize(def, inst); inst.DefVersion = def.Version; }
                    // drop empty scope-only instances so Save is sparse
                    if (inst.Overrides.Count == 0 && inst.EmitOverride == null) continue;
                    cleanedAspects.Add(inst);
                }
                var cleanedFree = TextToFreeform(freeformText.text);
                _ctl.SetElementAspects(id, cleanedAspects, cleanedFree);
                RebuildFromModel();
                SetSelected(id);
                CloseMenu();
                Flash("aspects saved");
            }

            MakeButton(rt, "Save", new Vector2(w / 2f - 150f, -h + 22f), new Vector2(120f, 32f),
                new Color(0.18f, 0.46f, 0.30f, 1f), Save);
            MakeButton(rt, "Cancel", new Vector2(w / 2f + 30f, -h + 22f), new Vector2(120f, 32f),
                new Color(0.24f, 0.28f, 0.34f, 1f), CloseMenu);
        }

        // --- registry / history panel ---

        /// <summary>List every aspect def (system + user versions), its scope/version/system-owned flag, with a
        /// "new def" entry and per-def history/diff buttons. Read-mostly; def editing is registry writes.</summary>
        private void ShowAspectRegistryModal()
        {
            const float w = 520f, h = 560f;
            var rt = BeginModal(w, h, "Aspect registry");

            var content = MakeScrollContent(rt, w, h - 60f);
            float y = -52f;

            bool haveDb = SqliteCli.IsAvailable;
            if (!haveDb)
            {
                MakeText(content, "SQLite unavailable — showing system defaults only (registry is read-only).",
                    new Vector2(16f, y), new Vector2(w - 32f, 28f), 12,
                    new Color(0.8f, 0.6f, 0.4f, 1f), TextAnchor.MiddleLeft);
                y -= 34f;
            }

            var defs = AspectRegistry.LoadAll();
            foreach (var d in defs)
            {
                string scope = d.Scope + (d.ElementType.HasValue ? " · " + d.ElementType : "")
                                       + (d.GraphType.HasValue ? "/" + d.GraphType : "");
                FormLabel(content, $"{d.Name}  v{d.Version}{(d.SystemOwned ? "  (system)" : "")}  [{scope}]", ref y, w - 32f);
                if (!string.IsNullOrEmpty(d.Description))
                {
                    MakeText(content, d.Description, new Vector2(32f, y), new Vector2(w - 64f, 18f), 11,
                        LabelColor, TextAnchor.MiddleLeft);
                    y -= 22f;
                }
                // emit flags summary
                MakeText(content, "emit: " + EmitLetters(d.Emit) + "   fields: " + (d.Fields?.Count ?? 0),
                    new Vector2(32f, y), new Vector2(w - 64f, 18f), 11, LabelColor, TextAnchor.MiddleLeft);
                y -= 24f;
                if (haveDb)
                {
                    var d2 = d;
                    MakeButton(content, "History", new Vector2(32f, y), new Vector2(86f, 26f),
                        new Color(0.20f, 0.34f, 0.42f, 1f), () => ShowAspectHistoryModal(d2.Name));
                    MakeButton(content, "Revert to system", new Vector2(124f, y), new Vector2(120f, 26f),
                        new Color(0.24f, 0.28f, 0.34f, 1f), () => { AspectRegistry.Delete(d2.Name); Flash("reverted — reopen registry"); CloseMenu(); });
                    y -= 34f;
                }
                y -= 4f;
            }

            content.sizeDelta = new Vector2(0f, Mathf.Max(h - 80f, -y + 20f));
            MakeButton(rt, "Close", new Vector2(w / 2f - 60f, -h + 22f), new Vector2(120f, 32f),
                new Color(0.24f, 0.28f, 0.34f, 1f), CloseMenu);
        }

        /// <summary>Show the revision history of one aspect def (version list + diff of the two most recent).</summary>
        private void ShowAspectHistoryModal(string name)
        {
            const float w = 520f, h = 480f;
            var rt = BeginModal(w, h, "History — " + name);
            var content = MakeScrollContent(rt, w, h - 60f);
            float y = -52f;

            var head = AspectRegistry.Get(name);
            MakeText(content, head != null ? $"current: v{head.Version}" : "current: (reverted / gone)",
                new Vector2(16f, y), new Vector2(w - 32f, 20f), 13, LabelColor, TextAnchor.MiddleLeft);
            y -= 26f;

            var history = AspectRegistry.History(name);
            for (int i = history.Count - 1; i >= 0; i--)
            {
                var v = history[i];
                MakeText(content, $"v{v.version}{(v.prevVersion > 0 ? "  ← v" + v.prevVersion : "")}    {v.changedAt}",
                    new Vector2(16f, y), new Vector2(w - 32f, 18f), 12,
                    new Color(0.82f, 0.86f, 0.92f, 1f), TextAnchor.MiddleLeft);
                y -= 20f;
                string change = AspectRegistry.RevisionChangeJson(name, v.version);
                if (!string.IsNullOrEmpty(change))
                {
                    MakeText(content, change, new Vector2(32f, y), new Vector2(w - 64f, 36f), 10,
                        LabelColor, TextAnchor.UpperLeft);
                    y -= 40f;
                }
            }
            content.sizeDelta = new Vector2(0f, Mathf.Max(h - 80f, -y + 20f));
            MakeButton(rt, "Back", new Vector2(w / 2f - 60f, -h + 22f), new Vector2(120f, 32f),
                new Color(0.24f, 0.28f, 0.34f, 1f), () => { CloseMenu(); ShowAspectRegistryModal(); });
        }

        // --- small helpers ---

        /// <summary>Build a scroll-view content rect inside a modal body (title bar + room for the footer buttons).</summary>
        private RectTransform MakeScrollContent(RectTransform parent, float w, float viewH)
        {
            var view = new GameObject("Scroll", typeof(RectTransform));
            var vrt = (RectTransform)view.transform;
            vrt.SetParent(parent, false);
            vrt.anchorMin = vrt.anchorMax = new Vector2(0f, 1f);
            vrt.pivot = new Vector2(0f, 1f);
            vrt.sizeDelta = new Vector2(w, viewH);
            vrt.anchoredPosition = new Vector2(0f, -40f);
            view.AddComponent<RectMask2D>();
            view.AddComponent<Image>().color = new Color(0f, 0f, 0f, 0f);

            var c = new GameObject("Content", typeof(RectTransform));
            var crt = (RectTransform)c.transform;
            crt.SetParent(vrt, false);
            crt.anchorMin = new Vector2(0f, 1f);
            crt.anchorMax = new Vector2(1f, 1f);
            crt.pivot = new Vector2(0f, 1f);
            crt.sizeDelta = new Vector2(0f, viewH);
            crt.anchoredPosition = Vector2.zero;

            var scroll = view.AddComponent<ScrollRect>();
            scroll.content = crt;
            scroll.viewport = vrt;
            scroll.horizontal = false;
            scroll.vertical = true;
            scroll.movementType = ScrollRect.MovementType.Clamped;
            return crt;
        }

        private static string FreeformToText(List<FreeformEntry> free)
        {
            if (free == null || free.Count == 0) return "";
            var sb = new System.Text.StringBuilder();
            foreach (var f in free) if (f != null) sb.Append(f.Key).Append(" = ").Append(f.Value).Append('\n');
            return sb.ToString();
        }

        private static List<FreeformEntry> TextToFreeform(string text)
        {
            var list = new List<FreeformEntry>();
            if (string.IsNullOrEmpty(text)) return list;
            foreach (var line in text.Replace("\r\n", "\n").Split('\n'))
            {
                string l = line.Trim();
                if (l.Length == 0) continue;
                int eq = l.IndexOf('=');
                string key, val;
                if (eq <= 0) { key = l; val = ""; }
                else { key = l.Substring(0, eq).Trim(); val = l.Substring(eq + 1).Trim(); }
                if (AspectResolution.IsValidKey(key)) list.Add(new FreeformEntry { Key = key, Value = val });
            }
            return list;
        }

        private static bool EmitFlagDefault(EmitFlags e, char flag) => flag switch
        {
            'A' => e.Annotate, 'D' => e.DocTag, 'C' => e.Comment, 'M' => e.Meta, _ => false,
        };

        private static string EmitLetters(EmitFlags f) =>
            (f.Annotate ? "A" : "") + (f.DocTag ? "D" : "") + (f.Comment ? "C" : "") + (f.Meta ? "M" : "");

        // Read a single emit flag from an instance override, or null when no override is set at all.
        private static bool? EmitOverrideHasFlag(AspectInstance inst, char flag)
        {
            if (inst == null || inst.EmitOverride == null) return null;
            var o = inst.EmitOverride.Value;
            return flag switch { 'A' => o.Annotate, 'D' => o.DocTag, 'C' => o.Comment, 'M' => o.Meta, _ => (bool?)null };
        }

        // Set one flag on an instance's emit override, creating the override struct on demand.
        private static void EnsureEmitOverride(AspectInstance inst, char flag, bool value, AspectDef def)
        {
            var cur = inst.EmitOverride ?? def.Emit;
            switch (flag)
            {
                case 'A': cur.Annotate = value; break;
                case 'D': cur.DocTag = value; break;
                case 'C': cur.Comment = value; break;
                case 'M': cur.Meta = value; break;
            }
            inst.EmitOverride = cur;
        }

        // Clear one flag back to the def default inside an existing override (or drop the override if all-default).
        private static void ClearEmitFlag(AspectInstance inst, char flag)
        {
            if (inst == null || inst.EmitOverride == null) return;
            var def = AspectRegistry.Get(inst.DefName);
            if (def == null) return;
            var o = inst.EmitOverride.Value;
            switch (flag)
            {
                case 'A': o.Annotate = def.Emit.Annotate; break;
                case 'D': o.DocTag = def.Emit.DocTag; break;
                case 'C': o.Comment = def.Emit.Comment; break;
                case 'M': o.Meta = def.Emit.Meta; break;
            }
            if (o.Annotate == def.Emit.Annotate && o.DocTag == def.Emit.DocTag && o.Comment == def.Emit.Comment && o.Meta == def.Emit.Meta)
                inst.EmitOverride = null;
            else
                inst.EmitOverride = o;
        }
    }
}
