# ipywidgets — interactive HTML widgets for Jupyter

ipywidgets (aka Jupyter Widgets) provides interactive browser controls — sliders, dropdowns, buttons, text boxes, plots-as-outputs — that are bound bidirectionally to Python kernel state. Widgets are built on **traitlets**: a widget attribute tagged `sync=True` keeps the Python object and its JavaScript view in lock-step over the Jupyter Comm channel. It's the standard way to add GUI interactivity to notebooks (classic Notebook, JupyterLab, VS Code, Colab, and Voilà dashboards). For npl-fim, ipywidgets output is authored as a notebook cell / Python snippet that constructs widgets and either `display()`s them or wires them with `interact`/`observe`.

**Current Version**: ipywidgets 8.x (current major)  **License**: BSD-3-Clause  **Runtime**: a Jupyter kernel + a frontend that ships the widget manager (JupyterLab 3+/Notebook 7 bundle it; Colab/VS Code supported)

## Official Resources & Documentation
- Docs: https://ipywidgets.readthedocs.io/en/stable/
- Widget list: https://ipywidgets.readthedocs.io/en/stable/examples/Widget%20List.html
- GitHub: https://github.com/jupyter-widgets/ipywidgets
- Layout/styling: https://ipywidgets.readthedocs.io/en/stable/examples/Widget%20Styling.html

## Installation & Setup

### pip / conda
```bash
pip install ipywidgets
conda install -c conda-forge ipywidgets
```
On **JupyterLab 3+ and Notebook 7** the extension is bundled — no build step. Legacy stacks may need:
```bash
# classic Notebook < 7
jupyter nbextension enable --py widgetsnbextension
# JupyterLab < 3
jupyter labextension install @jupyter-widgets/jupyterlab-manager
```

### Import
```python
import ipywidgets as widgets
from ipywidgets import interact, interactive, interact_manual, fixed
from IPython.display import display
```

## Core Syntax / API Reference

### Every widget shares a common shape
```python
s = widgets.IntSlider(value=5, min=0, max=10, step=1, description='n:')
display(s)
s.value            # read current value from Python
s.value = 8        # set it — the UI updates live
s.keys             # list of syncable traits
```
All widgets subclass `Widget`; visual ones subclass `DOMWidget`. State lives in traitlets tagged `sync=True`; mutating either side propagates.

### Numeric widgets
```python
widgets.IntSlider(value=50, min=0, max=100, step=1, description='Int')
widgets.FloatSlider(value=1.0, min=0.0, max=10.0, step=0.1, readout_format='.2f')
widgets.IntRangeSlider(value=[20, 80], min=0, max=100)
widgets.FloatLogSlider(value=10, base=10, min=-2, max=4)
widgets.BoundedIntText(value=5, min=0, max=10)
widgets.IntProgress(value=7, min=0, max=10, bar_style='info')   # 'success'|'info'|'warning'|'danger'
```

### Boolean & selection widgets
```python
widgets.ToggleButton(value=False, description='On/Off', button_style='success')
widgets.Checkbox(value=True, description='Enable')
widgets.Dropdown(options=['A', 'B', 'C'], value='A', description='Pick:')
widgets.Dropdown(options=[('One', 1), ('Two', 2)])   # (label, value) pairs
widgets.RadioButtons(options=['X', 'Y', 'Z'])
widgets.Select(options=['a', 'b', 'c'], rows=5)
widgets.SelectionSlider(options=['low', 'med', 'high'])
widgets.SelectMultiple(options=['r', 'g', 'b'])
widgets.ToggleButtons(options=['left', 'center', 'right'])
```

### String, date & misc widgets
```python
widgets.Text(value='', placeholder='type…', description='Name:')
widgets.Textarea(value='', rows=4)
widgets.Combobox(options=['apple', 'apricot'], ensure_option=False)
widgets.Password()
widgets.DatePicker(description='Date')
widgets.ColorPicker(value='#1f77b4', description='Color')
widgets.FileUpload(accept='.csv', multiple=False)
widgets.Button(description='Run', icon='play', button_style='primary')
widgets.HTML(value='<b>rich</b> html')
widgets.Label(value='static text')
```

