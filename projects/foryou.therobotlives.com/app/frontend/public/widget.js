/*!
 * foryou signup widget — the ONE dynamic-form core (Chunk C / M2).
 *
 * Single dependency-free vanilla core shared by both embed variants:
 *   - Script variant : host adds `<div data-foryou-service data-foryou-list>` + this
 *                       script; each placeholder is upgraded in place inside a Shadow DOM
 *                       and submits cross-origin (CORS) to the foryou public API.
 *   - Iframe variant : the hosted page at /embed/:service/:list renders the SAME placeholder
 *                       with data-foryou-embed="iframe" and loads this script; it is
 *                       same-origin (no CORS) and reports its height to the parent frame.
 *
 * It fetches a List manifest at runtime, renders a field per declared typed attribute,
 * validates client-side, includes a honeypot, submits with the no-leak/always-202 contract,
 * themes per Service branding with a WCAG-AA contrast floor, and shows loading / success /
 * error states accessibly.
 *
 * Backend contract (Chunk B, verified on `develop`):
 *   GET  /api/v1/public/lists/:public_slug                       -> { list: {...manifest} }
 *   GET  /api/v1/public/services/:svc/lists/:list                -> { list: {...manifest} }
 *   POST /api/v1/public/lists/:public_slug/signups               -> 202 { accepted: true }
 *   POST /api/v1/public/services/:svc/lists/:list/signups        -> 202 { accepted: true }
 *   body: { values: { <attr_slug>: <value> }, source, company_website }
 *
 * No build step: authored as clean vanilla JS, well under the 30KB target.
 */
