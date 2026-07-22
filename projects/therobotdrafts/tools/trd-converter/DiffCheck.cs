using System;
using System.IO;
using TheRobotDraft.Authoring.Interchange;

namespace TheRobotDraft.Tools.Converter
{
    /// <summary>Diagnostic: shows the first differing lines between Write(model) and Write(Parse(Write(model))).</summary>
    public static class DiffCheck
    {
        public static int Run(string pumlPath)
        {
            var model = PlantUmlReader.Parse(File.ReadAllText(pumlPath));
            string w1 = TrdYamlWriter.Write(model);
            string w2 = TrdYamlWriter.Write(TrdYamlReader.Parse(w1));
            if (w1 == w2) { Console.Out.WriteLine("STABLE"); return 0; }
            var a = w1.Split('\n');
            var b = w2.Split('\n');
            Console.Out.WriteLine("=== w1 lines: " + a.Length + ", w2 lines: " + b.Length + " ===");
            int n = Math.Min(a.Length, b.Length);
            int firstDiff = -1;
            for (int i = 0; i < n; i++) { if (a[i] != b[i]) { firstDiff = i; break; } }
            int ctx = firstDiff < 0 ? n - 1 : firstDiff;
            int lo = Math.Max(0, ctx - 2);
            for (int i = lo; i < Math.Min(n, ctx + 6); i++)
            {
                string mark = a[i] == b[i] ? "  " : ">>";
                Console.Out.WriteLine(mark + " w1[" + i + "]: " + a[i]);
                Console.Out.WriteLine(mark + " w2[" + i + "]: " + b[i]);
            }
            if (a.Length != b.Length)
                Console.Out.WriteLine("(length differs: w1=" + a.Length + " w2=" + b.Length + ")");
            return 1;
        }
    }
}
