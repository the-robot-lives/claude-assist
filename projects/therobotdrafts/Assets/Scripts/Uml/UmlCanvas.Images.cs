using System.Collections.Generic;
using System.IO;
using UnityEngine;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// Per-node pictures: any node can carry an image, rendered as a card on its +Z face (the bold name stays
    /// visible as a caption). Pasting an image from the OS clipboard (Cmd/Ctrl+V with an image on the pasteboard)
    /// drops a new <see cref="ElementKind.ObjectInstance"/> node holding that picture; a node's right-click menu can
    /// attach / clear an image on an existing node. The image filename is persisted per element id (with id-remap)
    /// alongside the other view-state. macOS only — clipboard reads shell out to <c>osascript</c>.
    /// </summary>
    public sealed partial class UmlCanvas
    {
        // Element id → PNG filename stored under persistentDataPath/trd-images/.
        private readonly Dictionary<ElementId, string> _nodeImage = new();
        // Runtime texture cache so a rebuild doesn't re-decode the PNG every frame.
        private readonly Dictionary<ElementId, Texture2D> _imageCache = new();

        private static string ImageDir => Path.Combine(Application.persistentDataPath, "trd-images");

        /// <summary>Write PNG bytes to a fresh file under the image dir; returns the bare filename (no path).</summary>
        private string SaveImageBytes(byte[] png)
        {
            try
            {
                Directory.CreateDirectory(ImageDir);
                string file = System.Guid.NewGuid().ToString("N") + ".png";
                File.WriteAllBytes(Path.Combine(ImageDir, file), png);
                return file;
            }
            catch (System.Exception ex)
            {
                Debug.LogWarning("node image save failed: " + ex.Message);
                return null;
            }
        }

        /// <summary>Load (and cache) the texture for a node's stored image, or null if it has none / the file is gone.</summary>
        private Texture2D LoadNodeImage(ElementId id)
        {
            if (_imageCache.TryGetValue(id, out var cached) && cached != null) return cached;
            if (!_nodeImage.TryGetValue(id, out var file) || string.IsNullOrEmpty(file)) return null;
            string path = Path.Combine(ImageDir, file);
            if (!File.Exists(path)) return null;
            try
            {
                var tex = new Texture2D(2, 2);
                if (!tex.LoadImage(File.ReadAllBytes(path))) return null;
                _imageCache[id] = tex;
                return tex;
            }
            catch (System.Exception ex)
            {
                Debug.LogWarning("node image load failed: " + ex.Message);
                return null;
            }
        }

        /// <summary>Drop the cached texture for an id (after the stored image changes or is cleared).</summary>
        private void DropImageCache(ElementId id)
        {
            _imageCache.Remove(id);
        }

        /// <summary>
        /// Paste the OS-clipboard image as a new ObjectInstance node on the active package. Falls back to a flash
        /// if the clipboard holds no image. Placement uses the given screen point (caller passes screen center).
        /// </summary>
        public void PasteImageAsObjectNode(Vector2 screenPos)
        {
            var png = UmlImageClipboard.TryReadClipboardPng();
            if (png == null) { Flash("no image on the clipboard"); return; }
            if (!_activePackage.IsValid) { Flash("add a package first (palette → Package)"); return; }

            string file = SaveImageBytes(png);
            if (file == null) { Flash("could not save pasted image"); return; }

            _ctl.EnterAddNode(ElementKind.ObjectInstance);
            var id = _ctl.CommitAddNode(_activePackage, UniqueName("Image"));
            if (!id.IsValid) { Flash("invalid placement"); _ctl.EnterSelect(); return; }
            _placements.SetPos(id, ScreenToModelPx(screenPos));
            _ctl.SetZLayer(id, _activeLayer);
            _ctl.EnterSelect();

            _nodeImage[id] = file;
            DropImageCache(id);
            RebuildFromModel();
            SetSelected(id);
            Flash("pasted image as Object node");
        }

        /// <summary>Read the clipboard image and attach it to an existing node (replacing any current picture).</summary>
        public void AttachImageToNode(ElementId id)
        {
            if (!id.IsValid || !_model.Contains(id)) return;
            var png = UmlImageClipboard.TryReadClipboardPng();
            if (png == null) { Flash("no image on the clipboard"); return; }
            string file = SaveImageBytes(png);
            if (file == null) { Flash("could not save image"); return; }
            _nodeImage[id] = file;
            DropImageCache(id);
            RebuildFromModel();
            Flash("attached image to node");
        }

        /// <summary>Remove a node's picture (the saved file is left on disk; only the link is dropped).</summary>
        public void ClearNodeImage(ElementId id)
        {
            if (!_nodeImage.ContainsKey(id)) return;
            _nodeImage.Remove(id);
            DropImageCache(id);
            RebuildFromModel();
            Flash("removed image");
        }
    }
}
