using System;
using System.Collections.Generic;
using UnityEngine;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// PlayerPrefs-backed most-recently-used ring of model file paths (capped at ~10).
    /// Survives app restart. De-dups on add (an existing entry is moved to the front).
    /// Stored as a JSON array via <see cref="JsonUtility"/> (wrapped in a serializable
    /// holder because JsonUtility cannot serialize a bare <c>List&lt;string&gt;</c>).
    /// </summary>
    public static class RecentFiles
    {
        private const string PrefsKey = "trd.recent.files";
        private const int Capacity = 10;

        [Serializable]
        private class PathList { public List<string> paths = new List<string>(); }

        /// <summary>The MRU list, most-recent first. Never null; empty when nothing is stored.</summary>
        public static List<string> GetRecent()
        {
            var json = PlayerPrefs.GetString(PrefsKey, "");
            if (string.IsNullOrEmpty(json)) return new List<string>();
            try
            {
                var pl = JsonUtility.FromJson<PathList>(json);
                return pl?.paths ?? new List<string>();
            }
            catch
            {
                return new List<string>();
            }
        }

        /// <summary>True if at least one recent path is stored.</summary>
        public static bool HasRecent() => GetRecent().Count > 0;

        /// <summary>Promote <paramref name="path"/> to the front of the MRU, de-duping any existing copy. No-op for null/empty.</summary>
        public static void AddRecent(string path)
        {
            if (string.IsNullOrEmpty(path)) return;
            var list = GetRecent();
            list.Remove(path);
            list.Insert(0, path);
            if (list.Count > Capacity) list.RemoveRange(Capacity, list.Count - Capacity);
            Save(list);
        }

        /// <summary>Remove a single path (e.g. a file that failed to open). Persists if changed.</summary>
        public static void Remove(string path)
        {
            if (string.IsNullOrEmpty(path)) return;
            var list = GetRecent();
            if (list.Remove(path)) Save(list);
        }

        /// <summary>Empty the MRU entirely.</summary>
        public static void Clear()
        {
            if (!PlayerPrefs.HasKey(PrefsKey)) return;
            PlayerPrefs.DeleteKey(PrefsKey);
            PlayerPrefs.Save();
        }

        private static void Save(List<string> list)
        {
            var pl = new PathList { paths = list };
            PlayerPrefs.SetString(PrefsKey, JsonUtility.ToJson(pl));
            PlayerPrefs.Save();
        }
    }
}
