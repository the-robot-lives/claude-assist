/**
 * iffywow/web — <ithkuil-word> custom element.
 *
 * The component is clever about presentation and deliberately stupid about
 * Ithkuil: it never parses romanization, ranks enums, or does integer
 * arithmetic. It renders a precomputed scene model, or compiles one locally
 * from a coordinate wire form via the bundled scene compiler.
 *
 * Inputs (precedence order):
 *   .model       — full render model injected by the host (Hologram path)
 *   .coordinate  — wire coordinate (array, or JSON string via attribute);
 *                  compiled locally with compileScene()
 *   latinized / integer — optional codec-provided facts (decimal string!)
 *
 * Interaction:
 *   click / Enter / Space  → toggle compact ⇄ exploded
 *                            (emits composed "ithkuil-mode-change")
 *   contextmenu / Shift+F10 → detail panel: latinized, integer, coordinate,
 *                             copy buttons, copy-SVG (with embedded metadata)
 *   hover                  → highlights the hovered socket subtree
 *   Escape                 → close panel
 *
 * Authored as plain ES modules (no decorators) so it runs without a build
 * step; `lit` resolves via node_modules or an import map.
 */
import {LitElement, css, html, nothing, svg} from "lit";
import {compileScene} from "./scene.js";
import {sceneToSVG, extractCoordinate} from "./metadata.js";

const scopeOf = (id) => id.replace(/\.(marker|link)$/, "");

export class IthkuilWordElement extends LitElement {
  static properties = {
    model: {attribute: false},
    coordinate: {
      converter: {
        fromAttribute: (value) => {
          try {
            return JSON.parse(value);
          } catch {
            return value; // compileScene will surface the parse error
          }
        },
        toAttribute: (value) => JSON.stringify(value),
      },
    },
    latinized: {type: String},
    integer: {type: String},
    exploded: {type: Boolean, reflect: true},
    _menu: {state: true},
    _hover: {state: true},
    _error: {state: true},
  };

  static styles = css`
    :host {
      display: inline-block;
      position: relative;
      /* no layout/paint containment: it would make :host the containing
         block for the position:fixed context menu */
      --_stroke: var(--ithkuil-stroke, currentColor);
      --_accent: var(--ithkuil-accent, #b45309);
    }
    svg {
      display: block;
      max-width: 100%;
      overflow: visible;
      cursor: pointer;
      outline-offset: 4px;
    }
    g path {
      fill: none;
      stroke: var(--_stroke);
      stroke-linecap: round;
      stroke-linejoin: round;
      transition: stroke 120ms ease;
    }
    g[data-kind="base"] path {
      stroke-width: 3;
    }
    g[data-kind="modifier"] path {
      stroke-width: 2.4;
    }
    g[data-kind="diacritic"] path {
      stroke-width: 2;
    }
    g[data-kind="connector"] path {
      stroke: var(--_accent);
      stroke-width: 1;
      stroke-dasharray: 4 3;
      opacity: 0.65;
      pointer-events: none;
    }
    g[data-kind="socket-marker"] path {
      stroke: var(--_accent);
      stroke-width: 1.25;
    }
    g.hl path {
      stroke: var(--_accent);
    }
    g[data-kind="socket-marker"].hl path {
      stroke-width: 2;
    }
    .error {
      font: 12px/1.4 ui-monospace, SFMono-Regular, Menlo, monospace;
      color: #b91c1c;
      white-space: pre-wrap;
      max-width: 32rem;
    }
    .context-menu {
      position: fixed;
      z-index: 10000;
      min-width: 20rem;
      max-width: min(38rem, calc(100vw - 2rem));
      padding: 0.75rem;
      border: 1px solid color-mix(in srgb, CanvasText 25%, transparent);
      border-radius: 0.5rem;
      background: Canvas;
      color: CanvasText;
      box-shadow: 0 0.5rem 2rem rgb(0 0 0 / 0.25);
      font: 13px/1.5 system-ui, sans-serif;
    }
    .context-menu code {
      display: block;
      overflow-wrap: anywhere;
      white-space: pre-wrap;
      max-height: 10rem;
      overflow-y: auto;
      font-size: 11px;
      padding: 0.25rem 0.4rem;
      border-radius: 0.25rem;
      background: color-mix(in srgb, CanvasText 8%, transparent);
    }
    .context-menu p {
      margin: 0.5rem 0;
    }
    .context-menu button {
      margin: 0.25rem 0.5rem 0 0;
      font: inherit;
    }
    .muted {
      opacity: 0.65;
      font-style: italic;
    }
  `;

  constructor() {
    super();
    this.exploded = false;
    this._onWindowPointerDown = (event) => {
      if (!event.composedPath().includes(this)) this._menu = undefined;
    };
  }

  /** The effective render model (injected or locally compiled). */
  get scene() {
    return this.model ?? this._compiled;
  }

  willUpdate(changed) {
    if (
      changed.has("model") ||
      changed.has("coordinate") ||
      changed.has("latinized") ||
      changed.has("integer")
    ) {
      this._recompute();
    }
  }

  _recompute() {
    this._error = undefined;
    this._compiled = undefined;
    if (this.model || this.coordinate == null) return;
    try {
      this._compiled = compileScene(this.coordinate, {
        latinized: this.latinized || undefined,
        integer: this.integer || undefined,
      });
    } catch (err) {
      this._error = String(err?.message ?? err);
    }
  }

