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
            SetActivePackage(pkgId);
            SetSelected(ElementId.None);
            RebuildFromModel();
            Flash("opened " + el.Name);
        }

        /// <summary>
        /// Add a package. If a diagram/page is open, the new package becomes a <b>page</b> of it (a sub-package):
        /// it nests under the current package, surfaces in that tab's ▾ pages dropdown, and a linked folder
        /// <see cref="ElementKind.PackageNode"/> is dropped on the current diagram (Cmd/Ctrl-click navigates into
        /// the page). With nothing open, it becomes a new top-level package — a fresh tab/diagram.
        /// </summary>
        private void AddPackageWithNode(Vector2 screenPos)
        {
            var prev = _activePackage; // the diagram/page we're currently viewing (None ⇒ nothing open yet)
            ShowNamePrompt("Package name", "Package" + CountOf(ElementKind.Package), value =>
            {
                string name = string.IsNullOrWhiteSpace(value) ? "Package" + CountOf(ElementKind.Package) : value.Trim();

                if (prev.IsValid && _model.Contains(prev))
                {
                    // Nest the new package under the current one as a page of this diagram.
                    _ctl.EnterAddNode(ElementKind.Package);
                    var pkgId = _ctl.CommitAddNode(prev, name);
                    if (!pkgId.IsValid) { Flash("invalid placement"); _ctl.EnterSelect(); return; }

                    // Drop a folder node on the current diagram, linked to the new page; stay on this diagram.
                    _ctl.EnterAddNode(ElementKind.PackageNode);
                    var nodeId = _ctl.CommitAddNode(prev, name);
                    if (nodeId.IsValid)
                    {
                        _placements.SetPos(nodeId, ScreenToModelPx(screenPos));
                        _ctl.SetZLayer(nodeId, _activeLayer);
                        _packageLink[nodeId] = pkgId;
                    }
                    SetActivePackage(prev); // remain on the current diagram so the user sees the new folder
                    _ctl.EnterSelect();
                    RebuildFromModel();
                    SetSelected(nodeId);
                    Flash("added page + folder");
                }
                else
                {
                    // Nothing open: create a new top-level package — a fresh tab/diagram — and enter it.
                    _ctl.EnterAddNode(ElementKind.Package);
                    var pkgId = _ctl.CommitAddNode(ElementId.None, name);
                    if (!pkgId.IsValid) { Flash("invalid placement"); _ctl.EnterSelect(); return; }
                    SetActivePackage(pkgId);
                    _ctl.EnterSelect();
                    RebuildFromModel();
                    SetSelected(ElementId.None);
                    Flash("added diagram");
                }
            });
        }
    }
}
