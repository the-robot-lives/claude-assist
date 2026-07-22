# ipywidgets

## What
ipywidgets provides interactive widgets for Jupyter notebooks — sliders, dropdowns, text inputs, color/date pickers, and layout containers — with bidirectional Python↔JavaScript communication. Its primary consumer is the Jupyter/JupyterLab runtime.

## How
- The LLM emits Python: widget constructors (`widgets.IntSlider(...)`, `widgets.Dropdown(...)`), `display()` calls, the `@widgets.interact` decorator for auto-generated controls, `.observe()` callbacks, and layout containers (`HBox`, `VBox`, `Tab`, `Accordion`).
- Rendered by executing notebook cells after `pip install ipywidgets` and enabling the extension (`jupyter nbextension enable --py widgetsnbextension`, or the JupyterLab manager labextension).
- Final artifact: interactive widget output rendered inline in notebook cells.

## Why
- Reach for ipywidgets to add native interactivity to Jupyter — live-updating plots, parameter controls, linked widgets, and custom DOMWidgets — with two-way Python/JavaScript data binding.
- Tradeoffs (per source): tied to the Jupyter environment; custom widgets require syncing traits between Python and JavaScript.
- It is the Jupyter-ecosystem analogue to the Kino widgets in this category (which serve Elixir LiveBook); reach for it when the notebook runtime is Python/Jupyter.

## Source
- Solution reference: `fim/solution/ipywidgets.md`
