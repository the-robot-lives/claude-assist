using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// The always-visible in-app menu bar (nav-redesign IA v2): File · Edit · Model · Diagram ·
    /// Code · Go · View — the same eight-menu tree the native macOS menu installs (minus the app
    /// menu), so every platform gets the same information architecture. Each button drops the same
    /// <see cref="MenuItem"/> menus the context menus use; "▸" items open their submenu as a nested
    /// dropdown beside the parent (the Open Recent pattern).
    /// </summary>
    public sealed partial class UmlCanvas
    {
        /// <summary>Build the menu-bar strip. Called from <c>BuildCanvas</c>; the context toolbar and
        /// tab bar sit just below it.</summary>
        private void BuildMenuBar()
        {
            var barGo = new GameObject("MenuBar", typeof(RectTransform));
            var bar = (RectTransform)barGo.transform;
            bar.SetParent(_root, false);
            bar.anchorMin = new Vector2(0f, 1f); bar.anchorMax = new Vector2(1f, 1f);
            bar.pivot = new Vector2(0f, 1f);
            bar.sizeDelta = new Vector2(0f, 30f);
            bar.anchoredPosition = new Vector2(0f, 0f);
            var bg = barGo.AddComponent<Image>();
            bg.color = new Color(0.085f, 0.095f, 0.12f, 1f);
            bg.raycastTarget = false;

            float x = 8f;
            AddMenuBarButton(bar, "File", ref x, pos => ShowFileMenu(pos));
            AddMenuBarButton(bar, "Edit", ref x, pos => ShowEditMenu(pos));
            AddMenuBarButton(bar, "Model", ref x, pos => ShowModelMenu(pos));
            AddMenuBarButton(bar, "Diagram", ref x, pos => ShowDiagramMenuV2(pos));
            AddMenuBarButton(bar, "Code", ref x, pos => ShowCodeMenu(pos));
            AddMenuBarButton(bar, "Go", ref x, pos => ShowGoMenu(pos));
            AddMenuBarButton(bar, "View", ref x, pos => ShowViewMenuV2(pos));
        }

        /// <summary>One menu-bar button; opens its dropdown anchored at the button's bottom-left corner.</summary>
        private void AddMenuBarButton(RectTransform bar, string label, ref float x, System.Action<Vector2> open)
        {
            float w = 26f + label.Length * 9f;
            var go = new GameObject("MenuBar:" + label, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(bar, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 1f);
            rt.pivot = new Vector2(0f, 1f);
            rt.sizeDelta = new Vector2(w, 26f);
            rt.anchoredPosition = new Vector2(x, -2f);
            var img = go.AddComponent<Image>();
            img.color = new Color(0.085f, 0.095f, 0.12f, 1f);
            var btn = go.AddComponent<Button>();
            btn.targetGraphic = img;
            var colors = btn.colors;
            colors.highlightedColor = new Color(1.3f, 1.5f, 1.9f, 1f);
            btn.colors = colors;
            MakeText(rt, label + "  ▾", Vector2.zero, new Vector2(w, 26f), 14,
                new Color(0.82f, 0.86f, 0.93f, 1f), TextAnchor.MiddleCenter).raycastTarget = false;

            btn.onClick.AddListener(() =>
            {
                // Screen-space overlay canvas ⇒ world corners are already screen pixels.
                var corners = new Vector3[4];
                rt.GetWorldCorners(corners);
                open(new Vector2(corners[0].x, corners[0].y - 2f)); // bottom-left, just under the button
            });
            x += w + 2f;
        }

        // ------------------------------------------------------------------ File

        private void ShowFileMenu(Vector2 screenPos)
        {
            CloseMenu();
            var items = new List<MenuItem>
            {
                new MenuItem("New Model  (Ctrl/Cmd+N)", true, () => NewDiagram()),
                new MenuItem("Open…  (Ctrl/Cmd+O)", true, () => OpenDiagramFile()),
                new MenuItem("Open Recent ▸", RecentFiles.HasRecent(), () => ShowRecentFilesMenu(screenPos)),
                MenuItem.Separator(),
                new MenuItem("Save  (Ctrl/Cmd+S)", true, () => { CloseMenu(); SaveDiagram(); }),
                new MenuItem("Save As…  (Ctrl/Cmd+Shift+S)", true, () => SaveDiagramAs()),
                MenuItem.Separator(),
                new MenuItem("Import ▸", true, () => ShowImportMenu(screenPos)),
                new MenuItem("Export ▸", true, () => ShowFileExportMenu(screenPos)),
                MenuItem.Separator(),
                new MenuItem("Reset to sample", true, () => ResetToSample()),
                new MenuItem("Delete diagram", _activePackage.IsValid, () => DeleteCurrentDiagram()),
                new MenuItem("Delete project", true, () => DeleteProject()),
            };
            CreateMenu(screenPos, "File", items);
        }

        private void ShowImportMenu(Vector2 screenPos)
        {
            CloseMenu();
            var items = new List<MenuItem>
            {
                new MenuItem("⇄ PlantUML…", true, () => ImportPlantUml()),
                new MenuItem("⇄ XMI…", true, () => ImportXmi()),
                new MenuItem("⇄ Mermaid…", true, () => ImportMermaid()),
                new MenuItem("⇄ EA project (.qea)…", true, () => ImportQea()),
                MenuItem.Separator(),
                new MenuItem("⌁ Source code → elements…", true, () => ShowImportCodeDialog(screenPos)),
                new MenuItem("🖼 Diagram from image…  (vision LLM)", true, () => ShowImageImportDialog(screenPos)),
                new MenuItem("⛁ Database schema → ERD…", true, () => ShowDbConnectDialog(screenPos)),
            };
            CreateMenu(screenPos + new Vector2(220f, 0f), "Import", items);
        }

        private void ShowFileExportMenu(Vector2 screenPos)
        {
            CloseMenu();
            var items = new List<MenuItem>
            {
                new MenuItem("⇄ PlantUML…", true, () => ExportPlantUml()),
                new MenuItem("⇄ XMI…", true, () => ExportXmi()),
                new MenuItem("⇄ Mermaid…", true, () => ExportMermaid()),
                new MenuItem("⇄ EA project (.qea)…", true, () => ExportQea()),
                MenuItem.Separator(),
                new MenuItem("🖼 Copy view as PNG", true, () => { CloseMenu(); StartCoroutine(CopyViewAsPng()); }),
                new MenuItem($"🖼 Copy selection as PNG  ({_selection.Count})", _selection.Count >= 2,
                    () => { CloseMenu(); CopySelectionAsPng(); }),
                MenuItem.Separator(),
                new MenuItem("⬡ 3D model → OBJ + MTL  (Blender)…", true, () => { CloseMenu(); Export3DModel(true); }),
                new MenuItem("⬡ 3D model → JSON vertex collections…", true, () => { CloseMenu(); Export3DModel(false); }),
                new MenuItem("⬡ 3D model → both formats…", true, () => { CloseMenu(); Export3DModel(true, true); }),
            };
            if (_selection.Count > 0)
            {
                items.Add(MenuItem.Separator());
                items.Add(new MenuItem("⇄ Selection → PlantUML…", true, () => ExportSelectionPlantUml()));
                items.Add(new MenuItem("⇄ Selection → XMI…", true, () => ExportSelectionXmi()));
                items.Add(new MenuItem("⇄ Selection → Mermaid…", true, () => ExportSelectionMermaid()));
            }
            CreateMenu(screenPos + new Vector2(220f, 0f), "Export", items);
        }

        // ------------------------------------------------------------------ Edit

        /// <summary>Edit menu: pure model edits (navigation verbs live in Go, view state in View).</summary>
        private void ShowEditMenu(Vector2 screenPos)
        {
            CloseMenu();
            var items = new List<MenuItem>
            {
                new MenuItem("↶ Undo  (Ctrl/Cmd+Z)", true, () => { CloseMenu(); RunMenuCommand(NativeMacMenu.Undo); }),
                new MenuItem("↷ Redo  (Ctrl/Cmd+Shift+Z)", true, () => { CloseMenu(); RunMenuCommand(NativeMacMenu.Redo); }),
                MenuItem.Separator(),
                new MenuItem("Copy  (Ctrl/Cmd+C)", _selectedId.IsValid, () => { CloseMenu(); RunMenuCommand(NativeMacMenu.Copy); }),
                new MenuItem("Paste  (Ctrl/Cmd+V)", true, () => { CloseMenu(); RunMenuCommand(NativeMacMenu.Paste); }),
                new MenuItem("Delete selection", _selectedId.IsValid || _selection.Count > 0,
                    () => { CloseMenu(); RunMenuCommand(NativeMacMenu.Delete); }),
            };
            CreateMenu(screenPos, "Edit", items);
        }

        // ------------------------------------------------------------------ Model

        /// <summary>Model menu: element creation plus the explicit tool modes (V / C / P).</summary>
        private void ShowModelMenu(Vector2 screenPos)
        {
            CloseMenu();
            string check(ToolMode m) => _toolMode == m ? "✓ " : "   ";
            var items = new List<MenuItem>
            {
                new MenuItem("Add Element ▸", true, () => ShowCanvasAddMenu(screenPos + new Vector2(220f, 0f))),
                MenuItem.Separator(),
                new MenuItem(check(ToolMode.Select) + "Select mode  (V)", true, () => { CloseMenu(); SetToolMode(ToolMode.Select); }),
                new MenuItem(check(ToolMode.Connect) + "Connect mode  (C)", true, () => { CloseMenu(); SetToolMode(ToolMode.Connect); }),
                new MenuItem(check(ToolMode.Place) + "Place mode  (P)", true, () => { CloseMenu(); SetToolMode(ToolMode.Place); }),
            };
            CreateMenu(screenPos, "Model", items);
        }

        // ------------------------------------------------------------------ Diagram

        private void ShowDiagramMenuV2(Vector2 screenPos)
        {
            CloseMenu();
            var items = new List<MenuItem>
            {
                new MenuItem("New empty diagram", true, () => NewDiagram()),
                new MenuItem("Delete diagram", _activePackage.IsValid, () => DeleteCurrentDiagram()),
                MenuItem.Separator(),
                new MenuItem("Layout ▸", true, () => ShowCanvasLayoutMenu(screenPos + new Vector2(220f, 0f))),
            };
            CreateMenu(screenPos, "Diagram", items);
        }

        // ------------------------------------------------------------------ Code

        /// <summary>Code menu: round-trip is a first-class pillar — generation, ingestion, database.</summary>
        private void ShowCodeMenu(Vector2 screenPos)
        {
            CloseMenu();
            var items = new List<MenuItem>
            {
                new MenuItem("⌁ Generate code…  (wizard)", true, () => ShowCodeGenWizard(screenPos)),
                new MenuItem("⌁ Import code → elements…", true, () => ShowImportCodeDialog(screenPos)),
                MenuItem.Separator(),
                new MenuItem("⛁ Database: connect / load schema…", true, () => ShowDbConnectDialog(screenPos)),
                new MenuItem("⛁ Generate Liquibase changelog…", true, () => { CloseMenu(); GenerateLiquibaseChangelog(); }),
            };
            CreateMenu(screenPos, "Code", items);
        }

        // ------------------------------------------------------------------ Go

        /// <summary>Go menu: camera and navigation verbs (the macOS "Go" convention).</summary>
        private void ShowGoMenu(Vector2 screenPos)
        {
            CloseMenu();
            var items = new List<MenuItem>
            {
                new MenuItem("⌖ Frame diagram  (Ctrl/Cmd+F)", true, () => { CloseMenu(); RunMenuCommand(NativeMacMenu.FrameAll); }),
                MenuItem.Separator(),
                new MenuItem("Camera Z up  (Alt+wheel)", true, () => { CloseMenu(); JumpCameraZ(1); }),
                new MenuItem("Camera Z down  (Alt+wheel)", true, () => { CloseMenu(); JumpCameraZ(-1); }),
                new MenuItem("⟳ Cycle drag-navigation mode  (N)", true, () => { CloseMenu(); CycleNavMode(false); }),
            };
            CreateMenu(screenPos, "Go", items);
        }

        // ------------------------------------------------------------------ View

        /// <summary>View menu: presentation state and configuration dialogs.</summary>
        private void ShowViewMenuV2(Vector2 screenPos)
        {
            CloseMenu();
            var items = new List<MenuItem>
            {
                new MenuItem("⬒ Toggle 2D / 3D view", true, () => { CloseMenu(); RunMenuCommand(NativeMacMenu.Toggle2D); }),
                MenuItem.Separator(),
                new MenuItem("🤖 LLM settings…   (code · layout · audit)", true, () => ShowLlmSettings(screenPos)),
                new MenuItem("👁 Vision LLM settings…   (image import)", true, () => ShowVisionLlmSettings(screenPos)),
                MenuItem.Separator(),
                new MenuItem("? Help & shortcuts…", true, () => { CloseMenu(); ShowHelp(); }),
            };
            CreateMenu(screenPos, "View", items);
        }

        /// <summary>Grab the rendered frame (scene + faces, menus already closed) and copy it as a PNG.</summary>
        private IEnumerator CopyViewAsPng()
        {
            yield return new WaitForEndOfFrame();
            Texture2D tex = null;
            try
            {
                tex = ScreenCapture.CaptureScreenshotAsTexture();
                var png = tex.EncodeToPNG();
                Flash(UmlImageClipboard.SaveAndCopyToClipboard(png));
            }
            finally
            {
                if (tex != null) Destroy(tex);
            }
        }
    }
}
