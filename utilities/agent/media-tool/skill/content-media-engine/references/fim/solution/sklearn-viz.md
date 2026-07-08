# scikit-learn visualization — ML model diagnostics on matplotlib

scikit-learn ships a family of visualization utilities for evaluating and inspecting machine-learning models: confusion matrices, ROC/PR curves, calibration, decision boundaries, partial dependence, learning/validation curves, and dendrograms. They are thin `Display` classes that draw onto matplotlib Axes, so everything composes with normal matplotlib layout, styling, and export. This is not a general charting library — it is purpose-built for model diagnostics.

**Current Version**: scikit-learn 1.5.x (current major)  **License**: BSD-3-Clause  **Runtime**: Python 3.9+; renders via matplotlib

## Official Resources & Documentation
- Visualizations guide: https://scikit-learn.org/stable/visualizations.html
- Inspection: https://scikit-learn.org/stable/inspection.html
- Metrics API: https://scikit-learn.org/stable/modules/classes.html#module-sklearn.metrics
- GitHub: https://github.com/scikit-learn/scikit-learn

## Installation & Setup
```bash
pip install scikit-learn matplotlib
pip install pandas numpy        # recommended
```
```python
import matplotlib.pyplot as plt
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
X, y = load_iris(return_X_y=True)
Xtr, Xte, ytr, yte = train_test_split(X, y, test_size=0.3, random_state=0, stratify=y)
clf = RandomForestClassifier(random_state=0).fit(Xtr, ytr)
```

## Core API — the `Display` pattern
Every plotting utility is a `*Display` class with two constructors and a `.plot()`:
- `Display.from_estimator(estimator, X, y, ...)` — compute from a fitted model + data.
- `Display.from_predictions(y_true, y_pred_or_score, ...)` — compute from precomputed predictions.
- `.plot(ax=..., name=..., **style)` — draw (and re-draw for overlays). Returns the display, exposing artists (`disp.ax_`, `disp.figure_`, `disp.line_`).
```python
from sklearn.metrics import ConfusionMatrixDisplay
disp = ConfusionMatrixDisplay.from_estimator(clf, Xte, yte, cmap="Blues", normalize="true")
disp.ax_.set_title("Confusion matrix")
plt.show()
```

## Display classes (the "chart types")
- **Classification metrics** (`sklearn.metrics`): `ConfusionMatrixDisplay`, `RocCurveDisplay`, `PrecisionRecallDisplay`, `DetCurveDisplay`, `PredictionErrorDisplay` (regression), `CalibrationDisplay` (in `sklearn.calibration`).
- **Model inspection** (`sklearn.inspection`): `DecisionBoundaryDisplay`, `PartialDependenceDisplay`.
- **Manual plots** (no Display, plain matplotlib): feature importances, PCA/t-SNE/UMAP scatter, learning/validation curves, tree structure (`plot_tree`), dendrograms.

## How-To

### How to set colors / palette / theme
These are matplotlib plots, so color control flows through matplotlib. `Display`s expose `cmap` (matrices/boundaries) and pass line style kwargs; use matplotlib for the rest.
```python
# 1) Colormap on matrix/boundary displays
ConfusionMatrixDisplay.from_estimator(clf, Xte, yte, cmap="viridis")
DecisionBoundaryDisplay.from_estimator(clf, X[:, :2], cmap="RdBu", alpha=0.4)

# 2) Line color/label for curve displays (kwargs forwarded to plot)
RocCurveDisplay.from_estimator(clf, Xte, yte, name="RF", color="#4e79a7")

# 3) Color a scatter by class label
sc = plt.scatter(Xp[:,0], Xp[:,1], c=y, cmap="tab10", edgecolors="k")
plt.colorbar(sc, label="class")

# 4) Apply a global theme/palette to every plot
plt.style.use("seaborn-v0_8-darkgrid")
plt.rcParams["axes.prop_cycle"] = plt.cycler(color=["#4e79a7","#f28e2b","#e15759"])
```
Prefer perceptually-uniform colormaps (`viridis`, `Blues`) for matrices; qualitative (`tab10`) for class scatter.

### How to overlay multiple ROC curves on one Axes
```python
from sklearn.metrics import RocCurveDisplay
fig, ax = plt.subplots(figsize=(6,6))
for name, model in models.items():
    RocCurveDisplay.from_estimator(model, Xte, yte, ax=ax, name=name)
ax.plot([0,1],[0,1], "k--", alpha=0.5)      # chance line
ax.set_title("ROC comparison")
```
Pass the same `ax=` to each `.plot`/`from_estimator` to stack curves.

### How to plot feature importances
```python
import numpy as np
imp = clf.feature_importances_
order = np.argsort(imp)
fig, ax = plt.subplots()
ax.barh(np.array(load_iris().feature_names)[order], imp[order], color="#4e79a7")
ax.set_xlabel("Importance"); ax.set_title("Feature importance")
# more robust: permutation importance
from sklearn.inspection import permutation_importance
r = permutation_importance(clf, Xte, yte, n_repeats=10, random_state=0)
```