(function () {
  "use strict";

  var GLOBAL_FLAG = "__foryouWidget";
  var MOUNT_FLAG = "__foryouMounted";
  var SELECTOR =
    "[data-foryou-service][data-foryou-list],[data-foryou-slug]";

  // Resolve the origin this script was served from — the foryou API lives there.
  // document.currentScript is only reliable during initial synchronous execution,
  // so capture it immediately and fall back to scanning <script> tags.
  var SCRIPT_ORIGIN = (function () {
    try {
      var cs = document.currentScript;
      if (cs && cs.src) return new URL(cs.src).origin;
      var scripts = document.getElementsByTagName("script");
      for (var i = scripts.length - 1; i >= 0; i--) {
        var s = scripts[i].getAttribute("src") || "";
        if (s.indexOf("widget.js") !== -1) return new URL(s, window.location.href).origin;
      }
    } catch (e) {}
    return window.location.origin;
  })();

  // ── Theme defaults (foryou "neon on black" branding) ────────────────────────
  var DEFAULT_THEME = {
    accent: "#4aedc4",
    accentText: "#05070c",
    surface: "#0c1018",
    surfaceMuted: "#161c28",
    text: "#e6e9ef",
    textMuted: "#9aa4b6",
    border: "#2a3242",
    danger: "#ff5c7a",
    radius: "0.6rem",
    font: '"Space Grotesk", system-ui, -apple-system, Segoe UI, Roboto, sans-serif',
    mode: "auto"
  };
  var LIGHT_OVERRIDES = {
    surface: "#ffffff",
    surfaceMuted: "#f2f4f8",
    text: "#101420",
    textMuted: "#586074",
    border: "#d5dae4"
  };

  var EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  var GUID_RE = /^[0-9a-fA-F]{8}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{12}$/;

  // ── Utilities ────────────────────────────────────────────────────────────────
  function isDev() {
    var h = window.location.hostname;
    return h === "localhost" || h === "127.0.0.1" || h.indexOf(".local") !== -1;
  }
  function warn(msg) {
    if (isDev() && window.console && console.warn) console.warn("[foryou-widget] " + msg);
  }
  function el(tag, attrs, text) {
    var node = document.createElement(tag);
    if (attrs) {
      for (var k in attrs) {
        if (!Object.prototype.hasOwnProperty.call(attrs, k)) continue;
        var v = attrs[k];
        if (v === null || v === undefined || v === false) continue;
        if (k === "text") node.textContent = String(v);
        else node.setAttribute(k, v === true ? "" : String(v));
      }
    }
    if (text != null) node.textContent = String(text);
    return node;
  }
  function safeJSONParse(str) {
    if (!str || typeof str !== "string") return null;
    try {
      return JSON.parse(str);
    } catch (e) {
      warn("invalid JSON in theme/config: " + str);
      return null;
    }
  }

  // ── WCAG-AA contrast floor ─────────────────────────────────────────────────
  function hexToRgb(hex) {
    if (typeof hex !== "string") return null;
    var h = hex.trim().replace(/^#/, "");
    if (h.length === 3) h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2];
    if (!/^[0-9a-fA-F]{6}$/.test(h)) return null;
    return {
      r: parseInt(h.slice(0, 2), 16),
      g: parseInt(h.slice(2, 4), 16),
      b: parseInt(h.slice(4, 6), 16)
    };
  }
  function relLuminance(rgb) {
    var c = [rgb.r, rgb.g, rgb.b].map(function (v) {
      v /= 255;
      return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
    });
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];
  }
  function contrastRatio(fgHex, bgHex) {
    var fg = hexToRgb(fgHex);
    var bg = hexToRgb(bgHex);
    if (!fg || !bg) return null;
    var l1 = relLuminance(fg);
    var l2 = relLuminance(bg);
    var lighter = Math.max(l1, l2);
    var darker = Math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }
  // Ensure `fg` reads on `bg`; if below AA (4.5), swap to whichever of black/white passes.
  function clampForeground(fgHex, bgHex, label) {
    var ratio = contrastRatio(fgHex, bgHex);
    if (ratio === null || ratio >= 4.5) return fgHex;
    var black = contrastRatio("#000000", bgHex) || 0;
    var white = contrastRatio("#ffffff", bgHex) || 0;
    warn(
      "theme " + label + " contrast " + ratio.toFixed(2) + " < AA 4.5 on " + bgHex + "; clamping"
    );
    return white >= black ? "#ffffff" : "#000000";
  }

  function resolveTheme(placeholderTheme, manifestBranding, globalTheme) {
    var mode =
      (placeholderTheme && placeholderTheme.mode) ||
      (globalTheme && globalTheme.mode) ||
      (manifestBranding && manifestBranding.mode) ||
      DEFAULT_THEME.mode;

    if (mode === "auto") {
      mode =
        window.matchMedia && window.matchMedia("(prefers-color-scheme: light)").matches
          ? "light"
          : "dark";
    }

    var theme = {};
    var base = DEFAULT_THEME;
    for (var k in base) if (Object.prototype.hasOwnProperty.call(base, k)) theme[k] = base[k];
    if (mode === "light") {
      for (var lk in LIGHT_OVERRIDES) theme[lk] = LIGHT_OVERRIDES[lk];
    }
    // merge over defaults, not replace; ignore invalid color strings.
    [manifestBranding, globalTheme, placeholderTheme].forEach(function (src) {
      if (!src || typeof src !== "object") return;
      for (var key in src) {
        if (!Object.prototype.hasOwnProperty.call(src, key)) continue;
        var val = src[key];
        if (val == null || val === "") continue;
        theme[key] = val;
      }
    });
    theme.mode = mode;

    // Contrast floors: body text on surface, and button label on accent.
    theme.text = clampForeground(theme.text, theme.surface, "text/surface");
    theme.accentText = clampForeground(theme.accentText, theme.accent, "accentText/accent");
    return theme;
  }

  // ── Styles (scoped to the shadow root via :host custom props) ───────────────
  function styleText() {
    return [
      ":host{all:initial;display:block;",
      "--fy-accent:#4aedc4;--fy-accent-text:#05070c;--fy-surface:#0c1018;",
      "--fy-surface-muted:#161c28;--fy-text:#e6e9ef;--fy-text-muted:#9aa4b6;",
      "--fy-border:#2a3242;--fy-danger:#ff5c7a;--fy-radius:0.6rem;",
      "--fy-font:system-ui,sans-serif;",
      "font-family:var(--fy-font);color:var(--fy-text);}",
      "*{box-sizing:border-box;}",
      ".fy{background:var(--fy-surface);color:var(--fy-text);border:1px solid var(--fy-border);",
      "border-radius:var(--fy-radius);padding:1.25rem;max-width:34rem;font-size:15px;line-height:1.5;}",
      ".fy h2{margin:0 0 .25rem;font-size:1.15rem;font-weight:700;}",
      ".fy p.fy-desc{margin:0 0 1rem;color:var(--fy-text-muted);font-size:.9rem;}",
      ".fy-field{margin-bottom:.85rem;}",
      ".fy-field>label{display:block;margin-bottom:.3rem;font-weight:600;font-size:.85rem;}",
      ".fy-req{color:var(--fy-accent);margin-left:.15rem;}",
      ".fy-input,.fy-select,.fy-textarea{width:100%;padding:.6rem .7rem;font:inherit;color:var(--fy-text);",
      "background:var(--fy-surface-muted);border:1px solid var(--fy-border);border-radius:calc(var(--fy-radius) - .25rem);}",
      ".fy-textarea{min-height:5rem;resize:vertical;}",
      ".fy-input:focus,.fy-select:focus,.fy-textarea:focus,.fy-check input:focus-visible,.fy-btn:focus-visible{",
      "outline:2px solid var(--fy-accent);outline-offset:2px;}",
      ".fy-input[aria-invalid=true],.fy-select[aria-invalid=true],.fy-textarea[aria-invalid=true]{border-color:var(--fy-danger);}",
      ".fy-err{color:var(--fy-danger);font-size:.78rem;margin-top:.25rem;min-height:1em;}",
      ".fy-checks{display:flex;flex-wrap:wrap;gap:.5rem .9rem;padding:.2rem 0;}",
      ".fy-check{display:flex;align-items:center;gap:.35rem;font-size:.85rem;font-weight:400;}",
      ".fy-check input{accent-color:var(--fy-accent);width:auto;}",
      ".fy-hp{position:absolute!important;left:-9999px!important;top:auto!important;width:1px!important;",
      "height:1px!important;overflow:hidden!important;}",
      ".fy-btn{display:inline-flex;align-items:center;justify-content:center;gap:.5rem;width:100%;",
      "margin-top:.4rem;padding:.7rem 1rem;font:inherit;font-weight:700;cursor:pointer;",
      "color:var(--fy-accent-text);background:var(--fy-accent);border:0;border-radius:calc(var(--fy-radius) - .25rem);}",
      ".fy-btn[disabled]{opacity:.6;cursor:default;}",
      ".fy-alert{padding:.7rem .8rem;border-radius:calc(var(--fy-radius) - .25rem);font-size:.85rem;margin-bottom:.75rem;}",
      ".fy-alert--error{background:rgba(255,92,122,.12);border:1px solid var(--fy-danger);color:var(--fy-text);}",
      ".fy-success{text-align:center;padding:.5rem 0;}",
      ".fy-success .fy-check-mark{font-size:2rem;line-height:1;color:var(--fy-accent);}",
      ".fy-success h2{margin:.5rem 0 .35rem;}",
      ".fy-success p{color:var(--fy-text-muted);margin:0;}",
      ".fy-skel{height:1.9rem;border-radius:calc(var(--fy-radius) - .3rem);background:var(--fy-surface-muted);",
      "margin-bottom:.7rem;animation:fy-pulse 1.4s ease-in-out infinite;}",
      ".fy-skel--tall{height:5rem;}",
      "@keyframes fy-pulse{0%,100%{opacity:1}50%{opacity:.45}}",
      "@media (prefers-reduced-motion: reduce){.fy-skel{animation:none;}}",
      ".fy-sr{position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap;}"
    ].join("");
  }

  function applyThemeVars(hostStyleEl, theme) {
    hostStyleEl.textContent =
      ":host{" +
      "--fy-accent:" + theme.accent + ";" +
      "--fy-accent-text:" + theme.accentText + ";" +
      "--fy-surface:" + theme.surface + ";" +
      "--fy-surface-muted:" + theme.surfaceMuted + ";" +
      "--fy-text:" + theme.text + ";" +
      "--fy-text-muted:" + theme.textMuted + ";" +
      "--fy-border:" + theme.border + ";" +
      "--fy-danger:" + theme.danger + ";" +
      "--fy-radius:" + theme.radius + ";" +
      "--fy-font:" + theme.font + ";" +
      "}";
  }

  // ── Config parsing ─────────────────────────────────────────────────────────
  function readConfig(host) {
    var svc = host.getAttribute("data-foryou-service");
    var list = host.getAttribute("data-foryou-list");
    var slug = host.getAttribute("data-foryou-slug");
    var globalCfg = window.foryouConfig || {};
    var apiBase =
      host.getAttribute("data-foryou-api") || globalCfg.apiBase || SCRIPT_ORIGIN;
    apiBase = String(apiBase).replace(/\/$/, "");

    var theme = safeJSONParse(host.getAttribute("data-foryou-theme")) || {};
    var source = host.getAttribute("data-foryou-source") || "widget";
    var isIframe = host.getAttribute("data-foryou-embed") === "iframe";

    var manifestUrl, signupUrl;
    if (slug) {
      manifestUrl = apiBase + "/api/v1/public/lists/" + encodeURIComponent(slug);
      signupUrl = manifestUrl + "/signups";
    } else if (svc && list) {
      var p =
        apiBase +
        "/api/v1/public/services/" +
        encodeURIComponent(svc) +
        "/lists/" +
        encodeURIComponent(list);
      manifestUrl = p;
      signupUrl = p + "/signups";
    }
    return {
      valid: !!manifestUrl,
      manifestUrl: manifestUrl,
      signupUrl: signupUrl,
      theme: theme,
      globalTheme: globalCfg.theme || null,
      source: source,
      isIframe: isIframe
    };
  }

  // ── Attribute normalization / sanitization ──────────────────────────────────
  var KNOWN_TYPES = {
    email: 1, string: 1, text: 1, int: 1, float: 1, date: 1, guid: 1, select: 1, multiselect: 1
  };
  function normalizeOptions(options) {
    if (!Array.isArray(options)) return [];
    return options.slice(0, 200).map(function (o) {
      if (o && typeof o === "object") {
        var value = o.value != null ? String(o.value) : String(o.label != null ? o.label : "");
        var label = o.label != null ? String(o.label) : value;
        return { label: label, value: value };
      }
      return { label: String(o), value: String(o) };
    });
  }
  function normalizeAttributes(raw) {
    if (!Array.isArray(raw)) return [];
    return raw
      .filter(function (a) {
        return a && typeof a.slug === "string";
      })
      .map(function (a) {
        var type = KNOWN_TYPES[a.type] ? a.type : "string"; // unknown -> text input
        return {
          slug: String(a.slug),
          name: a.name ? String(a.name) : String(a.slug),
          type: type,
          required: !!a.required,
          isIdentity: !!a.is_identity,
          options: normalizeOptions(a.options),
          validation: a.validation && typeof a.validation === "object" ? a.validation : {},
          sortOrder: typeof a.sort_order === "number" ? a.sort_order : 0
        };
      })
      .sort(function (x, y) {
        return x.sortOrder - y.sortOrder;
      });
  }

  // ── Field rendering ──────────────────────────────────────────────────────────
  function urlPrefill(attr) {
    // Prefill from query string: exact slug match, plus guid conveniences.
    try {
      var q = new URLSearchParams(window.location.search);
      if (q.has(attr.slug)) return q.get(attr.slug);
      if (attr.type === "guid") {
        var keys = ["invite_token", "token", "ref", "invite"];
        for (var i = 0; i < keys.length; i++) if (q.has(keys[i])) return q.get(keys[i]);
      }
    } catch (e) {}
    return null;
  }

  function buildField(attr, idBase) {
    var fieldId = idBase + "-" + attr.slug;
    var errId = fieldId + "-err";
    var wrap = el("div", { class: "fy-field" });
    var control;
    var prefill = urlPrefill(attr);
    var v = attr.validation || {};

    var describedBy = errId;

    if (attr.type === "multiselect") {
      var fs = el("fieldset", {
        class: "fy-checks",
        role: "group",
        "aria-labelledby": fieldId + "-legend"
      });
      fs.style.border = "0";
      fs.style.margin = "0";
      fs.style.padding = "0";
      attr.options.forEach(function (opt, idx) {
        var cid = fieldId + "-" + idx;
        var lab = el("label", { class: "fy-check", for: cid });
        var input = el("input", {
          type: "checkbox",
          id: cid,
          "data-slug": attr.slug,
          value: opt.value
        });
        lab.appendChild(input);
        lab.appendChild(el("span", null, opt.label));
        fs.appendChild(lab);
      });
      control = fs;
    } else if (attr.type === "select") {
      control = el("select", {
        class: "fy-select",
        id: fieldId,
        "data-slug": attr.slug,
        "aria-describedby": describedBy,
        "aria-required": attr.required ? "true" : null,
        required: attr.required || null
      });
      control.appendChild(el("option", { value: "" }, attr.required ? "Select…" : "—"));
      attr.options.forEach(function (opt) {
        var o = el("option", { value: opt.value }, opt.label);
        if (prefill != null && prefill === opt.value) o.setAttribute("selected", "");
        control.appendChild(o);
      });
    } else if (attr.type === "text") {
      control = el("textarea", {
        class: "fy-textarea",
        id: fieldId,
        "data-slug": attr.slug,
        "aria-describedby": describedBy,
        "aria-required": attr.required ? "true" : null,
        required: attr.required || null,
        maxlength: typeof v.length === "number" ? v.length : null
      });
      if (prefill != null) control.value = prefill;
    } else {
      var inputType = "text";
      var extra = {};
      if (attr.type === "email") {
        inputType = "email";
        extra.autocomplete = "email";
        extra.inputmode = "email";
      } else if (attr.type === "int") {
        inputType = "number";
        extra.step = "1";
        extra.inputmode = "numeric";
        if (typeof v.min === "number") extra.min = v.min;
        if (typeof v.max === "number") extra.max = v.max;
      } else if (attr.type === "float") {
        inputType = "number";
        extra.step = "any";
        extra.inputmode = "decimal";
        if (typeof v.min === "number") extra.min = v.min;
        if (typeof v.max === "number") extra.max = v.max;
      } else if (attr.type === "date") {
        inputType = "date";
      } else if (attr.type === "guid") {
        extra.autocomplete = "off";
        extra.spellcheck = "false";
      } else if (attr.type === "string") {
        if (typeof v.length === "number") extra.maxlength = v.length;
      }
      var attrs = {
        class: "fy-input",
        id: fieldId,
        type: inputType,
        "data-slug": attr.slug,
        "aria-describedby": describedBy,
        "aria-required": attr.required ? "true" : null,
        required: attr.required || null
      };
      for (var ek in extra) attrs[ek] = extra[ek];
      control = el("input", attrs);
      if (prefill != null) control.value = prefill;
    }

    // Label / legend
    var labelText = attr.name;
    if (attr.type === "multiselect") {
      var legend = el("div", { class: "fy-field", id: fieldId + "-legend" });
      legend.className = "";
      var legendLabel = el("label", null);
      legendLabel.id = fieldId + "-legend";
      legendLabel.textContent = labelText;
      if (attr.required) legendLabel.appendChild(el("span", { class: "fy-req" }, "*"));
      wrap.appendChild(legendLabel);
    } else {
      var label = el("label", { for: fieldId }, labelText);
      if (attr.required) label.appendChild(el("span", { class: "fy-req" }, "*"));
      wrap.appendChild(label);
    }

    wrap.appendChild(control);
    var errNode = el("div", { class: "fy-err", id: errId, "aria-live": "polite" });
    wrap.appendChild(errNode);

    return { wrap: wrap, control: control, errNode: errNode, attr: attr };
  }

  // ── Validation & value collection ────────────────────────────────────────────
  function collectValue(field) {
    var attr = field.attr;
    if (attr.type === "multiselect") {
      var checks = field.control.querySelectorAll("input[type=checkbox]");
      var vals = [];
      checks.forEach(function (c) {
        if (c.checked) vals.push(c.value);
      });
      return vals;
    }
    var raw = field.control.value;
    return typeof raw === "string" ? raw.trim() : raw;
  }

  function validateField(field) {
    var attr = field.attr;
    var v = attr.validation || {};
    var value = collectValue(field);

    var empty =
      attr.type === "multiselect" ? value.length === 0 : value === "" || value == null;

    if (empty) {
      return attr.required ? "This field is required." : null;
    }

    switch (attr.type) {
      case "email":
        if (!EMAIL_RE.test(value)) return "Enter a valid email address.";
        break;
      case "int":
        if (!/^-?\d+$/.test(value)) return "Enter a whole number.";
        var iv = parseInt(value, 10);
        if (typeof v.min === "number" && iv < v.min) return "Must be at least " + v.min + ".";
        if (typeof v.max === "number" && iv > v.max) return "Must be at most " + v.max + ".";
        break;
      case "float":
        if (isNaN(Number(value))) return "Enter a number.";
        var fv = Number(value);
        if (typeof v.min === "number" && fv < v.min) return "Must be at least " + v.min + ".";
        if (typeof v.max === "number" && fv > v.max) return "Must be at most " + v.max + ".";
        break;
      case "date":
        if (isNaN(Date.parse(value))) return "Enter a valid date.";
        break;
      case "guid":
        if (!GUID_RE.test(value)) return "Enter a valid identifier.";
        break;
      case "select":
        var ok = attr.options.some(function (o) {
          return o.value === value;
        });
        if (!ok) return "Choose one of the options.";
        break;
      case "multiselect":
        var allowed = attr.options.map(function (o) {
          return o.value;
        });
        var bad = value.some(function (x) {
          return allowed.indexOf(x) === -1;
        });
        if (bad) return "Invalid selection.";
        break;
      default: // string / text / unknown
        if (typeof v.length === "number" && String(value).length > v.length)
          return "Must be " + v.length + " characters or fewer.";
        if (v.pattern) {
          try {
            if (!new RegExp(v.pattern).test(value)) return "Invalid format.";
          } catch (e) {}
        }
    }
    return null;
  }

  function showFieldError(field, msg) {
    if (msg) {
      field.errNode.textContent = msg;
      field.control.setAttribute("aria-invalid", "true");
    } else {
      field.errNode.textContent = "";
      field.control.removeAttribute("aria-invalid");
    }
  }

  function typedValue(field) {
    var attr = field.attr;
    var value = collectValue(field);
    if (attr.type === "multiselect") return value;
    if (value === "" || value == null) return value;
    if (attr.type === "int") return parseInt(value, 10);
    if (attr.type === "float") return Number(value);
    return value;
  }

  // ── Widget instance ────────────────────────────────────────────────────────
  function mount(host) {
    if (host[MOUNT_FLAG]) return;
    var cfg = readConfig(host);
    if (!cfg.valid) {
      host[MOUNT_FLAG] = true;
      warn("placeholder missing data-foryou-slug or data-foryou-service+list; skipped.");
      return;
    }
    host[MOUNT_FLAG] = true;

    var root = host.attachShadow ? host.attachShadow({ mode: "open" }) : host;

    var baseStyle = el("style");
    baseStyle.textContent = styleText();
    var themeStyle = el("style");
    root.appendChild(baseStyle);
    root.appendChild(themeStyle);

    var container = el("div", { class: "fy" });
    root.appendChild(container);

    var live = el("div", { class: "fy-sr", "aria-live": "polite", role: "status" });
    root.appendChild(live);

    // Height reporting for the iframe variant.
    if (cfg.isIframe) setupHeightReporting(host);

    renderSkeleton(container);

    fetchManifest(cfg.manifestUrl)
      .then(function (manifest) {
        var theme = resolveTheme(
          cfg.theme,
          manifest.branding,
          cfg.globalTheme
        );
        applyThemeVars(themeStyle, theme);
        renderForm(container, live, cfg, manifest);
      })
      .catch(function (err) {
        applyThemeVars(themeStyle, resolveTheme(cfg.theme, null, cfg.globalTheme));
        renderUnavailable(container, err && err.code === 404);
      });
  }

  function fetchManifest(url) {
    return fetch(url, {
      method: "GET",
      headers: { Accept: "application/json" },
      credentials: "omit",
      mode: "cors"
    }).then(function (res) {
      if (!res.ok) {
        var e = new Error("manifest " + res.status);
        e.code = res.status;
        throw e;
      }
      return res.json();
    }).then(function (body) {
      var list = (body && body.list) || {};
      var settings = list.settings || {};
      return {
        name: list.name || "Sign up",
        description: list.description || "",
        optInMode: list.opt_in_mode === "double" ? "double" : "single",
        attributes: normalizeAttributes(list.attributes),
        branding:
          settings.branding && typeof settings.branding === "object" ? settings.branding : null,
        successMessage:
          typeof settings.success_message === "string" ? settings.success_message : null
      };
    });
  }

  function renderSkeleton(container) {
    container.innerHTML = "";
    container.setAttribute("aria-busy", "true");
    container.appendChild(el("div", { class: "fy-skel", style: "width:55%" }));
    for (var i = 0; i < 3; i++) container.appendChild(el("div", { class: "fy-skel" }));
    container.appendChild(el("div", { class: "fy-skel fy-skel--tall" }));
  }

  function renderUnavailable(container, isNotFound) {
    container.innerHTML = "";
    container.removeAttribute("aria-busy");
    container.appendChild(el("h2", null, "Sign-up unavailable"));
    container.appendChild(
      el(
        "p",
        { class: "fy-desc" },
        isNotFound
          ? "This sign-up form isn't available right now."
          : "We couldn't load this form. Please try again later."
      )
    );
  }

  function renderForm(container, live, cfg, manifest) {
    container.innerHTML = "";
    container.removeAttribute("aria-busy");

    var idBase = "fy-" + Math.random().toString(36).slice(2, 8);

    container.appendChild(el("h2", null, manifest.name));
    if (manifest.description)
      container.appendChild(el("p", { class: "fy-desc" }, manifest.description));

    var form = el("form", { novalidate: "true" });
    var alertBox = el("div", { class: "fy-alert fy-alert--error", role: "alert" });
    alertBox.style.display = "none";
    form.appendChild(alertBox);

    var fields = [];
    var attrs = manifest.attributes.length
      ? manifest.attributes
      : [
          {
            slug: "email",
            name: "Email",
            type: "email",
            required: true,
            isIdentity: true,
            options: [],
            validation: {},
            sortOrder: 0
          }
        ];

    attrs.forEach(function (attr) {
      var f = buildField(attr, idBase);
      fields.push(f);
      form.appendChild(f.wrap);
    });

    // Honeypot — backend drops non-empty `company_website` silently (Chunk B).
    var hpWrap = el("div", { class: "fy-hp", "aria-hidden": "true" });
    var hp = el("input", {
      type: "text",
      name: "company_website",
      tabindex: "-1",
      autocomplete: "off"
    });
    hpWrap.appendChild(el("label", null, "Company website"));
    hpWrap.appendChild(hp);
    form.appendChild(hpWrap);

    var btn = el("button", { type: "submit", class: "fy-btn" }, "Join");
    form.appendChild(btn);

    container.appendChild(form);

    var submitted = false;
    var busy = false;

    function revalidateAll() {
      var firstBad = null;
      fields.forEach(function (f) {
        var msg = validateField(f);
        showFieldError(f, msg);
        if (msg && !firstBad) firstBad = f;
      });
      return firstBad;
    }

    // live re-validation only after the first submit attempt
    fields.forEach(function (f) {
      var evt = f.attr.type === "select" || f.attr.type === "multiselect" ? "change" : "input";
      f.control.addEventListener(evt, function () {
        if (submitted) showFieldError(f, validateField(f));
      });
    });

    form.addEventListener("submit", function (e) {
      e.preventDefault();
      if (busy) return;
      submitted = true;
      alertBox.style.display = "none";

      var firstBad = revalidateAll();
      if (firstBad) {
        firstBad.control.focus();
        return;
      }

      var values = {};
      fields.forEach(function (f) {
        var val = typedValue(f);
        if (f.attr.type === "multiselect") {
          if (val.length) values[f.attr.slug] = val;
        } else if (val !== "" && val != null) {
          values[f.attr.slug] = val;
        }
      });

      busy = true;
      btn.setAttribute("disabled", "");
      btn.textContent = "Joining…";

      submitSignup(cfg.signupUrl, {
        values: values,
        source: cfg.source,
        company_website: hp.value
      })
        .then(function () {
          renderSuccess(container, live, manifest);
        })
        .catch(function (err) {
          busy = false;
          btn.removeAttribute("disabled");
          btn.textContent = "Join";
          alertBox.textContent = errorCopy(err);
          alertBox.style.display = "block";
          live.textContent = errorCopy(err);
        });
    });
  }

  function submitSignup(url, payload) {
    return fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json" },
      credentials: "omit",
      mode: "cors",
      body: JSON.stringify(payload)
    }).then(function (res) {
      // Always-202 / no-leak: any 2xx is success. Only rate-limit / hard errors branch.
      if (res.status === 429) {
        var e429 = new Error("rate limited");
        e429.code = 429;
        throw e429;
      }
      if (!res.ok && res.status >= 400) {
        var e = new Error("submit " + res.status);
        e.code = res.status;
        throw e;
      }
      return true;
    });
  }

  function errorCopy(err) {
    if (err && err.code === 429)
      return "Too many attempts — please wait a moment and try again.";
    return "Something went wrong — please try again.";
  }

  function renderSuccess(container, live, manifest) {
    var msg =
      manifest.successMessage ||
      (manifest.optInMode === "double"
        ? "Check your inbox to confirm your spot."
        : "You're on the list!");

    container.innerHTML = "";
    var box = el("div", { class: "fy-success" });
    box.appendChild(el("div", { class: "fy-check-mark", "aria-hidden": "true" }, "✓"));
    var h = el("h2", { tabindex: "-1" }, "Thanks!");
    box.appendChild(h);
    box.appendChild(el("p", null, msg));
    container.appendChild(box);
    live.textContent = "Success. " + msg;
    try {
      h.focus();
    } catch (e) {}
  }

  // ── Iframe height reporting ──────────────────────────────────────────────────
  function setupHeightReporting(host) {
    function postHeight() {
      var h = Math.ceil(
        Math.max(
          document.documentElement.scrollHeight,
          host.getBoundingClientRect
            ? host.getBoundingClientRect().bottom + window.scrollY
            : 0
        )
      );
      try {
        window.parent.postMessage(
          { source: "foryou-widget", type: "height", height: h },
          "*"
        );
      } catch (e) {}
    }
    if (window.ResizeObserver) {
      var ro = new ResizeObserver(postHeight);
      ro.observe(document.documentElement);
      if (host) ro.observe(host);
    } else {
      setInterval(postHeight, 500);
    }
    window.addEventListener("load", postHeight);
    setTimeout(postHeight, 60);
    setTimeout(postHeight, 400);
  }

  // ── Bootstrap / discovery ────────────────────────────────────────────────────
  function scan(rootNode) {
    var nodes = (rootNode || document).querySelectorAll(SELECTOR);
    for (var i = 0; i < nodes.length; i++) mount(nodes[i]);
  }

  function boot() {
    scan(document);
    // Catch late-inserted placeholders (SPA navigation / client hydration).
    if (window.MutationObserver) {
      var mo = new MutationObserver(function (mutations) {
        for (var m = 0; m < mutations.length; m++) {
          var added = mutations[m].addedNodes;
          for (var n = 0; n < added.length; n++) {
            var node = added[n];
            if (node.nodeType !== 1) continue;
            if (node.matches && node.matches(SELECTOR)) mount(node);
            if (node.querySelectorAll) scan(node);
          }
        }
      });
      mo.observe(document.documentElement, { childList: true, subtree: true });
    }
  }

  // Expose a manual API (idempotent) for programmatic hosts.
  if (!window[GLOBAL_FLAG]) {
    window[GLOBAL_FLAG] = { mount: mount, scan: scan, origin: SCRIPT_ORIGIN };
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }
})();
