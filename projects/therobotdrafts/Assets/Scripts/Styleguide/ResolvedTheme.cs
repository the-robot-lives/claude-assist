using System.Collections.Generic;

namespace TheRobotDraft.Styleguide
{
    /// <summary>Which color mode a resolved theme is rendered in (the styleguide's light/dark switch).</summary>
    public enum ColorMode { Light, Dark }

    /// <summary>
    /// A resolved styleguide theme: the full token map (seed-derived defaults + the file's active overrides + the
    /// selected color mode's surface/text/border mappings), plus the raw parsed YAML (so the form editor can mutate
    /// values and the emitter can round-trip with comments preserved). Tokens carry their <em>raw</em> string value
    /// (hex, <c>var(--x)</c>, <c>color-mix(...)</c>, font stacks, px); <see cref="TokenEvaluator"/> resolves the
    /// color/numeric ones on demand.
    /// </summary>
    public sealed class ResolvedTheme
    {
        /// <summary>The display name of the theme (from style-guide.meta.yaml).</summary>
        public string Name = "style-guide";

        /// <summary>The full ordered token map: ~300 CSS custom properties by their bare name (no <c>--</c> prefix).</summary>
        public readonly Dictionary<string, string> Tokens = new();

        public ColorMode Mode = ColorMode.Light;

        /// <summary>The parsed YAML root (style-guide.vars.yaml), retained for round-trip editing.</summary>
        public YamlLite.Node VarsYaml;

        /// <summary>The parsed color-modes YAML (light/dark semantic → token maps).</summary>
        public YamlLite.Node ColorModesYaml;

        /// <summary>The parsed semantic-classes YAML (18 named classes with accent-style + vars).</summary>
        public YamlLite.Node SemanticClassesYaml;

        /// <summary>Get a raw token value by bare name, or null.</summary>
        public string Token(string name) => Tokens.TryGetValue(name, out var v) ? v : null;

        /// <summary>Set a raw token value (and, if it's a vars-group seed, mirror it into the parsed YAML).</summary>
        public void SetToken(string name, string value) => Tokens[name] = value ?? "";
    }

    /// <summary>One styleguide semantic class (danger, warning, …): its accent treatment and color vars.</summary>
    public struct SemanticClass
    {
        public string Name;          // e.g. "danger"
        public string Title;         // e.g. "Danger"
        public string AccentStyle;   // bottom-bar | left-border | inner-shadow | outer-shadow | none | …
        public string Accent;        // raw token: "var(--error)"
        public string Background;    // raw token: "var(--error-tint)"
        public string Color;         // raw token: "var(--error)"
    }
}