### The Output widget (capture arbitrary rich output)
```python
out = widgets.Output()
with out:                       # everything printed/plotted here renders in the widget
    print('captured')
    import matplotlib.pyplot as plt
    plt.plot([1, 2, 3]); plt.show()
display(out)
out.clear_output()              # or clear_output(wait=True) to avoid flicker
```

### interact / interactive (auto-build UI from a function)
```python
def f(x, y):
    return x + y

interact(f, x=(0, 10), y=(0.0, 1.0, 0.1))   # tuple -> slider; picks widget by type
interact(f, x=['a', 'b', 'c'])              # list -> dropdown
interact(f, x=widgets.IntSlider(min=-5, max=5))  # explicit widget

# capture the widget object instead of auto-displaying:
w = interactive(f, x=(0, 10), y=(0, 10))
display(w)
w.result                                    # last return value
w.kwargs                                     # current arg dict

# defer execution until a button is pressed (expensive computations):
interact_manual(f, x=(0, 100))

# hold an argument constant:
interact(f, x=(0, 10), y=fixed(3))
```

### observe / link (manual event wiring)
```python
slider = widgets.IntSlider()
label  = widgets.Label()

def on_change(change):
    # change: {'name','old','new','owner','type'}
    label.value = f'value = {change.new}'

slider.observe(on_change, names='value')    # fire on the 'value' trait only
display(widgets.VBox([slider, label]))

# button clicks use on_click, not observe:
btn = widgets.Button(description='Go')
btn.on_click(lambda b: print('clicked'))

# link two widgets' traits (kernel-side or browser-side):
a = widgets.FloatText(); b = widgets.FloatSlider()
widgets.link((a, 'value'), (b, 'value'))     # kernel-side, needs live kernel
widgets.jslink((a, 'value'), (b, 'value'))   # browser-side, works in static export
```

## Widget Categories (Supported controls)
Numeric (Int/Float sliders, range sliders, progress, text), Boolean (Checkbox, ToggleButton), Selection (Dropdown, RadioButtons, Select, SelectMultiple, ToggleButtons, SelectionSlider), String (Text, Textarea, Combobox, Password, HTML, Label), Media/Input (Image, FileUpload, DatePicker, ColorPicker, Play/animation), Button, Output, and containers (Box, HBox, VBox, GridBox, Tab, Accordion, Stack). The broader Jupyter Widgets ecosystem adds `ipyleaflet` (maps), `ipympl` (interactive matplotlib), `ipycanvas`, `bqplot`, `pythreejs`, and `ipydatagrid`.

## How-To

### How to style & theme widgets (colors, width, layout)
```python
btn = widgets.Button(description='Save', button_style='success', icon='check')
# .style controls widget-specific visual traits:
btn.style.button_color = '#2c7fb8'
btn.style.font_weight = 'bold'

slider = widgets.FloatSlider(description='Gain')
slider.style.handle_color = '#d62728'
slider.style.description_width = '80px'          # align long labels

# .layout is CSS-like box styling (applies to ANY widget):
slider.layout = widgets.Layout(width='400px', margin='8px 0')
box = widgets.VBox(
    [btn, slider],
    layout=widgets.Layout(border='1px solid #ccc', padding='10px',
                          width='440px', align_items='center'),
)
display(box)
```
Two knobs: `widget.style` (widget-specific colors like `button_color`, `handle_color`, `bar_color`, `description_width`) and `widget.layout` (a `Layout` of CSS box props: `width`, `height`, `margin`, `padding`, `border`, `display`, `flex`, `grid_template_columns`, `align_items`, `justify_content`).

