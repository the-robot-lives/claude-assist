using System;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;

namespace TheRobotDraft.Authoring.Model
{
    /// <summary>
    /// UUIDv5-backed documentation pointer identity. The Unicode token alphabet matches the repo's
    /// <c>misc-git-utils doc-pointers</c> utility: four code points from U+13000..U+1342F, wrapped as ⟦code⟧.
    /// </summary>
    public static class DeepLinkIdentity
    {
        public const string NamespaceUuid = "64e9408c-37a7-5f92-8893-f149cbde01c0";
        public const int TokenStart = 0x13000;
        public const int TokenEnd = 0x1342F;
        private const int TokenSize = TokenEnd - TokenStart + 1;
        private const int TokenLength = 4;

        private static readonly Regex MarkerRegex = new Regex("⟦(?<code>[^⟦⟧\\s/?#:%]+)⟧",
            RegexOptions.Compiled);

        private static readonly Regex UuidRegex = new Regex(
            "(?<uuid>[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})",
            RegexOptions.Compiled);

        public static bool DefaultEmbed(ElementKind kind) =>
            kind != ElementKind.Field && kind != ElementKind.Note;

        public static string Uuid5ForElement(ElementId id, ElementKind kind, string name, ElementId parent)
        {
            string seed = "doc-pointers:therobotdrafts:" + (parent.IsValid ? parent.Value : "root")
                + ":" + id.Value + ":" + kind + ":" + (name ?? "");
            return Uuid5(NamespaceUuid, seed);
        }

        /// <summary>UUIDv5 identity for an edge — the aspect sidecar key for a link. Stable across re-derivation.</summary>
        public static string Uuid5ForEdge(EdgeId id, EdgeKind kind, ElementId from, ElementId to, string label)
        {
            string seed = "doc-pointers:therobotdrafts:edge:"
                + id.Value + ":" + kind + ":"
                + (from.IsValid ? from.Value : "?") + "->" + (to.IsValid ? to.Value : "?") + ":"
                + (label ?? "");
            return Uuid5(NamespaceUuid, seed);
        }

        public static string Uuid5(string namespaceUuid, string name)
        {
            byte[] ns = UuidStringToBytes(namespaceUuid);
            byte[] nameBytes = Encoding.UTF8.GetBytes(name ?? "");
            byte[] input = new byte[ns.Length + nameBytes.Length];
            Buffer.BlockCopy(ns, 0, input, 0, ns.Length);
            Buffer.BlockCopy(nameBytes, 0, input, ns.Length, nameBytes.Length);

            byte[] hash;
            using (var sha1 = SHA1.Create())
                hash = sha1.ComputeHash(input);

            byte[] uuid = new byte[16];
            Buffer.BlockCopy(hash, 0, uuid, 0, 16);
            uuid[6] = (byte)((uuid[6] & 0x0F) | 0x50); // version 5
            uuid[8] = (byte)((uuid[8] & 0x3F) | 0x80); // RFC 4122 variant
            return BytesToUuidString(uuid);
        }

        public static string EncodeToken(string uuid)
        {
            byte[] number = UuidStringToBytes(uuid);
            var chars = new List<string>(TokenLength);
            for (int i = 0; i < TokenLength; i++)
            {
                int rem = DivRem(number, TokenSize);
                chars.Add(char.ConvertFromUtf32(TokenStart + rem));
            }
            chars.Reverse();
            return string.Concat(chars);
        }

        public static string Marker(string code) =>
            string.IsNullOrWhiteSpace(code) ? "" : "⟦" + code.Trim() + "⟧";

        public static string DeclarationLine(string uuid, string code, string name, ElementKind kind)
        {
            if (string.IsNullOrWhiteSpace(uuid)) return "";
            string c;
            if (string.IsNullOrWhiteSpace(code))
            {
                try { c = EncodeToken(uuid); }
                catch { return ""; }
            }
            else
            {
                c = code.Trim();
            }
            string n = string.IsNullOrWhiteSpace(name) ? kind.ToString() : name.Trim();
            return Marker(c) + " " + n + " :: uuid5:" + uuid.Trim().ToLowerInvariant() + "; kind:" + kind;
        }

        public static bool TryExtract(ref string doc, out string uuid, out string code)
        {
            uuid = null;
            code = null;
            if (string.IsNullOrWhiteSpace(doc)) return false;

            var marker = MarkerRegex.Match(doc);
            if (!marker.Success) return false;

            code = marker.Groups["code"].Value;
            var uuidMatch = UuidRegex.Match(doc);
            if (uuidMatch.Success) uuid = uuidMatch.Groups["uuid"].Value.ToLowerInvariant();

            var kept = new List<string>();
            foreach (var raw in doc.Replace("\r\n", "\n").Split('\n'))
            {
                string line = raw.Trim();
                if (MarkerRegex.IsMatch(line)) continue;
                if (line.Length > 0) kept.Add(line);
            }
            doc = string.Join("\n", kept).Trim();
            return true;
        }

        private static int DivRem(byte[] bigEndian, int divisor)
        {
            int rem = 0;
            for (int i = 0; i < bigEndian.Length; i++)
            {
                int value = (rem << 8) + bigEndian[i];
                bigEndian[i] = (byte)(value / divisor);
                rem = value % divisor;
            }
            return rem;
        }

        private static byte[] UuidStringToBytes(string uuid)
        {
            string hex = (uuid ?? "").Replace("-", "");
            if (hex.Length != 32) throw new FormatException("invalid UUID: " + uuid);
            var bytes = new byte[16];
            for (int i = 0; i < 16; i++)
                bytes[i] = Convert.ToByte(hex.Substring(i * 2, 2), 16);
            return bytes;
        }

        private static string BytesToUuidString(byte[] bytes)
        {
            var sb = new StringBuilder(36);
            for (int i = 0; i < bytes.Length; i++)
            {
                if (i == 4 || i == 6 || i == 8 || i == 10) sb.Append('-');
                sb.Append(bytes[i].ToString("x2"));
            }
            return sb.ToString();
        }
    }
}
