using System;
using System.IO;
using TheRobotDraft.Authoring.Interchange;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace TheRobotDraft.Editor
{
    /// <summary>
    /// Headless + menu entry point that converts PlantUML (<c>.puml</c>) sources into native
    /// <c>.trd-yaml</c> model files by composing <see cref="PlantUmlReader"/> (parse) with
    /// <see cref="TrdYamlWriter"/> (emit).
    ///
    /// <para><b>Headless / batch use (no Unity UI):</b> invoke from the command line with explicit paths.</para>
    /// <code>
    /// unity -batchmode -nographics -quit -projectPath &lt;repo&gt;/projects/therobotdrafts \
    ///   -executeMethod TheRobotDraft.Editor.ConvertPumlToTrdYaml.ConvertArgs -- &lt;dir1&gt; [dir2...] [-recursive=true|false]
    /// </code>
    /// Or, in the standalone dotnet build, run the validator exe: <c>ConvertArgs -- &lt;dir&gt;</c>.
    ///
    /// <para><b>Interactive (in-editor):</b> the <c>TRD/Convert…</c> menu items use the same
    /// <see cref="ConvertFile"/> / <see cref="ConvertDirectory"/> core.</para>
    /// </summary>
    public static class ConvertPumlToTrdYaml
    {
        /// <summary>Convert a single <c>.puml</c> file to a sibling <c>.trd-yaml</c> file.</summary>
        public static void ConvertFile(string pumlPath)
        {
            if (string.IsNullOrEmpty(pumlPath))
                throw new ArgumentException("ConvertPumlToTrdYaml.ConvertFile: null/empty path", nameof(pumlPath));
            if (!File.Exists(pumlPath))
                throw new FileNotFoundException("PlantUML source not found: " + pumlPath, pumlPath);
            if (!pumlPath.EndsWith(".puml", StringComparison.OrdinalIgnoreCase))
                throw new ArgumentException("ConvertPumlToTrdYaml.ConvertFile: not a .puml file: " + pumlPath, nameof(pumlPath));

            string puml;
            try { puml = File.ReadAllText(pumlPath); }
            catch (Exception ex) { throw new IOException("Failed to read " + pumlPath + ": " + ex.Message, ex); }

            IxModel model;
            try { model = PlantUmlReader.Parse(puml); }
            catch (InterchangeException) { throw; }
            catch (Exception ex) { throw new InterchangeException("PlantUmlReader failed on " + pumlPath + ": " + ex.Message, ex); }

            string yaml = TrdYamlWriter.Write(model);

            string outPath = Path.ChangeExtension(pumlPath, ".trd-yaml");
            try { File.WriteAllText(outPath, yaml); }
            catch (Exception ex) { throw new IOException("Failed to write " + outPath + ": " + ex.Message, ex); }

            int elementCount = model.Elements?.Count ?? 0;
            int diagramCount = model.Diagrams?.Count ?? 0;
            Console.Out.WriteLine("[TRD] " + pumlPath + " -> " + outPath
                + " (" + elementCount + " elements, " + diagramCount + " diagram" + (diagramCount == 1 ? "" : "s") + ")");
        }

        /// <summary>Convert every <c>.puml</c> under <paramref name="dirPath"/>.</summary>
        /// <param name="recursive">Recurse into subdirectories (default true).</param>
        public static void ConvertDirectory(string dirPath, bool recursive = true)
        {
            if (string.IsNullOrEmpty(dirPath))
                throw new ArgumentException("ConvertPumlToTrdYaml.ConvertDirectory: null/empty path", nameof(dirPath));
            if (!Directory.Exists(dirPath))
                throw new DirectoryNotFoundException("Source directory not found: " + dirPath);

            var option = recursive ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly;
            var pumls = Directory.EnumerateFiles(dirPath, "*.puml", option);
            int converted = 0, skipped = 0;
            foreach (var p in pumls)
            {
                try
                {
                    ConvertFile(p);
                    converted++;
                }
                catch (Exception ex)
                {
                    Console.Error.WriteLine("[TRD] SKIPPED " + p + ": " + ex.GetType().Name + ": " + ex.Message);
                    skipped++;
                }
            }
            Console.Out.WriteLine("[TRD] " + dirPath + ": converted " + converted + ", skipped " + skipped
                + " (recursive=" + recursive + ")");
        }

        /// <summary>
        /// Argv entry point for batch-mode conversion. Each positional arg is a path:
        /// a directory is walked (recursive unless <c>-recursive=false</c> appears), a <c>.puml</c>
        /// file is converted, and other files are skipped.
        /// </summary>
        public static void ConvertArgs(string[] args)
        {
            if (args == null || args.Length == 0)
            {
                Console.Error.WriteLine("[TRD] ConvertArgs: no paths supplied. Usage: ConvertArgs -- <path-or-dir>... [-recursive=false]");
                return;
            }

            bool recursive = true;
            var paths = new System.Collections.Generic.List<string>(args.Length);
            foreach (var a in args)
            {
                if (a == null) continue;
                string trimmed = a.Trim();
                if (trimmed.Length == 0) continue;
                if (trimmed.StartsWith("-recursive=", StringComparison.OrdinalIgnoreCase))
                {
                    if (bool.TryParse(trimmed.Substring("-recursive=".Length), out var r)) recursive = r;
                    continue;
                }
                paths.Add(trimmed);
            }
            if (paths.Count == 0)
            {
                Console.Error.WriteLine("[TRD] ConvertArgs: no paths after parsing args.");
                return;
            }

            foreach (var path in paths)
            {
                try
                {
                    if (Directory.Exists(path)) ConvertDirectory(path, recursive);
                    else if (File.Exists(path) && path.EndsWith(".puml", StringComparison.OrdinalIgnoreCase)) ConvertFile(path);
                    else Console.Error.WriteLine("[TRD] SKIP " + path + " (not a .puml or a directory)");
                }
                catch (Exception ex)
                {
                    Console.Error.WriteLine("[TRD] ERROR " + path + ": " + ex.GetType().Name + ": " + ex.Message);
                }
            }
        }

#if UNITY_EDITOR
        [MenuItem("TRD/Convert PlantUml->.trd-yaml (file)")]
        public static void MenuFile()
        {
            string p = EditorUtility.OpenFilePanelWithFilters(
                "Select PlantUML file to convert", "Assets",
                new[] { "PlantUML", "puml", "All files", "*" });
            if (string.IsNullOrEmpty(p)) return;
            try
            {
                ConvertFile(p);
                EditorUtility.DisplayDialog("TRD", "Conversion complete.", "OK");
            }
            catch (Exception ex)
            {
                EditorUtility.DisplayDialog("TRD", "Conversion failed:\n" + ex.Message, "OK");
                throw;
            }
        }

        [MenuItem("TRD/Convert PlantUml->.trd-yaml (folder)")]
        public static void MenuDir()
        {
            string d = EditorUtility.OpenFolderPanel("Select folder of PlantUML files", "Assets", "");
            if (string.IsNullOrEmpty(d)) return;
            try
            {
                ConvertDirectory(d, recursive: true);
                EditorUtility.DisplayDialog("TRD", "Conversion complete.", "OK");
            }
            catch (Exception ex)
            {
                EditorUtility.DisplayDialog("TRD", "Conversion failed:\n" + ex.Message, "OK");
                throw;
            }
        }
#endif
    }
}
