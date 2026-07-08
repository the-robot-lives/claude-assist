using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// The always-visible in-app menu bar (top-left strip): File · Edit · Add · Generate · Layout · Export ·
    /// Settings. Before this, every feature hid behind the right-click canvas menu (or the macOS-only native
    /// menu bar) — discoverability was poor and non-mac players had no menu at all. Each button drops the same
    /// <see cref="MenuItem"/> menus the context menus use, so there is exactly one implementation of every
    /// command; the right-click menus remain as the quick path.
    /// </summary>
    public sealed partial class UmlCanvas
    {
        /// <summary>Build the menu-bar strip. Called from <c>BuildCanvas</c>; the tab bar sits just below it.</summary>
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
            AddMenuBarButton(bar, "File", ref x, pos => ShowCanvasDiagramMenu(pos));
            AddMenuBarButton(bar, "Edit", ref x, pos => ShowEditMenu(pos));
            AddMenuBarButton(bar, "Add", ref x, pos => ShowCanvasAddMenu(pos));
            AddMenuBarButton(bar, "Generate", ref x, pos => ShowCanvasGenerateMenu(pos));
            AddMenuBarButton(bar, "Layout", ref x, pos => ShowCanvasLayoutMenu(pos));
            AddMenuBarButton(bar, "Export", ref x, pos => ShowExportMenu(pos));
            AddMenuBarButton(bar, "Settings", ref x, pos => ShowSettingsMenu(pos));
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

        // ------------------------------------------------------------------ Edit menu

        /// <summary>Edit menu: the native-menu commands, now reachable on every platform.</summary>
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
                MenuItem.Separator(),
                new MenuItem("⌖ Frame diagram  (Ctrl/Cmd+F)", true, () => { CloseMenu(); RunMenuCommand(NativeMacMenu.FrameAll); }),
                new MenuItem("⬒ Toggle 2D / 3D view", true, () => { CloseMenu(); RunMenuCommand(NativeMacMenu.Toggle2D); }),
                new MenuItem("⟳ Cycle drag-navigation mode", true, () => { CloseMenu(); RunMenuCommand(NativeMacMenu.CycleNav); }),
            };
            CreateMenu(screenPos, "Edit", items);
        }

        // ------------------------------------------------------------------ Settings menu

        /// <summary>All configuration dialogs in one place (they were scattered across two context menus).</summary>
        private void ShowSettingsMenu(Vector2 screenPos)
        {
            CloseMenu();
            var items = new List<MenuItem>
            {
                new MenuItem("🤖 LLM settings…   (code · layout · audit)", true, () => ShowLlmSettings(screenPos)),
                new MenuItem("👁 Vision LLM settings…   (image import)", true, () => ShowVisionLlmSettings(screenPos)),
                new MenuItem("⛁ Database connection…   (ERD import)", true, () => ShowDbConnectDialog(screenPos)),
                MenuItem.Separator(),
                new MenuItem("? Help & shortcuts…", true, () => { CloseMenu(); ShowHelp(); }),
            };
            CreateMenu(screenPos, "Settings", items);
        }

        // ------------------------------------------------------------------ Export menu

        /// <summary>Every way out of the tool: code, changelog, PNG, and the 3-D model formats.</summary>
        private void ShowExportMenu(Vector2 screenPos)
        {
            CloseMenu();
            var items = new List<MenuItem>
            {
                new MenuItem("⌁ Export code…  (wizard)", true, () => ShowCodeGenWizard(screenPos)),
                new MenuItem("⛁ Liquibase changelog…", true, () => { CloseMenu(); GenerateLiquibaseChangelog(); }),
                MenuItem.Separator(),
                new MenuItem("🖼 Copy view as PNG", true, () => { CloseMenu(); StartCoroutine(CopyViewAsPng()); }),
                new MenuItem($"🖼 Copy selection as PNG  ({_selection.Count})", _selection.Count >= 2,
                    () => { CloseMenu(); CopySelectionAsPng(); }),
                MenuItem.Separator(),
                new MenuItem("⬡ 3D model → OBJ + MTL  (Blender)…", true, () => { CloseMenu(); Export3DModel(true); }),
                new MenuItem("⬡ 3D model → JSON vertex collections…", true, () => { CloseMenu(); Export3DModel(false); }),
                new MenuItem("⬡ 3D model → both formats…", true, () => { CloseMenu(); Export3DModel(true, true); }),
            };
            CreateMenu(screenPos, "Export", items);
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
