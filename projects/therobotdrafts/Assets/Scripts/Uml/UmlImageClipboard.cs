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

        /// <summary>
        /// Read an image off the OS clipboard as PNG bytes (macOS only). Dumps the pasteboard's «class PNGf»
        /// payload to a temp file via <c>osascript</c>, then returns the file's bytes. Returns null when the
        /// clipboard holds no image (osascript exits non-zero) or on any error — never throws to the caller.
        /// </summary>
        public static byte[] TryReadClipboardPng()
        {
            if (Application.platform != RuntimePlatform.OSXEditor
                && Application.platform != RuntimePlatform.OSXPlayer)
                return null;

            string path = Path.Combine(Application.temporaryCachePath, "trd-clip-in.png");
            try
            {
                var psi = new ProcessStartInfo("osascript")
                {
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    RedirectStandardError = true,
                };
                // Each statement is its own -e line. The whole thing fails (non-zero exit) if the clipboard
                // doesn't hold a PNG-coercible image, in which case we return null.
                psi.ArgumentList.Add("-e"); psi.ArgumentList.Add("set thePng to (the clipboard as «class PNGf»)");
                psi.ArgumentList.Add("-e"); psi.ArgumentList.Add("set fp to (POSIX file \"" + path + "\")");
                psi.ArgumentList.Add("-e"); psi.ArgumentList.Add("set fh to open for access fp with write permission");
                psi.ArgumentList.Add("-e"); psi.ArgumentList.Add("set eof fh to 0");
                psi.ArgumentList.Add("-e"); psi.ArgumentList.Add("write thePng to fh");
                psi.ArgumentList.Add("-e"); psi.ArgumentList.Add("close access fh");
                using (var proc = Process.Start(psi))
                {
                    proc.WaitForExit();
                    if (proc.ExitCode != 0) return null; // no image on the clipboard
                }
                if (!File.Exists(path)) return null;
                var bytes = File.ReadAllBytes(path);
                return (bytes != null && bytes.Length > 0) ? bytes : null;
            }
            catch { return null; }
        }
    }
}
