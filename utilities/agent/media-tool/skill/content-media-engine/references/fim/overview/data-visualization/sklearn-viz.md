# scikit-learn Visualization

## What
scikit-learn's visualization utilities are ML-specific plotting helpers for model evaluation and diagnostics, built on matplotlib. They cover confusion matrices, ROC/precision-recall curves, decision boundaries, partial dependence, feature importance, learning/validation curves, and dimensionality-reduction scatter (PCA, t-SNE).

## How
- The LLM emits Python using sklearn Display classes (`ConfusionMatrixDisplay.from_estimator`, `RocCurveDisplay.from_estimator`, `DecisionBoundaryDisplay`, `PartialDependenceDisplay`) plus `sklearn.inspection`/`model_selection` helpers, finished with `plt.show()`.
- Rendered by `pip install scikit-learn matplotlib` (numpy/pandas recommended); output goes through matplotlib's show/savefig.
- Final artifact: matplotlib figures (static images) of model diagnostics.

## Why
- Reach for sklearn-viz when the goal is evaluating and inspecting ML models — not general charting — because the helpers take an estimator directly and produce the standard diagnostic plots.
- Tradeoffs: scope is limited to ML diagnostics, some older `plot_*` functions are deprecated in favor of Display classes, and styling inherits matplotlib.
- It complements rather than competes with general libraries: pair it with matplotlib/seaborn for the surrounding EDA and reporting.

## Source
- Solution reference: `fim/solution/sklearn-viz.md`
