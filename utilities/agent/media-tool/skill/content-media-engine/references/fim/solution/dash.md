# Plotly Dash — reactive analytical web apps in pure Python

Dash is a Python framework for building interactive web applications and dashboards without writing JavaScript. It renders a React/Plotly.js front end from a declarative Python `layout` (a tree of components) and wires interactivity through **callbacks**: functions decorated with `@callback` whose `Output`s recompute whenever their `Input`s change. It's the production-grade choice for data apps that need custom layouts, multi-page routing, and server-side control. For npl-fim, Dash output is authored as a single `app.py` that defines `app.layout` and one or more callbacks, run with `python app.py`.

**Current Version**: Dash 2.17+ / 3.x (current major)  **License**: MIT  **Runtime**: Flask server + React/Plotly.js client; served on a local port (default 8050)

## Official Resources & Documentation
- Docs: https://dash.plotly.com/
- Component reference (Dash Core Components): https://dash.plotly.com/dash-core-components
- Callbacks: https://dash.plotly.com/basic-callbacks
- GitHub: https://github.com/plotly/dash
- Dash Bootstrap Components: https://dash-bootstrap-components.opensource.faculty.ai/

## Installation & Setup

### pip
```bash
pip install dash                      # includes plotly, dcc, html, dash-table
pip install pandas                    # near-always needed for data
pip install dash-bootstrap-components  # themed layouts
pip install dash-mantine-components    # alternative modern component set
```

### Minimal app
```python
from dash import Dash, dcc, html, Input, Output, callback

app = Dash(__name__)

app.layout = html.Div([
    html.H1('Hello Dash'),
    dcc.Input(id='name', value='world', type='text'),
    html.Div(id='greeting'),
])

@callback(Output('greeting', 'children'), Input('name', 'value'))
def greet(name):
    return f'Hello, {name}!'

if __name__ == '__main__':
    app.run(debug=True)          # Dash 2.x+; app.run_server is the deprecated alias
```

## Core Syntax / API Reference

### App object
```python
from dash import Dash
app = Dash(__name__,
           title='My Dashboard',
           suppress_callback_exceptions=True,   # needed for dynamically-created components
           external_stylesheets=[...])
server = app.server                              # the Flask server, for gunicorn/WSGI deploy
```

### Layout = a tree of components
`app.layout` is a single component (usually `html.Div`) whose `children` nest arbitrarily. Two component families:
```python
from dash import dcc, html
# html.* mirrors HTML tags; props are camelCase versions of HTML attrs + style dict
html.Div(children=[...], style={'padding': 10}, className='row')
html.H1('Title'); html.P('text'); html.Button('Click', id='btn', n_clicks=0)
html.A('link', href='/page-2'); html.Img(src='/assets/logo.png')

# dcc.* = Dash Core Components (rich interactive widgets)
dcc.Graph(id='g', figure=fig)         # a Plotly figure
dcc.Dropdown(id='dd', options=[{'label': 'A', 'value': 'a'}], value='a', multi=False)
dcc.Slider(id='s', min=0, max=10, step=1, value=5, marks={i: str(i) for i in range(11)})
dcc.RangeSlider(id='rs', min=0, max=100, value=[20, 80])
dcc.Input(id='in', type='number', debounce=True)
dcc.Checklist(options=['x', 'y'], value=['x'])
dcc.RadioItems(options=['a', 'b'], value='a')
dcc.DatePickerRange(id='dates')
dcc.Tabs([dcc.Tab(label='One', children=[...]), dcc.Tab(label='Two', children=[...])])
dcc.Markdown('**bold** and $math$', mathjax=True)
dcc.Upload(id='up', children=html.Button('Upload'))
dcc.Store(id='cache', storage_type='session')   # client-side data store
dcc.Interval(id='tick', interval=1000)           # periodic callback trigger
dcc.Loading(children=dcc.Graph(id='g2')) 
```

### Callbacks (the reactive core)
```python
from dash import callback, Input, Output, State

@callback(
    Output('graph', 'figure'),          # what to update: (component-id, property)
    Input('dropdown', 'value'),         # triggers: any change re-runs the function
    Input('slider', 'value'),
    State('textbox', 'value'),          # read-only: value used but does NOT trigger
)
def update(category, threshold, note):
    ...
    return figure                        # returned values map positionally to Outputs
```
Rules: every `Output` must be produced by exactly one callback; a callback fires when any `Input` changes; `State` is read without triggering. Return `dash.no_update` to skip updating a given Output.

### Multiple outputs & pattern-matching
```python
@callback(
    Output('g1', 'figure'), Output('g2', 'figure'),
    Input('dd', 'value'),
)
def two(v):
    return fig_a(v), fig_b(v)

# Which input fired? -> callback_context
from dash import ctx
@callback(Output('out', 'children'), Input('b1', 'n_clicks'), Input('b2', 'n_clicks'))
def which(n1, n2):
    return f'clicked {ctx.triggered_id}'

# Pattern-matching IDs for dynamic components:
from dash import MATCH, ALL
Output({'type': 'card', 'index': MATCH}, 'children')
Input({'type': 'card', 'index': ALL}, 'value')
```

