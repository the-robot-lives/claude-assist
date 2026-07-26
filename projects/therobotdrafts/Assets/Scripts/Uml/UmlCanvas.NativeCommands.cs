using UnityEngine;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// Dispatch for the nav-redesign (IA v2) native menu-bar commands — the 1xx–7xx ids declared in
    /// <see cref="NativeMacMenu"/> and emitted by native/RobotDraftMenu/NativeMenu.mm's eight-menu
    /// tree. Every case routes to an existing UmlCanvas verb; dialogs open centered on screen since
    /// a native menu click has no meaningful canvas anchor point.
    /// </summary>
    public sealed partial class UmlCanvas
    {
        private static Vector2 ScreenCenter => new Vector2(Screen.width * 0.5f, Screen.height * 0.5f);

        private void RunRedesignMenuCommand(int cmd)
        {
            switch (cmd)
            {
                // ---------------------------------------------------------- File
                case NativeMacMenu.FileNew: NewDiagram(); break;
                case NativeMacMenu.FileOpen: OpenDiagramFile(); break;
                case NativeMacMenu.FileSave: SaveDiagram(); break;
                case NativeMacMenu.FileSaveAs: SaveDiagramAs(); break;
                case NativeMacMenu.ImportPuml: ImportPlantUml(); break;
                case NativeMacMenu.ImportXmiCmd: ImportXmi(); break;
                case NativeMacMenu.ImportMermaidCmd: ImportMermaid(); break;
                case NativeMacMenu.ImportQeaCmd: ImportQea(); break;
                case NativeMacMenu.ImportCode: ShowImportCodeDialog(ScreenCenter); break;
                case NativeMacMenu.ImportImage: ShowImageImportDialog(ScreenCenter); break;
                case NativeMacMenu.ImportDb: ShowDbConnectDialog(ScreenCenter); break;
                case NativeMacMenu.ExportPuml: ExportPlantUml(); break;
                case NativeMacMenu.ExportXmiCmd: ExportXmi(); break;
                case NativeMacMenu.ExportMermaidCmd: ExportMermaid(); break;
                case NativeMacMenu.ExportQeaCmd: ExportQea(); break;
                case NativeMacMenu.ExportPng: StartCoroutine(CopyViewAsPng()); break;
                case NativeMacMenu.Export3DObj: Export3DModel(true); break;
                case NativeMacMenu.Export3DJson: Export3DModel(false); break;

                // ---------------------------------------------------------- Edit
                case NativeMacMenu.EditUndo: if (!GeoUndo()) Undo(); break;
                case NativeMacMenu.EditRedo: if (!GeoRedo()) Redo(); break;
                case NativeMacMenu.EditCopy: if (_selectedId.IsValid) CopyElement(_selectedId); break;
                case NativeMacMenu.EditPaste: PasteElement(); break;
                case NativeMacMenu.EditDelete: DeleteSelected(); break;

                // ---------------------------------------------------------- Model
                case NativeMacMenu.AddClass: MenuAddKind(ElementKind.Class); break;
                case NativeMacMenu.AddInterface: MenuAddKind(ElementKind.Interface); break;
                case NativeMacMenu.AddEnum: MenuAddKind(ElementKind.Enum); break;
                case NativeMacMenu.AddPackage: PromptAndAdd(ElementId.None, ElementKind.Package, ScreenCenter); break;
                case NativeMacMenu.AddNote: MenuAddNote(); break;
                case NativeMacMenu.ModeSelect: SetToolMode(ToolMode.Select); break;
                case NativeMacMenu.ModeConnect: SetToolMode(ToolMode.Connect); break;
                case NativeMacMenu.ModePlace: SetToolMode(ToolMode.Place); break;

                // ---------------------------------------------------------- Diagram
                case NativeMacMenu.DiagramNew: NewDiagram(); break;
                case NativeMacMenu.DiagramDelete: DeleteCurrentDiagram(); break;
                case NativeMacMenu.LayoutGrid: AutoLayout("grid"); break;
                case NativeMacMenu.LayoutForce: AutoLayout("force"); break;
                case NativeMacMenu.LayoutSource: AutoLayout("source"); break;
                case NativeMacMenu.LayoutHierarchy: AutoLayout("hierarchy"); break;
                case NativeMacMenu.LayoutAi: AutoLayoutAI(); break;
                case NativeMacMenu.LayoutSequence: AutoArrangeSequence(); break;

                // ---------------------------------------------------------- Code
                case NativeMacMenu.CodeWizard: ShowCodeGenWizard(ScreenCenter); break;
                case NativeMacMenu.CodeImport: ShowImportCodeDialog(ScreenCenter); break;
                case NativeMacMenu.CodeLiquibase: GenerateLiquibaseChangelog(); break;
                case NativeMacMenu.CodeDbConnect: ShowDbConnectDialog(ScreenCenter); break;

                // ---------------------------------------------------------- Go
                case NativeMacMenu.GoFrameAll:
                    if (_mode2D) Apply2DModeCamera(true); else _scene.FrameAll();
                    Flash("framed diagram"); break;
                case NativeMacMenu.GoZUp: JumpCameraZ(1); break;
                case NativeMacMenu.GoZDown: JumpCameraZ(-1); break;
                case NativeMacMenu.GoCycleNav: CycleNavMode(false); break;
                case NativeMacMenu.GoTrace:
                    if (_selectedId.IsValid) ShowTraceView(_selectedId);
                    else Flash("select an element to trace");
                    break;
                case NativeMacMenu.WindowFullScreen: Screen.fullScreen = !Screen.fullScreen; break;
                case NativeMacMenu.HelpSample: ResetToSample(); break;

                // ---------------------------------------------------------- View
                case NativeMacMenu.ViewToggle2D: Toggle2DMode(); break;
                case NativeMacMenu.ViewHelp: ShowHelp(); break;
                case NativeMacMenu.ViewLlmSettings: ShowLlmSettings(ScreenCenter); break;
                case NativeMacMenu.ViewVisionSettings: ShowVisionLlmSettings(ScreenCenter); break;
                case NativeMacMenu.ViewPreferences: ShowPreferences(ScreenCenter); break;
            }
        }

        /// <summary>Menu-bar Add: prompt-and-add into the active package (a diagram must exist first).</summary>
        private void MenuAddKind(ElementKind kind)
        {
            if (!_activePackage.IsValid) { Flash("add a package first (Model → Add Element → Package)"); return; }
            PromptAndAdd(_activePackage, kind, ScreenCenter);
        }

        private void MenuAddNote()
        {
            if (!_activePackage.IsValid) { Flash("add a package first (Model → Add Element → Package)"); return; }
            ShowNoteEditor(_activePackage, ElementId.None, ScreenCenter);
        }
    }
}