### How to build an interactive plot that updates live
```python
import numpy as np, matplotlib.pyplot as plt
import ipywidgets as widgets
from IPython.display import display

out = widgets.Output()
freq = widgets.FloatSlider(value=1.0, min=0.1, max=5.0, step=0.1, description='freq')
amp  = widgets.FloatSlider(value=1.0, min=0.1, max=3.0, step=0.1, description='amp')

def redraw(change=None):
    with out:
        out.clear_output(wait=True)          # wait=True prevents flicker
        t = np.linspace(0, 2*np.pi, 400)
        plt.figure(figsize=(6, 3))
        plt.plot(t, amp.value * np.sin(freq.value * t))
        plt.ylim(-3, 3); plt.show()

for w in (freq, amp):
    w.observe(redraw, names='value')
redraw()
display(widgets.VBox([freq, amp, out]))
```
Use an `Output` widget + `clear_output(wait=True)` for flicker-free redraws; for true incremental updates use `ipympl` (`%matplotlib widget`).

### How to lay out a dashboard with tabs and columns
```python
controls = widgets.VBox([widgets.Dropdown(options=['A','B']),
                         widgets.IntSlider(description='N')])
chart    = widgets.Output()
tab = widgets.Tab(children=[widgets.HBox([controls, chart]),
                            widgets.Textarea(value='notes')])
tab.set_title(0, 'Dashboard')
tab.set_title(1, 'Notes')
display(tab)
```
Containers: `HBox`/`VBox` (flex rows/cols), `GridBox` (`Layout(grid_template_columns='repeat(3, 1fr)')`), `Tab`, `Accordion`, `Stack` (show one child by `selected_index`).

### How to make a custom compound widget (subclass a container)
```python
class LabeledSlider(widgets.HBox):
    def __init__(self, name, **kw):
        self.slider = widgets.IntSlider(**kw)
        self.readout = widgets.Label()
        super().__init__([widgets.Label(name), self.slider, self.readout])
        self.slider.observe(self._sync, names='value')
        self._sync()
    def _sync(self, *_):
        self.readout.value = str(self.slider.value)

display(LabeledSlider('Volume', min=0, max=11, value=7))
```
Composition (subclassing `HBox`/`VBox`) is the recommended way to build reusable widgets in pure Python — no JS needed. A true low-level `DOMWidget` with new JS requires an accompanying frontend package.

## Do's and Don'ts

### ✅ Do
- Use `observe(handler, names='value')` to react to a specific trait; the handler receives a `change` dict (`change.new`, `change.old`).
- Use `Button.on_click(cb)` for buttons — buttons have no `value` to observe.
- Capture plots/prints inside an `Output()` widget so they render in your layout, not below the cell.
- Use `interact_manual` / `interactive` for expensive functions so they don't re-run on every slider tick.
- Use `jslink` (not `link`) when the output must work after the kernel stops (static HTML/Voilà export).
- Set `description_width` in `.style` when labels are clipped.

### ❌ Don't
- Don't `observe` without `names=` unless you mean *every* trait — you'll get spurious callbacks.
- Don't rebuild widgets on each interaction (creating a new slider inside the callback) — mutate `.value`/`.options` on the existing one.
- Don't expect widgets to render in a plain `.py` run or a non-widget frontend — they need a Jupyter widget manager.
- Don't put heavy compute directly in a `value` observer bound to a slider drag — debounce, use `interact_manual`, or observe on release.
- Don't confuse `.style` (widget-specific colors) with `.layout` (CSS box) — `button_color` is `.style`, `width` is `.layout`.
- Don't hand-author a `class CounterWidget(DOMWidget)` expecting it to render without a companion JS view — subclass a container instead for pure-Python widgets.