### Building figures
```python
import plotly.express as px
fig = px.scatter(df, x='gdp', y='life_exp', color='continent',
                 size='pop', hover_name='country', title='Gapminder')
# or the graph-objects API for fine control:
import plotly.graph_objects as go
fig = go.Figure(go.Bar(x=['a','b'], y=[3, 5]))
fig.update_layout(template='plotly_dark', margin=dict(l=40, r=20, t=40, b=40))
```

## App Types / Patterns (Supported)
Single-page dashboards, **multi-page apps** (`use_pages=True` + `pages/` dir), tabbed interfaces, form-driven tools, live-updating monitors (`dcc.Interval`), file-upload analyzers, cross-filtered linked charts, and full apps with auth (via `dash-auth`/reverse proxy). Component ecosystems: Dash Core Components, Dash HTML Components, `dash-table`/DataTable, Dash Bootstrap Components, Dash Mantine Components, `dash-leaflet` (maps), `dash-cytoscape` (graphs), `dash-bio`.

## How-To

### How to theme & style a Dash app (colors, layout, dark mode)
```python
import dash_bootstrap_components as dbc
from dash import Dash, dcc, html

app = Dash(__name__, external_stylesheets=[dbc.themes.DARKLY])   # pick a Bootswatch theme

app.layout = dbc.Container([
    dbc.Row(dbc.Col(html.H2('Sales', className='text-primary my-3'))),
    dbc.Row([
        dbc.Col(dcc.Dropdown(id='region', options=['NA','EU','APAC'], value='NA'), width=4),
        dbc.Col(dcc.Graph(id='chart'), width=8),
    ]),
], fluid=True)
```
Three theming layers: (1) Bootstrap/Mantine themes via `external_stylesheets`; (2) per-component `style={...}` dicts (CSS keys are camelCase: `backgroundColor`, `marginTop`); (3) a CSS file in an `assets/` folder (auto-loaded). Chart colors come from the Plotly figure `template` (`'plotly_dark'`, `'ggplot2'`, `'seaborn'`).

### How to link a control to a chart (the fundamental callback)
```python
import plotly.express as px, pandas as pd
from dash import Dash, dcc, html, Input, Output, callback

df = px.data.gapminder()
app = Dash(__name__)
app.layout = html.Div([
    dcc.Dropdown(id='year', options=sorted(df.year.unique()), value=2007),
    dcc.Graph(id='bubble'),
])

@callback(Output('bubble', 'figure'), Input('year', 'value'))
def draw(year):
    d = df[df.year == year]
    return px.scatter(d, x='gdpPercap', y='lifeExp', size='pop',
                      color='continent', log_x=True, height=500)

if __name__ == '__main__':
    app.run(debug=True)
```

### How to build a multi-page app
```python
# app.py
from dash import Dash, html, dcc, page_container
app = Dash(__name__, use_pages=True)     # auto-discovers ./pages/*.py
app.layout = html.Div([
    dcc.Link('Home', href='/'), ' | ', dcc.Link('Reports', href='/reports'),
    page_container,                       # active page renders here
])
if __name__ == '__main__':
    app.run(debug=True)

# pages/home.py
import dash
from dash import html
dash.register_page(__name__, path='/')
layout = html.H1('Home')
```
`use_pages=True` + a `pages/` folder with `dash.register_page(...)` gives routing, URLs, and nav without manual `dcc.Location` plumbing.

### How to speed up interactivity with a clientside callback
```python
from dash import clientside_callback, Output, Input
clientside_callback(
    """
    function(value) { return 'Live: ' + value; }
    """,
    Output('live', 'children'),
    Input('slider', 'value'),
)
```
Clientside callbacks run in the browser (no server round-trip) — use for trivial UI glue (formatting, toggling visibility) to cut latency.

### How to store per-session data and share it between callbacks
```python
from dash import dcc, Output, Input, State, callback
# dcc.Store holds JSON-serializable data in the browser:
# layout: dcc.Store(id='data', storage_type='session')
@callback(Output('data', 'data'), Input('load', 'n_clicks'), State('file', 'value'))
def load(n, path):
    if not n: from dash import no_update; return no_update
    return pd.read_csv(path).to_dict('records')   # store as JSON

@callback(Output('table', 'children'), Input('data', 'data'))
def show(records):
    return f'{len(records or [])} rows'
```
`dcc.Store` (`storage_type='memory'|'session'|'local'`) avoids recomputing shared state and keeps callbacks stateless.

## Do's and Don'ts

