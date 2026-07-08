# Streamlit — the fastest way to build data apps in Python

Streamlit turns a plain top-to-bottom Python script into an interactive web app. There is no callback graph and no layout tree to declare up front: you call `st.*` functions in sequence, Streamlit renders each element where it appears, and on **every interaction it re-runs the whole script** from the top, using cached data and `st.session_state` to preserve state. It's the fastest path from a `.py` file to a shareable dashboard. For npl-fim, Streamlit output is authored as a single `app.py` run with `streamlit run app.py`.

**Current Version**: Streamlit 1.4x+ (current major, 1.x)  **License**: Apache-2.0  **Runtime**: Tornado server + a React front end; served on port 8501; re-runs the script per interaction

## Official Resources & Documentation
- Docs: https://docs.streamlit.io/
- API reference: https://docs.streamlit.io/develop/api-reference
- GitHub: https://github.com/streamlit/streamlit
- Community components: https://streamlit.io/components
- Deploy (Community Cloud): https://share.streamlit.io/

## Installation & Setup

### pip
```bash
pip install streamlit
pip install pandas numpy matplotlib plotly altair   # common companions
streamlit hello                    # demo app to verify install
```

### Minimal app
```python
# app.py
import streamlit as st

st.title('My Data App')
name = st.text_input('Your name', 'world')
st.write(f'Hello, {name}!')
```
```bash
streamlit run app.py               # opens http://localhost:8501
```

## Core Syntax / API Reference

### The mental model
- The script runs **top to bottom** on first load and again on **every widget interaction**.
- Widgets *return their current value* inline — `value = st.slider(...)` — no callbacks required.
- Persist across re-runs with `st.session_state`; avoid recomputation with `@st.cache_data` / `@st.cache_resource`.

### Text & display
```python
st.title('T'); st.header('H'); st.subheader('sub')
st.write(anything)                 # magic: DataFrames, figures, dicts, markdown, str
st.markdown('**bold** :red[colored] $E=mc^2$')   # markdown + colored text + LaTeX
st.text('monospace'); st.caption('small'); st.code('print(1)', language='python')
st.latex(r'\int_0^1 x^2\,dx')
st.divider()
# Magic: a bare variable/expression on its own line is auto-rendered (like st.write)
df   # renders the DataFrame
```

### Input widgets (each returns its value)
```python
st.button('Click')                 # -> bool (True only on the run triggered by the click)
st.checkbox('Enable')              # -> bool
st.toggle('On')                    # -> bool
st.radio('Pick', ['a', 'b', 'c'])  # -> selected value
st.selectbox('Choose', ['x','y'])  # -> selected value
st.multiselect('Tags', ['p','q'])  # -> list
st.slider('N', 0, 100, 50)         # -> int/float; range slider if value=(lo,hi)
st.select_slider('Size', ['S','M','L'])
st.text_input('Name'); st.text_area('Notes')
st.number_input('Qty', min_value=0, max_value=10, value=1)
st.date_input('Day'); st.time_input('Time')
st.color_picker('Color', '#1f77b4')
st.file_uploader('CSV', type=['csv'], accept_multiple_files=False)
st.camera_input('Photo'); st.download_button('Save', data=csv_bytes, file_name='out.csv')
```

### Data & media display
```python
st.dataframe(df, use_container_width=True)      # interactive: sort/scroll/resize
st.data_editor(df, num_rows='dynamic')          # EDITABLE grid, returns edited df
st.table(df)                                     # static table
st.metric('Revenue', '$1.2M', delta='+8%')
st.json({'a': 1}); st.image(img); st.audio(wav); st.video(mp4)
```

### Built-in & library charts
```python
st.line_chart(df); st.area_chart(df); st.bar_chart(df); st.scatter_chart(df)
st.map(df_with_lat_lon)                          # quick geographic scatter
st.pyplot(matplotlib_fig)                        # Matplotlib
st.plotly_chart(fig, use_container_width=True)   # Plotly
st.altair_chart(chart, use_container_width=True) # Altair/Vega-Lite
st.pydeck_chart(deck); st.graphviz_chart(dot); st.bokeh_chart(p)
```

### Layout
```python
col1, col2, col3 = st.columns(3)
with col1:
    st.metric('A', 1)
col2.metric('B', 2)                              # or attribute-style

with st.sidebar:                                 # left sidebar
    region = st.selectbox('Region', ['NA', 'EU'])
st.sidebar.slider('Zoom', 1, 10)                 # shorthand

with st.expander('Details'):
    st.write('hidden until expanded')
tab1, tab2 = st.tabs(['Chart', 'Data'])
with st.container():
    st.write('grouped block')
placeholder = st.empty()                         # a slot you can overwrite later
```

