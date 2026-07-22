# Seaborn

## What
Seaborn is a Python statistical data-visualization library built on matplotlib. It provides high-level functions for relational, distribution, categorical, regression, and matrix plots with attractive defaults geared to exploratory data analysis.

## How
- The LLM emits Python: functions like `sns.scatterplot`, `sns.histplot(kde=True)`, `sns.boxplot`, `sns.heatmap`, and figure-level helpers (`sns.pairplot`, `sns.FacetGrid`), typically over a pandas DataFrame, finished with `plt.show()`.
- Rendered by `pip install seaborn pandas`; because it sits on matplotlib, plots display and export through the matplotlib machinery (`plt.show`, `savefig`). Themes set via `sns.set_theme()` / `sns.set_palette()`.
- Final artifact: matplotlib figures (static images).

## Why
- Reach for seaborn when you want statistical plots — distributions, correlations/heatmaps, regression, categorical comparisons — with minimal code and polished defaults for EDA.
- Tradeoffs: it inherits matplotlib's static nature and, for pixel-perfect or unusual layouts, you still drop down to matplotlib.
- It is the statistical-convenience layer over matplotlib: matplotlib gives low-level control, seaborn gives statistical shortcuts and nicer defaults on top.

## Source
- Solution reference: `fim/solution/seaborn.md`
