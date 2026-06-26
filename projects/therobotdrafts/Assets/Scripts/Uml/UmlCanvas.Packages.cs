using System.Collections.Generic;
using UnityEngine;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// Package navigation: a folder-style <see cref="ElementKind.PackageNode"/> dropped on a diagram can be linked
    /// to a top-level Package (tab). Cmd/Ctrl-clicking a linked folder node jumps to that package's tab.
    /// </summary>
    public sealed partial class UmlCanvas
    {
        // PackageNode (folder on a diagram) id → the top-level Package (tab) it opens.
        private readonly Dictionary<ElementId, ElementId> _packageLink = new();

        /// <summary>Switch the active diagram to the given package tab (mirrors the tab-bar click body).</summary>
        public void GoToPackage(ElementId pkgId)
        {
            if (!pkgId.IsValid || !_model.TryGet(pkgId, out var el) || el.Kind != ElementKind.Package) return;
            _activePackage = pkgId;
            SetSelected(ElementId.None);
            RebuildFromModel();
            Flash("opened " + el.Name);
        }

        /// <summary>
        /// Create a new Package (tab) and, if the user is currently viewing a diagram, also drop a linked folder
        /// PackageNode onto that diagram. Cmd/Ctrl-clicking the folder later navigates to the new package's tab.
        /// </summary>
        private void AddPackageWithNode(Vector2 screenPos)
        {
            var prev = _activePackage; // the diagram we're currently viewing (None ⇒ top-level, no diagram yet)
            ShowNamePrompt("Package name", "Package" + CountOf(ElementKind.Package), value =>
            {
                string name = string.IsNullOrWhiteSpace(value) ? "Package" + CountOf(ElementKind.Package) : value.Trim();

                _ctl.EnterAddNode(ElementKind.Package);
                var pkgId = _ctl.CommitAddNode(ElementId.None, name);
                if (!pkgId.IsValid) { Flash("invalid placement"); _ctl.EnterSelect(); return; }

                if (prev.IsValid && _model.Contains(prev))
                {
                    // Drop a folder node on the current diagram, linked to the new package; stay on this diagram.
                    _ctl.EnterAddNode(ElementKind.PackageNode);
                    var nodeId = _ctl.CommitAddNode(prev, name);
                    if (nodeId.IsValid)
                    {
                        _pos[nodeId] = ScreenToModelPx(screenPos);
                        _ctl.SetZLayer(nodeId, _activeLayer);
                        _packageLink[nodeId] = pkgId;
                    }
                    _activePackage = prev; // remain on the current diagram so the user sees the new folder
                    _ctl.EnterSelect();
                    RebuildFromModel();
                    SetSelected(nodeId);
                    Flash("added Package + folder");
                }
                else
                {
                    // No current diagram (the very first / top-level package): enter the new empty package.
                    _activePackage = pkgId;
                    _ctl.EnterSelect();
                    RebuildFromModel();
                    SetSelected(ElementId.None);
                    Flash("added Package");
                }
            });
        }
    }
}
