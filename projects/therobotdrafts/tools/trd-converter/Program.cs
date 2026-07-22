using System;
using System.Collections.Generic;
using System.IO;
using TheRobotDraft.Authoring.Interchange;

namespace TheRobotDraft.Tools.Converter
{
    /// <summary>
    /// Headless entry point: reads <c>.puml</c> files (or every <c>.puml</c> under a directory),
    /// parses each via <see cref="PlantUmlReader"/> into an <see cref="IxModel"/>, and writes a sibling
    /// <c>.trd-yaml</c> via <see cref="TrdYamlWriter"/>. Pure C# + BCL — no Unity required.
    ///
    /// <para>Modes (flags):</para>
    /// <list type="bullet">
    /// <item><c>(default)</c> — convert each .puml to a sibling .trd-yaml</item>
    /// <item><c>--check</c>  — round-trip validation, no files written (exit 2 on any drift/failure)</item>
    /// <item><c>--stats</c>  — element/edge-type histogram per family (fidelity audit, no files written)</item>
    /// <item><c>--diff &lt;file&gt;</c> — show first differing lines between write and re-write</item>
    /// </list>
    /// <para><c>--no-recurse</c> limits directory walks to top-level. Exit 0 ok, 1 usage, 2 had failures.</para>
    /// </summary>
    public static class Program
    {
        public static int Main(string[] args)
        {
            if (args == null || args.Length == 0) { PrintUsage(); return 1; }

            bool checkOnly = false, diffMode = false, statsMode = false, recursive = true;
            var paths = new List<string>();
            foreach (var a in args)
            {
                if (a == "--no-recurse") recursive = false;
                else if (a == "--check") checkOnly = true;
                else if (a == "--diff") diffMode = true;
                else if (a == "--stats") statsMode = true;
                else if (a == "-h" || a == "--help") { PrintUsage(); return 0; }
                else if (!a.StartsWith("--")) paths.Add(a);
            }
            if (paths.Count == 0) { PrintUsage(); return 1; }

            if (diffMode)
            {
                foreach (var path in paths) { Console.Out.WriteLine("--- " + path + " ---"); DiffCheck.Run(path); }
                return 0;
            }

            var files = ExpandFiles(paths, recursive);
            if (statsMode) return Stats.Run(files);

            Console.Out.WriteLine("[trd] " + (checkOnly ? "checking" : "converting") + " " + files.Count + " .puml file(s)...");
            int converted = 0, skipped = 0, drift = 0, totalElements = 0, totalEdges = 0;
            var failures = new List<string>();
            foreach (var f in files)
            {
                var (ok, msg, nEl, nEd) = checkOnly ? Check(f) : Convert(f);
                if (ok) { converted++; totalElements += nEl; totalEdges += nEd; }
                else { skipped++; failures.Add(Path.GetFileName(f) + " — " + msg); if (checkOnly && msg == "DRIFT") drift++; }
            }

            // Summary
            Console.Out.WriteLine("────────────────────────────────────────────");
            Console.Out.WriteLine("[trd] " + (checkOnly ? "checked" : "converted") + " " + converted + "/" + files.Count
                + (checkOnly ? (", drift " + drift) : "") + ", skipped " + skipped
                + " (" + totalElements + " elements, " + totalEdges + " edges)");
            if (failures.Count > 0)
            {
                Console.Error.WriteLine("[trd] " + (checkOnly ? "drift/failures" : "failures") + ":");
                foreach (var x in failures) Console.Error.WriteLine("    " + x);
            }
            return skipped > 0 ? 2 : 0;
        }

        private static List<string> ExpandFiles(List<string> paths, bool recursive)
        {
            var files = new List<string>();
            foreach (var path in paths)
            {
                if (Directory.Exists(path))
                {
                    var option = recursive ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly;
                    files.AddRange(Directory.EnumerateFiles(path, "*.puml", option));
                }
                else if (File.Exists(path) && path.EndsWith(".puml", StringComparison.OrdinalIgnoreCase))
                {
                    files.Add(path);
                }
                else
                {
                    Console.Error.WriteLine("[trd] SKIP " + path + " (not a .puml file or directory)");
                }
            }
            return files;
        }

        private static (bool ok, string msg, int nEl, int nEd) Convert(string pumlPath)
        {
            try
            {
                var model = ReadModel(pumlPath);
                string yaml = TrdYamlWriter.Write(model);
                string outPath = Path.ChangeExtension(pumlPath, ".trd-yaml");
                File.WriteAllText(outPath, yaml);
                Console.Out.WriteLine("  + " + Rel(pumlPath) + "  (" + model.Elements.Count + " el, "
                    + model.Edges.Count + " ed, " + model.Diagrams.Count + " diag)");
                return (true, "OK", model.Elements.Count, model.Edges.Count);
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine("  x " + Rel(pumlPath) + "  " + ex.GetType().Name + ": " + ex.Message);
                return (false, ex.Message, 0, 0);
            }
        }

        private static (bool ok, string msg, int nEl, int nEd) Check(string pumlPath)
        {
            try
            {
                var model = ReadModel(pumlPath);
                string w1 = TrdYamlWriter.Write(model);
                string w2 = TrdYamlWriter.Write(TrdYamlReader.Parse(w1));
                bool stable = w1 == w2;
                Console.Out.WriteLine("  " + (stable ? "ok " : "!! ") + Rel(pumlPath)
                    + "  (" + model.Elements.Count + " el, " + model.Edges.Count + " ed)");
                return (stable, stable ? "OK" : "DRIFT", model.Elements.Count, model.Edges.Count);
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine("  x " + Rel(pumlPath) + "  " + ex.GetType().Name + ": " + ex.Message);
                return (false, ex.Message, 0, 0);
            }
        }

        private static IxModel ReadModel(string pumlPath) => PlantUmlReader.Parse(File.ReadAllText(pumlPath));

        private static string Rel(string p)
        {
            try { return Path.GetRelativePath(Directory.GetCurrentDirectory(), p); }
            catch { return p; }
        }

        private static void PrintUsage()
        {
            Console.Error.WriteLine("trd-converter — PlantUML (.puml) -> TheRobotDrafts native (.trd-yaml)");
            Console.Error.WriteLine("Usage: trd-converter <file.puml|dir> [--no-recurse] [--check] [--stats] [--diff <file>]");
        }
    }
}
