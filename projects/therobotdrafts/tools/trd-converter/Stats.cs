using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using TheRobotDraft.Authoring.Interchange;

namespace TheRobotDraft.Tools.Converter
{
    /// <summary>
    /// Coverage / fidelity probe. Parses every .puml (no files written) and reports, per diagram
    /// family and overall: element count, a histogram of <see cref="IxElementType"/> values actually
    /// produced, a histogram of <see cref="IxEdgeType"/> values, and a list of files that came back
    /// empty (0 elements) — the signal that the PlantUmlReader cannot represent that family yet.
    /// </summary>
    public static class Stats
    {
        public static int Run(List<string> files)
        {
            if (files.Count == 0) { Console.Error.WriteLine("[trd] no .puml files to analyze"); return 1; }

            // family = the immediate parent directory name of the .puml (e.g. "bpmn-process").
            var byFamily = new SortedDictionary<string, List<(string file, IxModel model)>>();
            var empty = new List<string>();
            int parseErrors = 0;
            var elHist = new Dictionary<IxElementType, int>();
            var edHist = new Dictionary<IxEdgeType, int>();
            int totalEl = 0, totalEd = 0;

            foreach (var f in files)
            {
                IxModel model;
                try { model = PlantUmlReader.Parse(File.ReadAllText(f)); }
                catch (Exception ex)
                {
                    Console.Error.WriteLine("  x " + Rel(f) + "  PARSE ERROR: " + ex.GetType().Name + ": " + ex.Message);
                    parseErrors++;
                    continue;
                }
                string family = new DirectoryInfo(Path.GetDirectoryName(f) ?? "").Name;
                if (!byFamily.ContainsKey(family)) byFamily[family] = new List<(string, IxModel)>();
                byFamily[family].Add((f, model));
                if (model.Elements.Count == 0) empty.Add(Rel(f));
                foreach (var e in model.Elements) { elHist.TryGetValue(e.Type, out var c); elHist[e.Type] = c + 1; totalEl++; }
                foreach (var e in model.Edges) { edHist.TryGetValue(e.Type, out var c); edHist[e.Type] = c + 1; totalEd++; }
            }

            Console.Out.WriteLine("[trd] coverage probe — " + files.Count + " .puml, " + byFamily.Count + " families");
            Console.Out.WriteLine("────────────────────────────────────────────");
            Console.Out.WriteLine("family                   files   el(avg)   ed(avg)   top element types");
            Console.Out.WriteLine("────────────────────────────────────────────");
            foreach (var kv in byFamily)
            {
                int n = kv.Value.Count;
                int el = kv.Value.Sum(m => m.model.Elements.Count);
                int ed = kv.Value.Sum(m => m.model.Edges.Count);
                double elAvg = (double)el / n;
                double edAvg = (double)ed / n;
                // top 3 element types in this family
                var top = kv.Value.SelectMany(m => m.model.Elements)
                    .GroupBy(e => e.Type.ToString())
                    .OrderByDescending(g => g.Count())
                    .Take(3)
                    .Select(g => g.Key + ":" + g.Count());
                string topStr = string.Join(", ", top);
                string flag = elAvg == 0 ? "  <EMPTY>" : "";
                Console.Out.WriteLine($"{kv.Key,-24} {n,4} {elAvg,9:F1} {edAvg,9:F1}   {topStr}{flag}");
            }

            Console.Out.WriteLine("────────────────────────────────────────────");
            Console.Out.WriteLine("[trd] element-type histogram (all families):");
            foreach (var kv in elHist.OrderByDescending(x => x.Value))
                Console.Out.WriteLine($"    {kv.Key,-22} {kv.Value,6}" + (kv.Key == IxElementType.Unknown ? "  <-- fidelity risk" : ""));

            Console.Out.WriteLine("[trd] edge-type histogram (all families):");
            foreach (var kv in edHist.OrderByDescending(x => x.Value))
                Console.Out.WriteLine($"    {kv.Key,-22} {kv.Value,6}" + (kv.Key == IxEdgeType.Unknown ? "  <-- fidelity risk" : ""));

            Console.Out.WriteLine("────────────────────────────────────────────");
            Console.Out.WriteLine("[trd] totals: " + totalEl + " elements, " + totalEd + " edges, "
                + parseErrors + " parse errors, " + empty.Count + " empty files");
            if (empty.Count > 0)
            {
                Console.Error.WriteLine("[trd] EMPTY (0 elements) — reader cannot represent these families:");
                foreach (var e in empty) Console.Error.WriteLine("    " + e);
            }
            return (empty.Count > 0 || parseErrors > 0) ? 2 : 0;
        }

        private static string Rel(string p)
        {
            try { return Path.GetRelativePath(Directory.GetCurrentDirectory(), p); }
            catch { return p; }
        }
    }
}
