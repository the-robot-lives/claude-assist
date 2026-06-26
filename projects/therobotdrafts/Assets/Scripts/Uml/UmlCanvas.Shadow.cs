using System.Collections.Generic;
using System.IO;
using UnityEngine;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.CodeGen;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// Shadow-copy round-trip. Imported / generated source is written to an on-disk shadow folder so a node's code
    /// can be opened in an external editor (VS Code). Each opened file is polled for save-time changes; when the
    /// user saves in VS Code the node's members / code docs are re-parsed from the edited code (deterministic
    /// structural parser) and the bubble model updates — code edits flow back to the diagram.
    /// </summary>
    public partial class UmlCanvas
    {
        private string ShadowRoot => Path.Combine(Application.persistentDataPath, "shadow");

        private struct ShadowWatch { public string Path; public long Ticks; public ElementId Node; }
        private readonly List<ShadowWatch> _shadowWatches = new();
        private float _nextShadowPoll;

        private static string LangExt(string lang)
        {
            switch ((lang ?? "").Trim().ToLowerInvariant())
            {
                case "c#": case "csharp": return ".cs";
                case "java": return ".java";
                case "typescript": case "ts": return ".ts";
                case "javascript": case "node.js": case "js": return ".js";
                case "python": return ".py";
                case "go": return ".go";
                case "rust": return ".rs";
                case "elixir": return ".ex";
                case "c++": case "cpp": case "c/c++": return ".cpp";
                default: return ".txt";
            }
        }

        private static string Sanitize(string s)
        {
            var sb = new System.Text.StringBuilder();
            foreach (char c in s) sb.Append(char.IsLetterOrDigit(c) || c == '.' || c == '-' || c == '_' ? c : '_');
            return sb.ToString();
        }

        /// <summary>The on-disk shadow path for a node's editable code (id-prefixed so same-named files don't collide).</summary>
        private string ShadowPathFor(ElementId id)
        {
            if (!_model.TryGet(id, out var el)) return null;
            string baseName = !string.IsNullOrEmpty(el.SourceFile)
                ? Path.GetFileName(el.SourceFile)
                : (string.IsNullOrEmpty(el.Name) ? "Untitled" : el.Name) + LangExt(el.Language);
            return Path.Combine(ShadowRoot, id.Value + "__" + Sanitize(baseName));
        }

        /// <summary>The node's current code: stored generated code, else its imported original, else a fresh skeleton.</summary>
        private string CurrentCodeFor(ElementId id)
        {
            if (!_model.TryGet(id, out var el)) return null;
            if (!string.IsNullOrEmpty(el.Code)) return el.Code;
            if (!string.IsNullOrEmpty(el.SourceFile) && _sourceFiles.TryGetValue(el.SourceFile, out var s)) return s;
            try { return CodeSkeleton.Generate(BuildCodeContext(id)); } catch { return null; }
        }

        /// <summary>Write the node's code to its shadow file (creating the dir); returns the path, or null on failure.</summary>
        private string WriteShadow(ElementId id)
        {
            string code = CurrentCodeFor(id);
            if (string.IsNullOrEmpty(code)) return null;
            string path = ShadowPathFor(id);
            try { Directory.CreateDirectory(ShadowRoot); File.WriteAllText(path, code); }
            catch (System.Exception ex) { Flash("shadow write failed: " + ex.Message); return null; }
            // Persist the code on the element so regeneration / overlay builds on the same text the user edits.
            _ctl.SetCode(id, code);
            return path;
        }

        /// <summary>Pre-write shadow copies for every imported classifier (called right after an import completes).</summary>
        private void WriteShadowsForImport()
        {
            try { Directory.CreateDirectory(ShadowRoot); } catch { return; }
            foreach (var el in _model.Elements)
                if (KindInfo.IsClassifier(el.Kind)
                    && !string.IsNullOrEmpty(el.SourceFile)
                    && _sourceFiles.TryGetValue(el.SourceFile, out var text))
                {
                    try { File.WriteAllText(ShadowPathFor(el.Id), text); } catch { /* best-effort */ }
                }
        }

        /// <summary>Open a node's shadow source in VS Code and watch it: saving in VS Code re-syncs the model.</summary>
        public void EditCodeInVsCode(ElementId id)
        {
            string path = WriteShadow(id);
            if (path == null) { Flash("no code to edit — try ⌁ Generate code first"); return; }
            LaunchExternalEditor(path);
            long ticks = File.Exists(path) ? File.GetLastWriteTimeUtc(path).Ticks : 0;
            _shadowWatches.RemoveAll(w => w.Path == path);
            _shadowWatches.Add(new ShadowWatch { Path = path, Ticks = ticks, Node = id });
            Flash("opened in VS Code — save there to re-sync the model");
        }

        private void LaunchExternalEditor(string path)
        {
            try
            {
                // Try the `code` CLI, then a macOS app launch, then a generic text open.
                var psi = new System.Diagnostics.ProcessStartInfo
                {
                    FileName = "/bin/sh",
                    Arguments = "-c \"code '" + path + "' || open -a 'Visual Studio Code' '" + path + "' || open -t '" + path + "'\"",
                    UseShellExecute = false,
                    CreateNoWindow = true,
                };
                System.Diagnostics.Process.Start(psi);
            }
            catch (System.Exception ex) { Flash("couldn't launch editor: " + ex.Message); }
        }

        /// <summary>Throttled poll (≈2 Hz) of watched shadow files; a newer write-time means VS Code saved → re-sync.</summary>
        private void PollShadowFiles()
        {
            if (_shadowWatches.Count == 0) return;
            if (Time.unscaledTime < _nextShadowPoll) return;
            _nextShadowPoll = Time.unscaledTime + 0.5f;
            for (int i = 0; i < _shadowWatches.Count; i++)
            {
                var w = _shadowWatches[i];
                long t;
                try { if (!File.Exists(w.Path)) continue; t = File.GetLastWriteTimeUtc(w.Path).Ticks; }
                catch { continue; }
                if (t <= w.Ticks) continue;
                w.Ticks = t; _shadowWatches[i] = w;
                ResyncNodeFromShadow(w.Node, w.Path);
            }
        }

        /// <summary>Re-parse a shadow file and update the node's members + code docs + stored code from it.</summary>
        public void ResyncNodeFromShadow(ElementId id, string path)
        {
            if (!_model.TryGet(id, out var el)) return;
            string text;
            try { text = File.ReadAllText(path); } catch { return; }

            _ctl.SetCode(id, text);
            if (!string.IsNullOrEmpty(el.SourceFile)) _sourceFiles[el.SourceFile] = text;

            if (CodeStructParser.TryParse(text, el.Language, out var model)
                && model != null && model.types != null && model.types.Length > 0)
            {
                var pt = System.Array.Find(model.types, t => t.name == el.Name) ?? model.types[0];
                ReplaceMembersFromParse(id, pt);
                if (!string.IsNullOrEmpty(pt.comment)) _ctl.SetCodeDoc(id, pt.comment);
                if (!string.IsNullOrWhiteSpace(pt.deepLinkUuid) || !string.IsNullOrWhiteSpace(pt.deepLinkCode))
                {
                    _ctl.SetDeepLink(id, pt.deepLinkUuid, pt.deepLinkCode);
                    _ctl.SetEmbedDeepLinkCode(id, true);
                }
                RebuildFromModel();
                SetSelected(id);
                Flash("re-synced " + el.Name + " from code edits");
            }
            else
            {
                RebuildFromModel();
                Flash("code saved (couldn't parse structure — members unchanged)");
            }
        }

        /// <summary>Replace a node's Field/Function members with the parsed type's, preserving the node itself.</summary>
        private void ReplaceMembersFromParse(ElementId id, CodeParser.ParsedType pt)
        {
            if (!_model.TryGet(id, out var el)) return;
            var doomed = new List<ElementId>();
            foreach (var childId in el.ChildIds)
                if (_model.TryGet(childId, out var c) && KindInfo.IsMember(c.Kind)) doomed.Add(childId);
            foreach (var d in doomed) _ctl.Delete(d);

            ImportAddMembers(id, ElementKind.Field, pt.fields, pt.fieldComments,
                pt.fieldDeepLinkUuids, pt.fieldDeepLinkCodes);
            ImportAddMembers(id, ElementKind.Function, pt.methods, pt.methodComments,
                pt.methodDeepLinkUuids, pt.methodDeepLinkCodes);
            _ctl.EnterSelect();
        }
    }
}
