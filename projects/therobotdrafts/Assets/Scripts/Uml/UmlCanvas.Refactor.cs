using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Networking;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.CodeGen;
using TheRobotDraft.Llm;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// Refactor actions on a node — Rename, Move to a new file, and an LLM-driven free-form refactor (e.g. "extract
    /// this validation into a method", "split into two classes"). The LLM refactor reuses the code viewer: the result
    /// lands there read-only and Approve &amp; save writes it back onto the node (and its shadow file). Surfaced as a
    /// small submenu off the node's right-click menu.
    /// </summary>
    public partial class UmlCanvas
    {
        /// <summary>Open the Refactor submenu for a node.</summary>
        public void ShowRefactorMenu(ElementId id, Vector2 screenPos)
        {
            if (!_model.TryGet(id, out var el)) return;
            var pid = id;
            var items = new List<MenuItem>
            {
                new MenuItem("Rename…", true, () => ShowNamePrompt("Rename — " + el.Name, el.Name, n =>
                {
                    if (string.IsNullOrWhiteSpace(n)) return;
                    _ctl.Rename(pid, n.Trim());
                    RebuildFromModel(); SetSelected(pid); Flash("renamed → " + n.Trim());
                })),
                new MenuItem("Move to new file…", true, () =>
                {
                    string suggested = string.IsNullOrEmpty(el.SourceFile) ? el.Name + LangExt(el.Language) : el.SourceFile;
                    ShowNamePrompt("Move " + el.Name + " to file", suggested, f =>
                    {
                        if (string.IsNullOrWhiteSpace(f)) return;
                        _ctl.SetSourceFile(pid, f.Trim());
                        WriteShadow(pid);
                        RebuildFromModel(); SetSelected(pid); Flash("moved to " + f.Trim());
                    });
                }),
                new MenuItem("Refactor with LLM…  (extract method, simplify, split…)", true, () => ShowRefactorPrompt(pid)),
            };
            CreateMenu(screenPos, "Refactor — " + Ellipsize(el.Name, 26), items);
        }

        /// <summary>Prompt for a free-text refactor instruction, then run it through the LLM into the code viewer.</summary>
        private void ShowRefactorPrompt(ElementId id)
        {
            if (!_model.TryGet(id, out var el)) return;
            ShowNamePrompt("Refactor " + el.Name + " — describe the change", "", instruction =>
            {
                if (string.IsNullOrWhiteSpace(instruction)) { Flash("no refactor instruction"); return; }
                if (string.IsNullOrEmpty(LlmSettings.BaseUrl)) { Flash("LLM not configured — set it in LLM settings…"); return; }
                string code = CurrentCodeFor(id);
                if (string.IsNullOrEmpty(code)) { Flash("no code to refactor — ⌁ Generate code first"); return; }
                var setText = ShowCodeViewer("Refactor — " + el.Name, code, "refactoring with LLM…", id, null, el.Language);
                StartCoroutine(RunLlmRefactor(id, instruction.Trim(), code, el.Language, setText));
            });
        }

        private IEnumerator RunLlmRefactor(ElementId id, string instruction, string code, string language,
            System.Action<string, string> setText)
        {
            string lang = string.IsNullOrEmpty(language) ? "software" : language;
            string sys = "You are an expert " + lang + " engineer performing a focused refactor. Apply ONLY the " +
                "requested change while preserving behavior. Return ONLY the complete refactored source — no markdown " +
                "fences, no commentary, the same language.";
            string user = "Refactor instruction:\n" + instruction + "\n\nSource:\n" + code;
            using (var req = LlmClient.BuildChatRequest(sys, user))
            {
                yield return req.SendWebRequest();
                if (req.result != UnityWebRequest.Result.Success)
                {
                    setText(code, "refactor failed: " + req.error + " — original shown");
                    Flash("refactor failed");
                    yield break;
                }
                if (LlmClient.TryParseContent(req.downloadHandler.text, out var content, out var error))
                {
                    setText(StripFences(content), "refactored via " + LlmSettings.Model + " — Approve to save");
                    Flash("refactor ready — review & Approve");
                }
                else
                {
                    setText(code, "refactor parse failed: " + error + " — original shown");
                    Flash("refactor parse failed");
                }
            }
        }
    }
}