### session_state, forms & fragments
```python
# Persist values across re-runs:
if 'count' not in st.session_state:
    st.session_state.count = 0
if st.button('Increment'):
    st.session_state.count += 1
st.write(st.session_state.count)

# Forms batch inputs and re-run only on submit (avoids per-widget re-runs):
with st.form('entry'):
    x = st.number_input('x'); y = st.number_input('y')
    submitted = st.form_submit_button('Compute')
if submitted:
    st.write(x + y)

# Fragments re-run only themselves, not the whole script (1.33+):
@st.fragment
def live_clock():
    st.write(pd.Timestamp.now())
```

### Caching
```python
@st.cache_data                     # for DATA (DataFrames, arrays): cached by args, returns a copy
def load(path):
    return pd.read_csv(path)

@st.cache_resource                 # for RESOURCES (db connections, ML models): one shared instance
def get_model():
    return load_model('model.pkl')
```

## App Patterns (Supported)
Linear dashboards, sidebar-filtered reports, multi-page apps (a `pages/` folder auto-creates nav), form-driven tools, file-upload analyzers, live-updating displays (`st.empty` / `@st.fragment` / auto-rerun), chat apps (`st.chat_message` / `st.chat_input`), and ML demos (`st.file_uploader` → model → `st.write`). Chart backends: native (Vega-Lite under the hood), Matplotlib, Plotly, Altair, Bokeh, PyDeck, Graphviz.

## How-To

### How to theme & style a Streamlit app (colors, dark mode, layout)
```toml
# .streamlit/config.toml  — sets the app-wide theme
[theme]
base = "dark"                 # or "light"
primaryColor = "#1f77b4"      # accent for widgets/links
backgroundColor = "#0e1117"
secondaryBackgroundColor = "#262730"
textColor = "#fafafa"
font = "sans serif"
```
```python
st.set_page_config(page_title='Sales', page_icon='📊',
                   layout='wide', initial_sidebar_state='expanded')
st.markdown(':blue[**Colored**] and :red[warning] text.')     # inline colored markdown
# Escape hatch for arbitrary CSS:
st.markdown("<style>.stButton>button{border-radius:12px}</style>", unsafe_allow_html=True)
```
Theming layers: (1) `.streamlit/config.toml [theme]` for app-wide colors/font/dark-mode; (2) `st.set_page_config(layout='wide')` for the page frame; (3) inline `:color[...]` markdown; (4) raw CSS via `st.markdown(..., unsafe_allow_html=True)` as a last resort. Chart colors come from the underlying library (Plotly template, Altair scheme).

### How to build a sidebar-filtered dashboard
```python
import streamlit as st, plotly.express as px
df = px.data.gapminder()

st.set_page_config(layout='wide')
with st.sidebar:
    year = st.select_slider('Year', sorted(df.year.unique()), value=2007)
    conts = st.multiselect('Continents', df.continent.unique(), default=list(df.continent.unique()))

d = df[(df.year == year) & (df.continent.isin(conts))]
c1, c2 = st.columns([2, 1])
c1.plotly_chart(px.scatter(d, x='gdpPercap', y='lifeExp', size='pop',
                           color='continent', log_x=True), use_container_width=True)
c2.metric('Countries', len(d))
c2.dataframe(d[['country', 'lifeExp']], use_container_width=True)
```

### How to cache an expensive load so the app stays snappy
```python
@st.cache_data(ttl=3600, show_spinner='Loading…')
def load_data(url):
    return pd.read_csv(url)          # runs once; cached result reused across re-runs & users

df = load_data('https://example.com/big.csv')
```
Because the whole script re-runs per interaction, uncached I/O repeats every time — always wrap loads in `@st.cache_data` (and shared clients/models in `@st.cache_resource`).

### How to keep widget state and avoid losing it on re-run
```python
st.session_state.setdefault('history', [])
entry = st.text_input('Add note')
if st.button('Save') and entry:
    st.session_state.history.append(entry)
st.write(st.session_state.history)

# Bind a widget to session_state via key= (its value persists under that key):
st.slider('Threshold', 0, 100, key='thr')
st.write(st.session_state.thr)
```

### How to make a multi-page app
```
project/
├── Home.py                 # entrypoint: `streamlit run Home.py`
└── pages/
    ├── 1_Reports.py        # numeric prefix orders the auto nav
    └── 2_Settings.py
```
Each file is a page; Streamlit builds the sidebar navigation automatically. For programmatic control use `st.navigation([st.Page(...), ...])` + `st.switch_page`.

## Do's and Don'ts

### ✅ Do
- Remember the script re-runs top-to-bottom on every interaction — structure code so that's cheap.
- Wrap expensive loads in `@st.cache_data`; wrap connections/models in `@st.cache_resource`.
- Use `st.session_state` for anything that must survive a re-run (counters, accumulated input).
- Use `st.form` to batch several inputs and submit once, avoiding a re-run per keystroke.
- Pass `use_container_width=True` to charts/dataframes so they fill responsive columns.
- Read `st.button` as "True only on the click run" — don't treat it as persistent state.

