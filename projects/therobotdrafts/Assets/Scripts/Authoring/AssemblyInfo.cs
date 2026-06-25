using System.Runtime.CompilerServices;

// The authoring tests seed fixtures through low-level model mutators (AddElement/AddEdge) that are
// internal-by-design ("called only by commands"). Expose internals to the test assembly only.
[assembly: InternalsVisibleTo("TheRobotDraft.Authoring.Tests")]