  render() {
    if (this._error) {
      return html`<div class="error" role="alert">ithkuil-word: ${this._error}</div>`;
    }
    const model = this.scene;
    if (!model) {
      return html`<slot></slot>`;
    }
    const [x, y, w, h] = model.viewBox;
    const label = model.latinized
      ? `Ithkuil word: ${model.latinized}`
      : "Ithkuil word";
    return html`
      <svg
        viewBox="${x} ${y} ${w} ${h}"
        role="img"
        tabindex="0"
        aria-label=${label}
        @click=${this._toggle}
        @keydown=${this._onKeyDown}
        @contextmenu=${this._openContextMenu}
      >
        ${this._renderNodes(model)}
      </svg>
      ${this._renderContextMenu(model)}
    `;
  }

  _renderNodes(model) {
    const mode = this.exploded ? "exploded" : "compact";
    return model.nodes.map((node) => {
      const p = node[mode];
      if (!p?.visible || !node.path) return nothing;
      const t = `translate(${p.translate[0]} ${p.translate[1]}) rotate(${p.rotate}) scale(${p.scale})`;
      return svg`
        <g
          data-node-id=${node.id}
          data-kind=${node.kind}
          class=${this._isHighlighted(node.id) ? "hl" : ""}
          transform=${t}
          @pointerenter=${() => (this._hover = scopeOf(node.id))}
          @pointerleave=${() => (this._hover = undefined)}
        ><path d=${node.path}></path></g>
      `;
    });
  }

  _isHighlighted(id) {
    if (!this._hover) return false;
    const s = scopeOf(id);
    return s === this._hover || s.startsWith(`${this._hover}.`);
  }

  _toggle = () => {
    if (this._menu) {
      this._menu = undefined;
      return;
    }
    this.exploded = !this.exploded;
    this.dispatchEvent(
      new CustomEvent("ithkuil-mode-change", {
        detail: {exploded: this.exploded},
        bubbles: true,
        composed: true,
      })
    );
  };

  _onKeyDown = (event) => {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      this._toggle();
    } else if (event.key === "Escape") {
      this._menu = undefined;
    } else if (event.key === "F10" && event.shiftKey) {
      event.preventDefault();
      const rect = this.getBoundingClientRect();
      this._menu = {x: rect.left + rect.width / 2, y: rect.top + rect.height / 2};
    }
  };

  _openContextMenu = (event) => {
    event.preventDefault();
    this._menu = {x: event.clientX, y: event.clientY};
  };

  _renderContextMenu(model) {
    if (!this._menu) return nothing;
    const coordinate = JSON.stringify(model.coordinate);
    const left = Math.max(8, Math.min(this._menu.x, window.innerWidth - 340));
    const top = Math.max(8, Math.min(this._menu.y, window.innerHeight - 240));
    return html`
      <section
        class="context-menu"
        role="dialog"
        aria-label="Ithkuil word details"
        style="left: ${left}px; top: ${top}px;"
        @click=${(event) => event.stopPropagation()}
      >
        <strong>${model.latinized ?? html`<span class="muted">unromanized</span>`}</strong>
        <p>
          <b>Integer</b>
          ${model.integer
            ? html`<code>${model.integer}</code>`
            : html`<span class="muted">not provided — computed by the Elixir/Python codec</span>`}
        </p>
        <p>
          <b>Coordinate</b>
          <code>${coordinate}</code>
        </p>
        ${model.integer
          ? html`<button @click=${() => this._copy(model.integer)}>Copy integer</button>`
          : nothing}
        <button @click=${() => this._copy(coordinate)}>Copy coordinate</button>
        <button @click=${() => this._copy(this.toSVG())}>Copy SVG</button>
        <button @click=${() => (this._menu = undefined)}>Close</button>
      </section>
    `;
  }

  _copy(text) {
    navigator.clipboard?.writeText(text).catch(() => {});
  }

  updated(changed) {
    if (changed.has("_menu")) {
      if (this._menu) {
        window.addEventListener("pointerdown", this._onWindowPointerDown);
      } else {
        window.removeEventListener("pointerdown", this._onWindowPointerDown);
      }
    }
  }

  disconnectedCallback() {
    window.removeEventListener("pointerdown", this._onWindowPointerDown);
    super.disconnectedCallback();
  }

  /**
   * Standalone SVG document string for the current (or given) mode, with the
   * coordinate embedded as metadata — so extractCoordinate(toSVG()) round-trips.
   * @param {"compact" | "exploded"} [mode]
   */
  toSVG(mode) {
    const model = this.scene;
    if (!model) throw new Error("ithkuil-word: no model or coordinate set");
    return sceneToSVG(model, mode ?? (this.exploded ? "exploded" : "compact"));
  }

  /** Exact tuple recovery from any SDK-generated SVG string. */
  static extractCoordinate = extractCoordinate;
}

customElements.define("ithkuil-word", IthkuilWordElement);

// Re-export the toolkit so the main entry matches types.d.ts.
export {compileScene} from "./scene.js";
export {parseCoordinate, toWire} from "./coordinate.js";
export {sceneToSVG, extractCoordinate, extractMetadata} from "./metadata.js";