### ✅ Do
- Give every interactive component a unique `id`; callbacks address components by `(id, property)`.
- Keep callbacks **pure** functions of their inputs — Dash may run them on any worker; don't rely on globals for per-user state (use `dcc.Store`).
- Use `State` for values you need but shouldn't trigger on (e.g. a text box read only when a button is clicked).
- Return `dash.no_update` to leave an Output unchanged instead of recomputing.
- Expose `server = app.server` and deploy with gunicorn (`gunicorn app:server`) in production.
- Use `debounce=True` on text/number `Input`s to avoid a callback per keystroke.

### ❌ Don't
- Don't assign the same `Output` to two callbacks — Dash raises a duplicate-output error (use `allow_duplicate=True` + a triggering input only when intentional).
- Don't mutate a global DataFrame inside a callback and expect isolation — every browser shares the process; use `dcc.Store` for user state.
- Don't run with `debug=True` in production — it exposes the reloader/dev tools.
- Don't reference component IDs that don't exist at load time without `suppress_callback_exceptions=True`.
- Don't do heavy compute in a keystroke-triggered callback — debounce or move to a button.
- Don't confuse `app.run` (current) with the deprecated `app.run_server` — prefer `app.run`.

## Styling, Theming & Customization
- **Stylesheets**: `external_stylesheets=[dbc.themes.FLATLY]` (Bootstrap/Bootswatch) or Mantine; or drop custom `.css` into an `assets/` folder (auto-served, no config).
- **Inline styles**: every component takes `style={...}` with camelCase CSS keys and `className='...'` for stylesheet classes.
- **Layout systems**: `dbc.Container/Row/Col` (12-col grid), `dbc.Card`, or `dash-mantine-components` `Grid/Stack/Group`.
- **Figure theming**: `fig.update_layout(template='plotly_dark')` (built-ins: `plotly`, `plotly_white`, `plotly_dark`, `ggplot2`, `seaborn`, `simple_white`); set colors via `color_discrete_sequence`/`color_continuous_scale` in Plotly Express.
- **Dark mode**: pick a dark Bootstrap theme + a dark figure template together for consistency.
- **Assets**: images, fonts, favicon, and JS also live in `assets/` and load automatically.

## Advanced Features
- **Pattern-matching callbacks** (`MATCH`/`ALL`/`ALLSMALLER`) for dynamically generated component sets.
- **`dcc.Interval`** for polling/live dashboards; **`dcc.Loading`** for spinners around slow Outputs.
- **Long-callbacks / background callbacks** (`@callback(..., background=True)` with a Celery/DiskCache manager) for multi-minute jobs with progress.
- **DataTable** (`dash_table.DataTable`) — sortable/filterable/editable grids with conditional formatting.
- **`ctx` (callback_context)** to branch on which input fired (`ctx.triggered_id`).
- **Auth & deploy**: `dash-auth` basic auth, or reverse-proxy behind OAuth; scale with gunicorn workers + Redis-backed stores.
- **Testing**: `dash.testing` with Selenium for end-to-end callback tests.

## Common Pitfalls & Troubleshooting
- **"Duplicate callback outputs"**: two callbacks target the same Output — merge them or use `allow_duplicate=True`.
- **"A nonexistent object was used in an Input"**: the component ID isn't in the initial layout — add it or set `suppress_callback_exceptions=True`.
- **State leaks between users**: you used a module-global instead of `dcc.Store`/per-callback data.
- **Callback fires on load**: Dash runs callbacks once at startup; guard with `if not n_clicks: return no_update` or `prevent_initial_call=True`.
- **Slow app**: too many server round-trips — move trivial logic to clientside callbacks, debounce inputs, and cache with `flask_caching`/`dcc.Store`.
- **Assets not loading**: files must be in a folder literally named `assets/` next to `app.py`.
- **Figure not updating**: the callback must *return* a new `figure`; mutating in place won't propagate.

## Integration Notes
- **Deployment**: `gunicorn app:server -w 4`; behind Nginx; Docker-friendly. Plotly's Dash Enterprise or any WSGI host works.
- **Pandas/NumPy**: the native data layer; `plotly.express` consumes DataFrames directly.
- **Jupyter**: `JupyterDash`/`app.run(jupyter_mode='inline')` embeds a Dash app in a notebook cell.
- **vs Streamlit**: Dash gives finer layout/callback control and scales to complex multi-page apps; Streamlit is faster for quick linear scripts (see `streamlit.md`).

## Best For / Avoid For
`production-dashboards`, `multi-page-apps`, `custom-layouts`, `linked-charts`, `enterprise`, `plotly-native` — choose Dash when you need a real, deployable web app with precise layout, routing, and callback control in Python.

Avoid for: throwaway one-file exploration (Streamlit is faster), notebook-embedded controls (ipywidgets/Voilà), or static charts with no interactivity (plain Plotly export).

## See Also
- `streamlit.md` — simpler script-first Python app framework
- `plotly_js.md` / `plotly-python.md` — the charting layer Dash renders
- `ipywidgets.md` — notebook-native interactivity alternative
- `../use-case/data-dashboards.md`, `../use-case/interactive-apps.md`