## Styling, Theming & Customization
- **`widget.style`**: widget-specific — `button_color`, `handle_color` (sliders), `bar_color` (progress), `description_width`, `font_weight`, `text_color`.
- **`widget.layout`** (`widgets.Layout`): CSS box model — `width`, `height`, `min/max_width`, `margin`, `padding`, `border`, `display`, `flex`, `flex_flow`, `align_items`, `justify_content`, `grid_template_columns`, `grid_gap`, `visibility`.
- **`button_style` / `bar_style`**: preset semantic classes `'primary' | 'success' | 'info' | 'warning' | 'danger' | ''`.
- **Icons**: FontAwesome names (`icon='play'`, `'check'`, `'trash'`) on `Button`.
- **Global theming**: widgets inherit the JupyterLab/Notebook theme (light/dark); custom CSS can target `.widget-*` classes via a `HTML`/`display(HTML('<style>...'))` cell.
- **Rich labels**: `HTML` and `HTMLMath` widgets render markup and LaTeX (MathJax) in place of plain `Label`.

## Advanced Features
- **`asyncio` integration**: `widgets` play well with `async` callbacks; `Play` widget drives animations via a timer.
- **`ipympl`** (`%matplotlib widget`): fully interactive matplotlib canvases as widgets (pan/zoom, live update) instead of static PNG via `Output`.
- **Companion widget libraries**: `bqplot` (grammar-of-graphics plots as widgets), `ipyleaflet`/`ipympl`/`pythreejs`/`ipyvolume` (maps/3D), `ipydatagrid` (fast tables), `ipycanvas` (2D canvas).
- **Voilà**: renders a notebook of widgets as a standalone web app (`voila notebook.ipynb`), hiding code.
- **Embedding**: `ipywidgets.embed.embed_minimal_html('out.html', views=[w])` exports a static, `jslink`-driven snapshot.
- **Custom widgets**: `DOMWidget` + a TypeScript/JS view package (via `anywidget` for a modern, single-file authoring path).

## Common Pitfalls & Troubleshooting
- **Widget shows as `Model not available` / blank**: frontend extension missing or version mismatch between `ipywidgets` and the lab/notebook widget manager — align versions.
- **Nothing updates**: you observed the wrong trait name, or created a new widget inside the callback instead of mutating the existing one.
- **Flickering plots**: use `Output` + `clear_output(wait=True)`, or switch to `ipympl`.
- **Static HTML export is dead**: kernel-side `link`/`observe` don't survive export — use `jslink` and `embed_minimal_html`.
- **Colab quirks**: enable `from google.colab import output; output.enable_custom_widget_manager()`.
- **Long labels clipped**: raise `style.description_width`.
- **Callbacks fire twice**: a trait changed by your handler re-triggers `observe` — guard with a flag or `unobserve` during the update.

## Integration Notes
- **JupyterLab/Notebook 7**: works out of the box; **VS Code** and **Colab** supported with the custom widget manager.
- **Voilà**: turn a widget notebook into a deployed dashboard without exposing code — a lightweight alternative to Dash/Streamlit for notebook-native apps.
- **Plotly/Bokeh**: their `FigureWidget`/`push_notebook` integrate with ipywidgets events for linked interactivity.
- **anywidget**: modern framework for shipping custom widgets as a single Python+JS file.

## Best For / Avoid For
`notebook-interactivity`, `parameter-exploration`, `data-app-prototyping`, `teaching`, `voila-dashboards`, `jupyter-native` — choose ipywidgets when the audience lives in Jupyter and you want live controls bound to kernel state with minimal code.

Avoid for: standalone production web apps served to the public (use Dash/Streamlit), non-notebook environments, or when you need custom, framework-grade UI (build a real web front end).

## See Also
- `streamlit.md` / `dash.md` — standalone Python web-app frameworks (deploy outside Jupyter)
- `vtk_js.md` — scientific 3D that pairs with notebook widgets (itkwidgets/pythreejs)
- `sympy.md` / `sagemath.md` — math backends whose `@interact`-style exploration ipywidgets powers
- `../use-case/interactive-notebooks.md`, `../use-case/data-dashboards.md`