### How to visualize a decision boundary
```python
from sklearn.inspection import DecisionBoundaryDisplay
clf2 = RandomForestClassifier().fit(X[:, :2], y)     # 2 features for a 2D boundary
disp = DecisionBoundaryDisplay.from_estimator(clf2, X[:, :2], response_method="predict",
                                              alpha=0.4, cmap="Pastel1")
disp.ax_.scatter(X[:,0], X[:,1], c=y, edgecolor="k", cmap="tab10")
```

### How to plot partial dependence / learning curves
```python
from sklearn.inspection import PartialDependenceDisplay
PartialDependenceDisplay.from_estimator(clf, Xtr, features=[0, 1, (0, 1)])

from sklearn.model_selection import LearningCurveDisplay
LearningCurveDisplay.from_estimator(clf, X, y, cv=5, scoring="accuracy")
```

### How to export
```python
plt.savefig("diagnostics.png", dpi=300, bbox_inches="tight")   # standard matplotlib savefig
```

## Do's and Don'ts

### ✅ Do
- Use `from_estimator` when you have a fitted model + data; `from_predictions` when you already computed scores (e.g., cross-val out-of-fold predictions).
- Reuse a single `ax=` to overlay curves for model comparison.
- Normalize confusion matrices (`normalize="true"`) when classes are imbalanced.
- Compute ROC/PR on a held-out or cross-validated set, never on training data.

### ❌ Don't
- Don't use the removed `plot_confusion_matrix` / `plot_roc_curve` functions — they were deprecated and removed; use the `*Display` classes.
- Don't plot decision boundaries with >2 input features — reduce to 2 (or use PCA) first.
- Don't read too much into ROC on heavily imbalanced data — prefer `PrecisionRecallDisplay`.
- Don't call `t-SNE`/`UMAP` on raw high-cardinality data without scaling — standardize first.

## Styling, Theming & Customization
- All styling is matplotlib: `plt.style.use`, `rcParams`, `ax.set_*`, `fig.savefig`.
- Display artists are exposed for tweaking: `disp.ax_`, `disp.figure_`, `disp.im_` (image), `disp.line_`, `disp.text_` (matrix cell labels).
- `cmap`, `alpha`, `colorbar`, `values_format` (confusion matrix cell format) are common kwargs.

## Advanced Features
- **`DecisionBoundaryDisplay`**: `response_method="predict"|"predict_proba"|"decision_function"`, grid resolution control.
- **`PartialDependenceDisplay`**: ICE curves (`kind="individual"|"both"`), 2-way interactions via feature tuples.
- **Calibration**: `CalibrationDisplay.from_estimator` for reliability diagrams.
- **`plot_tree` / `export_graphviz`**: render decision trees.
- **Dendrograms**: `scipy.cluster.hierarchy.dendrogram` paired with `AgglomerativeClustering`.
- **Dimensionality reduction**: `PCA`, `TSNE`, `Isomap`, `MDS` → 2D scatter for cluster/class structure.

### How to visualize a decision tree
```python
from sklearn.tree import DecisionTreeClassifier, plot_tree
tree = DecisionTreeClassifier(max_depth=3).fit(Xtr, ytr)
fig, ax = plt.subplots(figsize=(14, 8))
plot_tree(tree, feature_names=load_iris().feature_names,
          class_names=load_iris().target_names, filled=True, rounded=True, ax=ax)
```

### How to plot PCA / t-SNE embeddings
```python
from sklearn.decomposition import PCA
from sklearn.manifold import TSNE
Xp = PCA(n_components=2).fit_transform(X)
plt.scatter(Xp[:,0], Xp[:,1], c=y, cmap="tab10", edgecolors="k")
Xt = TSNE(n_components=2, perplexity=30, init="pca").fit_transform(X)
plt.scatter(Xt[:,0], Xt[:,1], c=y, cmap="tab10")
```

## Integration Notes
- **matplotlib**: everything draws onto Axes — combine displays in `plt.subplots(1, 3)` for a diagnostics panel and `savefig` once.
- **Jupyter**: displays render inline; ideal for iterative model evaluation.
- **pandas**: `permutation_importance` results and `feature_importances_` pair naturally with a DataFrame + `barh` for labeled importance charts.
- **cross-validation**: use `from_predictions` with out-of-fold predictions (`cross_val_predict`) to avoid optimistic in-sample curves.

## Common Pitfalls & Troubleshooting
- `ImportError: cannot import name 'plot_roc_curve'` → use `RocCurveDisplay.from_estimator`.
- ROC needs scores → binary/probabilistic output; set `probability=True` on SVC or use `decision_function`.
- Decision boundary errors → model trained on >2 features; slice or reduce dimensionality.
- Overlays not stacking → forgot to pass the same `ax=`.
- Multiclass ROC → compute per-class (one-vs-rest) or use `from_predictions` with binarized labels.

## Best For / Avoid For
`model-evaluation`, `classifier-diagnostics`, `feature-importance`, `decision-boundaries`, `partial-dependence`, `learning-curves`, `dimensionality-reduction-viz` — choose sklearn viz.
Avoid for: `general-charting` (matplotlib/seaborn/plotly), `interactive-dashboards`, `deep-learning-specific-viz` (TensorBoard), `production-BI`.

## See Also
- `matplotlib.md` — the rendering layer and full styling control
- `seaborn.md` — statistical EDA plots that pair well with model diagnostics
- `plotly-python.md` — interactive alternative for sharing results
- `../use-case/data-visualization.md`
