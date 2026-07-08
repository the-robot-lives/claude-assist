# Streamlit

## What
Streamlit is a Python framework for quickly building and sharing data apps. A plain top-to-bottom script becomes an interactive web app with widgets, automatic reactivity, and built-in chart/data display.

## How
- The LLM emits a Python script using the `st` API: `st.title`, input widgets (`st.slider`, `st.selectbox`, `st.file_uploader`), display (`st.dataframe`, `st.line_chart`), layout (`st.columns`, `st.sidebar`), plus `st.session_state` and `@st.cache_data`.
- Rendered by `pip install streamlit` and running `streamlit run app.py`. It embeds charts from matplotlib (`st.pyplot`), Plotly (`st.plotly_chart`), Bokeh (`st.bokeh_chart`), and Altair (`st.altair_chart`).
- Final artifact: a served, reactive web data app.

## Why
- Reach for Streamlit for rapid prototyping of data apps where you want automatic reactivity and simple deployment without wiring callbacks.
- Tradeoffs: it re-runs the script on interaction (managed via caching/session state) and is a served app, not static hosting; less explicit control than a callback-based framework.
- Versus Dash it favors speed and minimal boilerplate over fine-grained callback control; versus Panel it is script-first rather than multi-backend component composition.

## Source
- Solution reference: `fim/solution/streamlit.md`
