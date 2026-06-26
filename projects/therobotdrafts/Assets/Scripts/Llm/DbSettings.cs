using UnityEngine;
using TheRobotDraft.Schema;

namespace TheRobotDraft.Llm
{
    /// <summary>
    /// Persisted database connection settings for the "Load DB schema → ERD" / "Generate Liquibase changelog"
    /// features, stored in <see cref="PlayerPrefs"/> so they survive across sessions (mirrors <see cref="LlmSettings"/>).
    /// The password lives in PlayerPrefs too — acceptable for a local dev/authoring tool, and the same trust model the
    /// LLM API key already uses. Engine is "postgres" or "mysql".
    /// </summary>
    public static class DbSettings
    {
        private const string EngineKey = "trd.db.engine";
        private const string HostKey = "trd.db.host";
        private const string PortKey = "trd.db.port";
        private const string DatabaseKey = "trd.db.database";
        private const string UserKey = "trd.db.user";
        private const string PasswordKey = "trd.db.password";
        private const string SchemaKey = "trd.db.schema";
        private const string AuthorKey = "trd.db.author";

        public const string DefaultEngine = "postgres";
        public const string DefaultHost = "127.0.0.1";
        public const int DefaultPgPort = 5432;
        public const int DefaultMySqlPort = 3306;
        public const string DefaultSchema = "public";

        public static string Author => PlayerPrefs.GetString(AuthorKey, "therobotdrafts");

        public static void Load(out string engine, out string host, out int port, out string database,
            out string user, out string password, out string schema, out string author)
        {
            engine = PlayerPrefs.GetString(EngineKey, DefaultEngine);
            host = PlayerPrefs.GetString(HostKey, DefaultHost);
            port = PlayerPrefs.GetInt(PortKey, DefaultPgPort);
            database = PlayerPrefs.GetString(DatabaseKey, "");
            user = PlayerPrefs.GetString(UserKey, "");
            password = PlayerPrefs.GetString(PasswordKey, "");
            schema = PlayerPrefs.GetString(SchemaKey, DefaultSchema);
            author = PlayerPrefs.GetString(AuthorKey, "therobotdrafts");
        }

        public static void Save(string engine, string host, int port, string database,
            string user, string password, string schema, string author)
        {
            PlayerPrefs.SetString(EngineKey, string.IsNullOrWhiteSpace(engine) ? DefaultEngine : engine.Trim());
            PlayerPrefs.SetString(HostKey, (host ?? DefaultHost).Trim());
            PlayerPrefs.SetInt(PortKey, port > 0 ? port : DefaultPgPort);
            PlayerPrefs.SetString(DatabaseKey, (database ?? "").Trim());
            PlayerPrefs.SetString(UserKey, (user ?? "").Trim());
            PlayerPrefs.SetString(PasswordKey, password ?? "");
            PlayerPrefs.SetString(SchemaKey, (schema ?? DefaultSchema).Trim());
            PlayerPrefs.SetString(AuthorKey, string.IsNullOrWhiteSpace(author) ? "therobotdrafts" : author.Trim());
            PlayerPrefs.Save();
        }

        /// <summary>Assemble a <see cref="DbConnInfo"/> from the persisted settings for an introspection call.</summary>
        public static DbConnInfo ToConn()
        {
            Load(out var engine, out var host, out var port, out var database,
                out var user, out var password, out var schema, out _);
            return new DbConnInfo
            {
                Engine = engine, Host = host, Port = port, Database = database,
                User = user, Password = password, SchemaFilter = schema,
            };
        }
    }
}