### ❌ Don't
- Don't rely on a `st.button` value persisting — it's `True` only on the run its click triggered; store results in `session_state`.
- Don't do uncached network/disk/DB work at top level — it repeats on every interaction.
- Don't mutate widgets after creation or reuse the same `key` for two widgets — keys must be unique.
- Don't build tight `while True:` loops for live updates — use `@st.fragment`, `st.empty`, or `st.rerun()` deliberately.
- Don't overuse `unsafe_allow_html=True` — it's an escape hatch, not the primary styling path, and can break with updates.
- Don't expect `st.write(fig)`-style magic to give layout control — for side-by-side use `st.columns`.

## Styling, Theming & Customization
- **Global theme**: `.streamlit/config.toml [theme]` — `base` (`light`/`dark`), `primaryColor`, `backgroundColor`, `secondaryBackgroundColor`, `textColor`, `font`. Users can also toggle light/dark in the menu.
- **Page frame**: `st.set_page_config(layout='wide'|'centered', page_title=..., page_icon=..., initial_sidebar_state=...)` — must be the first Streamlit call.
- **Inline color**: markdown `:red[text]`, `:blue[**bold**]`, and emoji/`:material/icon:` shortcodes.
- **Custom CSS/HTML**: `st.markdown('<style>…</style>', unsafe_allow_html=True)` for one-off tweaks.
- **Chart colors**: set on the underlying figure — Plotly `template`/`color_discrete_sequence`, Altair `scale(scheme=…)`, Matplotlib styles.
- **Layout primitives**: `st.columns` (with width ratios), `st.tabs`, `st.expander`, `st.container`, `st.sidebar`, `st.empty`.

## Advanced Features
- **`@st.fragment`**: re-run only a portion of the app (independent widgets/timers) without recomputing everything — key for performance and live regions.
- **Chat**: `st.chat_message('user'|'assistant')` + `st.chat_input` build LLM chat UIs; `st.write_stream` renders token streams.
- **`st.data_editor`**: fully editable grid returning the mutated DataFrame; column config for types/validation.
- **Custom components**: `streamlit-components` (bidirectional React ↔ Python) and the rich third-party ecosystem (`streamlit-aggrid`, `streamlit-folium`, `streamlit-option-menu`).
- **`st.connection`**: managed connections to SQL/Snowflake/GCS with built-in caching.
- **`st.rerun()` / `st.stop()`**: force a re-run or halt the script early.
- **Secrets**: `st.secrets` reads `.streamlit/secrets.toml` for API keys.

## Common Pitfalls & Troubleshooting
- **State resets on interaction**: expected — the script re-runs. Persist in `st.session_state` and cache loads.
- **`set_page_config` error**: it must be the very first Streamlit command in the script.
- **Duplicate widget key error**: two widgets share a `key` (or identical params auto-generate the same id) — give explicit unique `key=`.
- **App is slow**: uncached I/O repeating per run — add `@st.cache_data`; use forms/fragments to limit re-runs.
- **Button "doesn't work"**: you checked its value on a later run; capture the result into `session_state` on the click run.
- **Chart too narrow**: pass `use_container_width=True`.
- **Live updates hammer the CPU**: replace polling loops with `@st.fragment(run_every=...)` or `st.empty` + controlled `st.rerun()`.

## Integration Notes
- **Deploy**: Streamlit Community Cloud (push a repo, one click), or `streamlit run` behind any container/reverse proxy; Hugging Face Spaces supports Streamlit apps.
- **Pandas/NumPy**: first-class; `st.dataframe`/`st.line_chart` consume DataFrames directly.
- **Plotly/Altair/Matplotlib/Bokeh/PyDeck**: all render via dedicated `st.*_chart` calls.
- **vs Dash**: Streamlit trades fine-grained layout/callback control for speed of authoring; choose Dash (see `dash.md`) for complex multi-page, tightly-controlled production apps.

## Best For / Avoid For
`rapid-prototyping`, `data-apps`, `ml-demos`, `internal-tools`, `dashboards`, `single-file`, `chat-uis` — choose Streamlit when you want a working, shareable data app from one linear script with minimal ceremony.

Avoid for: pixel-perfect custom layouts and complex routing (use Dash), notebook-embedded controls (ipywidgets/Voilà), or high-concurrency public apps needing fine caching/state control per user.

## See Also
- `dash.md` — callback-driven Python app framework with finer layout control
- `ipywidgets.md` — notebook-native interactivity (Voilà for notebook dashboards)
- `plotly_js.md` / `altair.md` / `matplotlib.md` — charting backends Streamlit renders
- `../use-case/data-dashboards.md`, `../use-case/interactive-apps.md`
