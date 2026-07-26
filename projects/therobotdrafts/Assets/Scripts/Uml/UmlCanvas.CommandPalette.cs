using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// The Ctrl/Cmd+K command palette (nav-redesign IA v2): a spotlight-style overlay listing every
    /// menu command with fuzzy substring filtering. Guarantees the interaction law that every verb
    /// is reachable without a pointer — type, Enter, done. The palette registers itself as the open
    /// menu (<c>_menu</c>) so Escape and click-away dismiss it like any dropdown.
    /// </summary>
    public sealed partial class UmlCanvas
    {
        private readonly struct PaletteCommand
        {
            public readonly string Menu;
            public readonly string Label;
            public readonly System.Action Run;
            public PaletteCommand(string menu, string label, System.Action run)
            { Menu = menu; Label = label; Run = run; }
        }

        private InputField _paletteInput;
        private RectTransform _paletteResults;
        private List<PaletteCommand> _paletteMatches = new List<PaletteCommand>();

        private List<PaletteCommand> BuildPaletteCommands()
        {
            var list = new List<PaletteCommand>
            {
                new PaletteCommand("File", "New Model", () => NewDiagram()),
                new PaletteCommand("File", "Open…", () => OpenDiagramFile()),
                new PaletteCommand("File", "Save", () => SaveDiagram()),
                new PaletteCommand("File", "Save As…", () => SaveDiagramAs()),
                new PaletteCommand("File", "Import PlantUML…", () => ImportPlantUml()),
                new PaletteCommand("File", "Import XMI…", () => ImportXmi()),
                new PaletteCommand("File", "Import Mermaid…", () => ImportMermaid()),
                new PaletteCommand("File", "Import EA Project (.qea)…", () => ImportQea()),
                new PaletteCommand("File", "Import Source Code…", () => ShowImportCodeDialog(ScreenCenter)),
                new PaletteCommand("File", "Import Diagram from Image…", () => ShowImageImportDialog(ScreenCenter)),
                new PaletteCommand("File", "Import Database Schema…", () => ShowDbConnectDialog(ScreenCenter)),
                new PaletteCommand("File", "Export PlantUML…", () => ExportPlantUml()),
                new PaletteCommand("File", "Export XMI…", () => ExportXmi()),
                new PaletteCommand("File", "Export Mermaid…", () => ExportMermaid()),
                new PaletteCommand("File", "Export EA Project (.qea)…", () => ExportQea()),
                new PaletteCommand("File", "Copy View as PNG", () => StartCoroutine(CopyViewAsPng())),
                new PaletteCommand("File", "Export 3D Scene (OBJ + MTL)…", () => Export3DModel(true)),
                new PaletteCommand("Edit", "Undo", () => { if (!GeoUndo()) Undo(); }),
                new PaletteCommand("Edit", "Redo", () => { if (!GeoRedo()) Redo(); }),
                new PaletteCommand("Edit", "Delete Selection", () => DeleteSelected()),
                new PaletteCommand("Model", "Select Mode", () => SetToolMode(ToolMode.Select)),
                new PaletteCommand("Model", "Connect Mode", () => SetToolMode(ToolMode.Connect)),
                new PaletteCommand("Model", "Place Mode", () => SetToolMode(ToolMode.Place)),
                new PaletteCommand("Diagram", "New Empty Diagram", () => NewDiagram()),
                new PaletteCommand("Diagram", "Layout: By Source / Package", () => AutoLayout("source")),
                new PaletteCommand("Diagram", "Layout: Hierarchy", () => AutoLayout("hierarchy")),
                new PaletteCommand("Diagram", "Layout: Force-Directed", () => AutoLayout("force")),
                new PaletteCommand("Diagram", "Layout: Tidy Grid", () => AutoLayout("grid")),
                new PaletteCommand("Diagram", "Layout: AI-Assisted…", () => AutoLayoutAI()),
                new PaletteCommand("Code", "Generate Code… (wizard)", () => ShowCodeGenWizard(ScreenCenter)),
                new PaletteCommand("Code", "Generate Liquibase Changelog…", () => GenerateLiquibaseChangelog()),
                new PaletteCommand("Go", "Frame Diagram", () => { if (_mode2D) Apply2DModeCamera(true); else _scene.FrameAll(); }),
                new PaletteCommand("Go", "Camera Z Up", () => JumpCameraZ(1)),
                new PaletteCommand("Go", "Camera Z Down", () => JumpCameraZ(-1)),
                new PaletteCommand("Go", "Cycle Drag-Nav Mode", () => CycleNavMode(false)),
                new PaletteCommand("View", "Toggle 2D / 3D", () => Toggle2DMode()),
                new PaletteCommand("View", "LLM Settings…", () => ShowLlmSettings(ScreenCenter)),
                new PaletteCommand("View", "Vision LLM Settings…", () => ShowVisionLlmSettings(ScreenCenter)),
                new PaletteCommand("View", "Help & Shortcuts", () => ShowHelp()),
            };
            // Quick element creation (guarded on an active package like the menu path).
            foreach (var kind in QuickPlaceKinds)
            {
                var k = kind;
                list.Add(new PaletteCommand("Model", "Add " + k, () => MenuAddKind(k)));
            }
            return list;
        }

        /// <summary>Open (or close) the command palette overlay.</summary>
        private void ToggleCommandPalette()
        {
            if (_menu != null && _paletteInput != null) { CloseMenu(); _paletteInput = null; return; }
            CloseMenu();

            // Dim backdrop — clicking it closes the palette (it registers as _menu).
            var backdrop = new GameObject("PaletteBackdrop", typeof(RectTransform));
            var bdRt = (RectTransform)backdrop.transform;
            bdRt.SetParent(_root, false);
            Stretch(bdRt);
            var bdImg = backdrop.AddComponent<Image>();
            bdImg.color = new Color(0f, 0f, 0f, 0.35f);
            var bdBtn = backdrop.AddComponent<Button>();
            bdBtn.targetGraphic = bdImg;
            bdBtn.onClick.AddListener(() => { CloseMenu(); _paletteInput = null; });
            _menu = backdrop;

            const float w = 560f, inputH = 44f;
            const int maxRows = 10;
            const float rowH = 34f;
            var panel = new GameObject("CommandPalette", typeof(RectTransform));
            var rt = (RectTransform)panel.transform;
            rt.SetParent(bdRt, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 1f);
            rt.pivot = new Vector2(0.5f, 1f);
            rt.sizeDelta = new Vector2(w, inputH + maxRows * rowH + 12f);
            rt.anchoredPosition = new Vector2(0f, -110f);
            TheRobotDraft.Uml.Chrome.MacOsControlKit.ApplyPopover(panel.AddComponent<Image>());

            // Input row.
            var inputGo = new GameObject("PaletteInput", typeof(RectTransform));
            var inRt = (RectTransform)inputGo.transform;
            inRt.SetParent(rt, false);
            inRt.anchorMin = new Vector2(0f, 1f); inRt.anchorMax = new Vector2(1f, 1f);
            inRt.pivot = new Vector2(0f, 1f);
            inRt.sizeDelta = new Vector2(0f, inputH);
            inRt.anchoredPosition = Vector2.zero;
            var paletteImg = inputGo.AddComponent<Image>();
            TheRobotDraft.Uml.Chrome.MacOsControlKit.ApplyTextField(paletteImg);
            _paletteInput = inputGo.AddComponent<InputField>();
            var textComp = MakeText((RectTransform)inputGo.transform, "", new Vector2(14f, 0f), new Vector2(w - 28f, inputH), 18,
                new Color(0.95f, 0.97f, 1f, 1f), TextAnchor.MiddleLeft);
            textComp.raycastTarget = true;
            var placeholder = MakeText((RectTransform)inputGo.transform, "Type a command…", new Vector2(14f, 0f),
                new Vector2(w - 28f, inputH), 18, new Color(0.45f, 0.5f, 0.58f, 1f), TextAnchor.MiddleLeft);
            placeholder.fontStyle = FontStyle.Italic;
            _paletteInput.textComponent = textComp;
            _paletteInput.placeholder = placeholder;
            _paletteInput.lineType = InputField.LineType.SingleLine;

            // Results column.
            var resGo = new GameObject("PaletteResults", typeof(RectTransform));
            _paletteResults = (RectTransform)resGo.transform;
            _paletteResults.SetParent(rt, false);
            _paletteResults.anchorMin = new Vector2(0f, 1f); _paletteResults.anchorMax = new Vector2(1f, 1f);
            _paletteResults.pivot = new Vector2(0f, 1f);
            _paletteResults.sizeDelta = new Vector2(0f, maxRows * rowH);
            _paletteResults.anchoredPosition = new Vector2(0f, -(inputH + 6f));

            var all = BuildPaletteCommands();
            void Refresh(string filter)
            {
                for (int i = _paletteResults.childCount - 1; i >= 0; i--) Destroy(_paletteResults.GetChild(i).gameObject);
                _paletteMatches.Clear();
                string f = (filter ?? "").Trim().ToLowerInvariant();
                foreach (var c in all)
                {
                    if (f.Length > 0 && !c.Label.ToLowerInvariant().Contains(f) && !c.Menu.ToLowerInvariant().Contains(f))
                        continue;
                    _paletteMatches.Add(c);
                    if (_paletteMatches.Count >= maxRows) break;
                }
                float y = 0f;
                for (int i = 0; i < _paletteMatches.Count; i++)
                {
                    var c = _paletteMatches[i];
                    var item = new MenuItem((i == 0 ? "↵  " : "    ") + c.Menu + " · " + c.Label, true, () =>
                    {
                        CloseMenu(); _paletteInput = null;
                        c.Run();
                    });
                    MakeMenuButton(_paletteResults, item, new Vector2(6f, y), new Vector2(w - 12f, rowH - 2f));
                    y -= rowH;
                }
            }
            Refresh("");
            _paletteInput.onValueChanged.AddListener(Refresh);
            _paletteInput.onSubmit.AddListener(_ =>
            {
                if (_paletteMatches.Count == 0) return;
                var first = _paletteMatches[0];
                CloseMenu(); _paletteInput = null;
                first.Run();
            });

            if (EventSystem.current != null) EventSystem.current.SetSelectedGameObject(inputGo);
            _paletteInput.ActivateInputField();
        }
    }
}
