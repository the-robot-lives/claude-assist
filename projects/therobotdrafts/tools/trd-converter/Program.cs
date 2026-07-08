using System;
using System.IO;
using TheRobotDraft.Authoring.Interchange;

namespace TheRobotDraft.Tools.Converter
{
    /// <summary>
    /// Headless entry point: reads a <c>.puml</c> file (or every <c>.puml</c> under a directory),
    /// parses it via <see cref="PlantUmlReader"/> into an <see cref="IxModel"/>, and writes a sibling
    /// <c>.trd-yaml</c> via <see cref="TrdYamlWriter"/>. Same core path the in-editor converter uses.
    ///
    /// <para>Usage:</para>
    /// <list type="bullet">
    /// <item><c>trd-converter &lt;path.puml&gt;</c> — convert one file</item>
    /// <item><c>trd-converter &lt;dir&gt;</c> — convert every .puml under dir (recursive)</item>
    /// <item><c>trd-converter &lt;dir&gt; --no-recurse</c> — top-level only</item>
    /// <item><c>trd-converter --check &lt;path.puml&gt;</c> — write then read back and assert the
    ///   round-trip is byte-identical (validation, no .trd-yaml written)</item>
    /// </list>
    /// </summary>
    public static class Program
    {
        public static int Main(string[] args)
        {
            if (args == null || args.Length == 0)
            {
                PrintUsage();
                return 1;
            }

            bool checkOnly = false;
            bool diffMode = false;
            bool recursive = true;
            var paths = new System.Collections.Generic.List<string>();
            foreach (var a in args)
            {
                if (a == "--no-recurse") recursive = false;
                else if (a == "--check") checkOnly = true;
                else if (a == "--diff") diffMode = true;
                else if (a == "-h" || a == "--help") { PrintUsage(); return 0; }
                else if (!a.StartsWith("--")) paths.Add(a);
            }
            if (paths.Count == 0) { PrintUsage(); return 1; }

            if (diffMode)
            {
                foreach (var path in paths)
                {
                    Console.Out.WriteLine("--- " + path + " ---");
                    DiffCheck.Run(path);
                }
                return 0;
            }

            int converted = 0, skipped = 0, checkFailures = 0;
            foreach (var path in paths)
            {
                if (Directory.Exists(path))
                {
                    var option = recursive ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly;
                    foreach (var f in Directory.EnumerateFiles(path, "*.puml", option))
                    {
                        var (ok, msg) = checkOnly ? Check(f) : Convert(f);
                        if (ok) converted++;
                        else { skipped++; if (checkOnly && !msg.StartsWith("READ")) checkFailures++; }
                    }
                }
                else if (File.Exists(path) && path.EndsWith(".puml", StringComparison.OrdinalIgnoreCase))
                {
                    var (ok, msg) = checkOnly ? Check(path) : Convert(path);
                    if (ok) converted++;
                    else skipped++;
                }
                else
                {
                    Console.Error.WriteLine("[trd] SKIP " + path + " (not a .puml file or directory)");
                    skipped++;
                }
            }

            string mode = checkOnly ? "checked" : "converted";
            Console.Out.WriteLine("[trd] " + mode + " " + converted + ", skipped " + skipped
                + (checkOnly ? (", round-trip failures " + checkFailures) : ""));
            return skipped > 0 ? 2 : 0;
        }

        private static (bool ok, string msg) Convert(string pumlPath)
        {
            try
            {
                var model = ReadModel(pumlPath);
                string yaml = TrdYamlWriter.Write(model);
                string outPath = Path.ChangeExtension(pumlPath, ".trd-yaml");
                File.WriteAllText(outPath, yaml);
                Console.Out.WriteLine("[trd] " + Path.GetRelativePath(Directory.GetCurrentDirectory(), pumlPath)
                    + " -> " + Path.GetRelativePath(Directory.GetCurrentDirectory(), outPath)
                    + " (" + model.Elements.Count + " elements, " + model.Edges.Count + " edges, "
                    + model.Diagrams.Count + " diagrams)");
                return (true, "OK");
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine("[trd] FAIL " + pumlPath + ": " + ex.GetType().Name + ": " + ex.Message);
                return (false, ex.Message);
            }
        }

        private static (bool ok, string msg) Check(string pumlPath)
        {
            try
            {
                var model = ReadModel(pumlPath);
                string w1 = TrdYamlWriter.Write(model);
                var model2 = TrdYamlReader.Parse(w1);
                string w2 = TrdYamlWriter.Write(model2);
                bool stable = w1 == w2;
                string status = stable ? "OK  " : "DRIFT";
                Console.Out.WriteLine("[trd] " + status + " " + Path.GetRelativePath(Directory.GetCurrentDirectory(), pumlPath)
                    + " (" + model.Elements.Count + " el, " + model.Edges.Count + " ed)");
                if (!stable)
                {
                    Console.Error.WriteLine("[trd] round-trip drift in " + pumlPath + " — re-parse changed the serialization");
                }
                return (stable, stable ? "OK" : "DRIFT");
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine("[trd] FAIL " + pumlPath + ": " + ex.GetType().Name + ": " + ex.Message);
                return (false, "READ_FAIL");
            }
        }

        private static IxModel ReadModel(string pumlPath)
        {
            string puml = File.ReadAllText(pumlPath);
            return PlantUmlReader.Parse(puml);
        }

        private static void PrintUsage()
        {
            Console.Error.WriteLine("trd-converter — PlantUML (.puml) -> TheRobotDrafts native (.trd-yaml)");
            Console.Error.WriteLine("Usage: trd-converter <file.puml | dir> [--no-recurse] [--check]");
        }
    }
}
