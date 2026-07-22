using System.Collections.Generic;
using TheRobotDraft.Authoring.Interchange;

namespace TheRobotDraft.Authoring.Rules
{
    /// <summary>
    /// Validates an <see cref="IxModel"/> against the native <c>.trd-yaml</c> model rules (plan §2.2). The core
    /// invariant — "packages nest under a diagram" — means every top-level <see cref="IxElementType.Package"/> (one
    /// with no <c>ParentId</c>) must be referenced by at least one <see cref="IxDiagram"/>'s placement list, and
    /// every diagram must name at least one such top-level package placement. This enforces the diagram → package
    /// containment hierarchy at the file level without violating the single-parent element tree (elements remain in
    /// one global pool; placements are references).
    /// </summary>
    public static class TrdModelValidator
    {
        /// <summary>Validate the model, returning the first violation (or <see cref="Validity.Valid"/>).</summary>
        public static Validity Validate(IxModel model)
        {
            if (model == null) return Validity.Invalid("model is null");

            var present = new HashSet<string>(System.StringComparer.Ordinal);
            foreach (var el in model.Elements)
            {
                if (el == null || string.IsNullOrEmpty(el.Id)) continue;
                present.Add(el.Id);
            }

            // Element-level checks: every non-empty parentId must resolve to an existing element.
            foreach (var el in model.Elements)
            {
                if (el == null) continue;
                if (!string.IsNullOrEmpty(el.ParentId) && !present.Contains(el.ParentId))
                    return Validity.Invalid($"element '{el.Id}' has parentId '{el.ParentId}' that does not exist");
            }

            // Top-level packages = Package elements with no parentId. These are the roots a diagram must scope.
            var topLevelPackageIds = new HashSet<string>(System.StringComparer.Ordinal);
            foreach (var el in model.Elements)
            {
                if (el != null && el.Type == IxElementType.Package && string.IsNullOrEmpty(el.ParentId))
                    topLevelPackageIds.Add(el.Id);
            }

            if (model.Diagrams == null || model.Diagrams.Count == 0)
            {
                // A model with top-level packages but no diagram is invalid — those packages would float in open space.
                if (topLevelPackageIds.Count > 0)
                    return Validity.Invalid("top-level package(s) with no diagram: every package must be placed in a diagram");
                return Validity.Valid;
            }

            var placedIds = new HashSet<string>(System.StringComparer.Ordinal);
            foreach (var d in model.Diagrams)
            {
                if (d == null) continue;
                if (d.Nodes == null || d.Nodes.Count == 0)
                    return Validity.Invalid($"diagram '{d.Id}' has no placements — every diagram must place at least one package");

                bool hasTopLevelPkg = false;
                foreach (var pl in d.Nodes)
                {
                    if (pl == null || string.IsNullOrEmpty(pl.ElementId)) continue;
                    placedIds.Add(pl.ElementId);
                    if (topLevelPackageIds.Contains(pl.ElementId)) hasTopLevelPkg = true;
                    if (!present.Contains(pl.ElementId))
                        return Validity.Invalid($"diagram '{d.Id}' places element '{pl.ElementId}' which does not exist in the model");
                }
                if (!hasTopLevelPkg)
                    return Validity.Invalid($"diagram '{d.Id}' does not place any top-level package — a diagram must scope at least one package");
            }

            // Every top-level package must be placed in at least one diagram.
            foreach (var pkgId in topLevelPackageIds)
                if (!placedIds.Contains(pkgId))
                    return Validity.Invalid($"top-level package '{pkgId}' is not placed in any diagram");

            // Edge endpoint existence.
            if (model.Edges != null)
                foreach (var e in model.Edges)
                {
                    if (e == null) continue;
                    if (!string.IsNullOrEmpty(e.FromId) && !present.Contains(e.FromId))
                        return Validity.Invalid($"edge '{e.Id}' has from '{e.FromId}' that does not exist");
                    if (!string.IsNullOrEmpty(e.ToId) && !present.Contains(e.ToId))
                        return Validity.Invalid($"edge '{e.Id}' has to '{e.ToId}' that does not exist");
                }

            return Validity.Valid;
        }
    }
}
