using System.Diagnostics;
using System.IO;
using UnityEngine;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// Writes a diagram snapshot to disk and pushes it onto the OS clipboard as an image. On macOS the PNG is
    /// placed on the pasteboard via <c>osascript</c> (so it pastes straight into Keynote / Slack / docs); on
    /// other platforms the file path is copied instead (the system copy buffer is text-only there).
    /// </summary>
    public static class UmlImageClipboard
    {
        /// <summary>
        /// Save <paramref name="png"/> to a temp file and copy it to the clipboard. Returns a short status line
        /// suitable for the canvas hint (whether the image landed on the clipboard or only the path did).
        /// </summary>
        public static string SaveAndCopyToClipboard(byte[] png)
        {
            string path = Path.Combine(Application.temporaryCachePath, "trd-diagram.png");
            try { File.WriteAllBytes(path, png); }
            catch (System.Exception ex) { return "PNG save failed: " + ex.Message; }

            if (Application.platform == RuntimePlatform.OSXEditor
                || Application.platform == RuntimePlatform.OSXPlayer)
            {
                try
                {
                    // Read the file as PNG image data and set it as the clipboard contents. The «class PNGf»
                    // four-char-code tells AppleScript to treat the bytes as a PNG image, not as text.
                    string script = "set the clipboard to (read (POSIX file \"" + path + "\") as «class PNGf»)";
                    var psi = new ProcessStartInfo("osascript")
                    {
                        UseShellExecute = false,
                        CreateNoWindow = true,
                        RedirectStandardError = true,
                    };
                    psi.ArgumentList.Add("-e");
                    psi.ArgumentList.Add(script);
                    using (var proc = Process.Start(psi))
                    {
                        proc.WaitForExit();
                        if (proc.ExitCode == 0) return "copied diagram to clipboard (PNG)";
                    }
                }
                catch { /* fall through to the path-copy fallback below */ }
            }

            GUIUtility.systemCopyBuffer = path;
            return "saved PNG → " + path + " (path copied)";
        }
    }
}
