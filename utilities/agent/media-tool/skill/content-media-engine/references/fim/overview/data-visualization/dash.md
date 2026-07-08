# Dash

## What
Dash is a Python framework for building reactive web applications and dashboards with a React.js frontend. It composes layouts from `dcc` (graphs, dropdowns, sliders) and `html` components, wired together by callbacks.

## How
- The LLM emits Python: an `app = dash.Dash(__name__)`, an `app.layout` tree of components, and `@app.callback(Output, Input)` functions that return updated figures (typically Plotly).
- Rendered by `pip install dash` (plus `pandas`, optionally `dash-bootstrap-components`); run `app.run_server(debug=True)` to serve the app. Client-side callbacks are available for performance.
- Final artifact: a served interactive web dashboard.

## Why
- Reach for Dash for production-ready dashboards with complex interactions and multi-output callbacks, where you want a React frontend without writing JavaScript.
- Tradeoffs: it is a full web-app framework (requires running a server, not static hosting) and centers on Plotly figures for charting.
- Versus Streamlit it favors explicit callback wiring and production control over rapid scripting; versus Panel it is Plotly/React-centric rather than multi-backend.

## Source
- Solution reference: `fim/solution/dash.md`
