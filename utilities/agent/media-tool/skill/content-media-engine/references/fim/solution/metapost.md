# MetaPost — a graphics programming language with a linear equation solver

MetaPost is a declarative graphics programming language (a descendant of Knuth's METAFONT) that produces resolution-independent PostScript/PDF/SVG figures. Its defining feature is a built-in **linear equation solver**: you state geometric relationships (`z1 = z2 + (1cm, 0)`, `z3 = 0.5[z1,z2]`) and MetaPost solves for the unknown points, making constrained technical diagrams concise. It excels at precise mathematical figures, diagrams with typeset (TeX) labels, and font-quality curves via Hobby's spline algorithm. For npl-fim, MetaPost output is authored as a `.mp` source file compiled with `mpost` to numbered EPS figures (or SVG/PDF).

**Current Version**: MetaPost 2.x (current major, ships with TeX Live/MiKTeX)  **License**: LGPL  **Runtime**: the `mpost` interpreter; `-numbersystem` may be `scaled` (default), `double`, or `decimal`

## Official Resources & Documentation
- Manual (`mpman`): https://www.tug.org/docs/metapost/mpman.pdf
- Home: https://www.tug.org/metapost.html
- MetaPost previewer / examples: https://metapost.fauskes.net/  (MetaPost Previewer, examples)
- CTAN: https://ctan.org/pkg/metapost
- "Learning MetaPost by Doing" and André Heck's tutorial are common learning refs.

## Installation & Setup

### Comes with TeX distributions
```bash
# TeX Live / MacTeX
tlmgr install metapost
# Debian/Ubuntu
apt-get install texlive-metapost
```

### Compile
```bash
mpost figure.mp            # emits figure.1, figure.2, ... (one EPS per beginfig)
mpost -numbersystem=double figure.mp   # wider numeric range (avoids overflow)

# to SVG (per-figure):
mpost -s 'outputformat="svg"' figure.mp     # emits figure.1.svg, ...
# to PDF via the whole-file route:
mptopdf figure.mp          # -> figure-1.pdf, figure-2.pdf
```

### Skeleton file
```metapost
% figure.mp
prologues := 3;              % embed fonts so EPS is self-contained
outputtemplate := "%j-%c.svg";  % name outputs figure-1.svg, etc.
outputformat := "svg";

beginfig(1);
  draw (0,0)--(100,0)--(50,80)--cycle;
endfig;

end.
```

## Core Syntax / API Reference

### Numeric & pair (point) types
```metapost
numeric u; u := 1cm;             % a length; units: cm, mm, pt, bp, in
pair z0, z1;                     % 2D points; z1 is shorthand for (x1, y1)
z0 = (0, 0);
z1 = (2u, 0);
z2 = 0.5[z0, z1];                % mediation: point 50% from z0 to z1
% MetaPost SOLVES equations — order doesn't matter:
z3 = z0 + (u, u);
x4 = x1; y4 = y3;                % z4 lies under z1, level with z3
```
`a[p,q]` is *mediation* = `p + a*(q-p)`. Equations use `=` (a constraint to solve), while `:=` is imperative assignment.

### Paths & the Hobby spline operators
```metapost
path p;
p := (0,0)--(2u,0)--(u,2u)--cycle;      % straight segments, closed
path c;
c := (0,0){right} .. (u,2u){up} .. (2u,u){right};  % smooth curve w/ directions
% .. = smooth Hobby curve, -- = straight, ... = "tense"/looser curve
p := fullcircle scaled 2u shifted (3u,0);   % predefined: fullcircle, halfcircle, unitsquare
p := subpath (0,1) of c;                     % extract part of a path
point 0.5 of c;                              % point at time 0.5
```

### Drawing & filling
```metapost
draw p;                          % stroke with current pen
draw p withcolor blue withpen pencircle scaled 2pt;
fill p withcolor 0.8white;       % fill interior
filldraw p withcolor red;        % fill + stroke
draw p dashed evenly;            % dashed (evenly / withdots / dashpattern)
drawarrow z0--z1;                % arrowhead at end
drawdblarrow z0--z1;             % arrowheads both ends
undraw p;                        % erase (draw in background color)
```

### Pens, colors, dashes
```metapost
pickup pencircle scaled 1.5pt;   % set default pen
draw p;                          % uses picked-up pen
color myblue; myblue := (0.12, 0.47, 0.71);   % RGB in 0..1
draw p withcolor myblue;
draw p withcolor (0.8, 0.8, 0.8);
draw p dashed dashpattern(on 4bp off 2bp);
```

### Transforms
```metapost
draw p shifted (u, 0);
draw p scaled 1.5;
draw p rotated 30;               % degrees, about origin
draw p reflectedabout (z0, z1);
draw p slanted 0.5;
draw p xscaled 2 yscaled 0.5;
transform T; T := identity rotated 45 shifted (u,u);
draw p transformed T;
```

### Labels (TeX-typeset text)
```metapost
label("plain text", z0);              % centered at z0
label.top("$x$", z1);                 % suffix = placement: top,bot,lft,rt,ulft,urt,llft,lrt
dotlabel.bot("$A$", z0);              % draws a dot + label
label.rt(btex $\int_0^1 f(x)\,dx$ etex, z2);  % full TeX between btex..etex
```
`btex ... etex` compiles arbitrary (La)TeX; simple `"$...$"` works for basic math. Requires a TeX engine invoked by `mpost` automatically.

### Loops, conditionals, macros
```metapost
for i = 1 upto 5:
  draw (i*u, 0)--(i*u, u) withcolor (0.2i)*red;
endfor;

for x = 0 step 0.1 until 6.28:
  draw (x*u, sind(x*180/3.14159)*u);   % sind() = sine in degrees
endfor;

if x1 > x2: draw z1 withcolor red; else: draw z2; fi;

def cross(expr p, s) =            % define a reusable macro
  draw (p + (-s,-s))--(p + (s,s));
  draw (p + (-s,s))--(p + (s,-s));
enddef;
cross((u,u), 3pt);

vardef midtriangle(expr a, b, c) =    % vardef returns a value
  (a + b + c)/3
enddef;
```

## Output / Figure Types
Each `beginfig(n) ... endfig;` produces one independent figure. MetaPost is used for: geometric constructions, commutative/technical diagrams, function graphs (via loops or the bundled `graph` package), fractals and recursive figures, arrows/flow figures, boxes-and-connectors (`boxes`/`rboxes` packages), and font-quality curve art. Output formats: EPS (default), SVG (`outputformat:="svg"`), PDF (`mptopdf`/`luamplib`), and MPS (embeddable EPS-in-PDF).

## How-To

### How to add colors, custom pens & gradients-by-hand (styling recipe)
```metapost
beginfig(1);
  numeric u; u := 1cm;
  color brand; brand := (0.12, 0.47, 0.71);       % define an RGB color (0..1)
  path box; box := unitsquare xscaled 3u yscaled 2u;

  % flat fills and mixed colors:
  fill box withcolor 0.85[white, brand];          % brand mixed 85% toward... (mediation on colors)
  draw box withcolor brand withpen pencircle scaled 1.5pt;

  % manual "gradient": stack thin bands with interpolated color
  for i = 0 upto 40:
    fill unitsquare xscaled 3u yscaled (2u/41) shifted (0, i*2u/41)
      withcolor (i/40)[brand, (1,1,1)];
  endfor;

  draw box withpen pencircle scaled 1pt;          % re-stroke border on top
endfig;
end.
```
Colors are RGB triples in `0..1`; `a[c1,c2]` mediates between two colors. There is no native gradient primitive — band the fill in a loop for smooth shading. `cmyk(c,m,y,k)` and `withcolor (r,g,b)` are both accepted.

### How to build a constrained figure using the equation solver
```metapost
beginfig(2);
  numeric u; u := 1cm;
  pair z1, z2, z3, z4;
  z1 = (0,0);
  z2 = z1 + (4u, 0);
  z3 = z1 + (0, 3u);
  z4 = z2 + z3 - z1;              % parallelogram 4th corner — solved automatically
  draw z1--z2--z4--z3--cycle;
  dotlabel.llft("$z_1$", z1); dotlabel.lrt("$z_2$", z2);
  dotlabel.urt("$z_4$", z4);    dotlabel.ulft("$z_3$", z3);
endfig;
end.
```
State relationships with `=`; MetaPost solves the linear system for any unknown coordinates — you never compute the corner yourself.

### How to plot a mathematical function
```metapost
beginfig(3);
  numeric u; u := 1cm;
  path axis, sine;
  axis := (-0.3u,0)--(6.5u,0);
  draw axis dashed evenly;
  sine := (0,0)
    for t = 0.1 step 0.1 until 6.28:
      .. (t*u, sind(t*180/3.14159)*u)
    endfor;
  draw sine withcolor (0.85,0.1,0.1) withpen pencircle scaled 1pt;
  label.rt("$\sin x$", point (length sine) of sine);
endfig;
end.
```
Build a `path` by accumulating `.. (x,y)` segments in a `for` loop; `sind`/`cosd` take degrees, so convert radians.

### How to typeset TeX math labels on a diagram
```metapost
beginfig(4);
  numeric u; u := 1cm;
  z0 = origin; z1 = (3u, 0);
  drawarrow z0--z1;
  label.top(btex $\vec{v} = (v_x, v_y)$ etex, 0.5[z0,z1]);
  label.bot(btex \textbf{displacement} etex, 0.5[z0,z1]);
endfig;
verbatimtex \documentclass{article}\begin{document} etex   % preamble for btex
end.
```
`btex ... etex` runs the label through TeX; use `verbatimtex ... etex` at file top to set the document class/preamble.

### How to reuse geometry with a parametric macro
```metapost
vardef star(expr ctr, r, n) =
  save p; path p;
  p := ctr + (r,0) rotated 0
    for i = 1 upto n-1: -- ctr + (r,0) rotated (360i/n * (if odd n: 2 else: 1 fi)) endfor
    -- cycle;
  p
enddef;
beginfig(5);
  fill star(origin, 1cm, 5) withcolor (0.9,0.7,0.1);
endfig;
end.
```
`vardef` returns a value (here a `path`); `save` localizes temporaries so the macro is reentrant.

## Do's and Don'ts

### ✅ Do
- Use `=` for geometric *constraints* (solved) and `:=` for *assignments* (imperative). Mixing them up is the top bug source.
- Set `prologues := 3;` for self-contained EPS with embedded fonts.
- Use `sind`/`cosd` (degree trig) or convert explicitly — MetaPost angles are in degrees.
- Localize macro temporaries with `save name;` so macros don't leak numerics.
- Compile with `-numbersystem=double` when coordinates or products exceed the default `scaled` range (~±4096).

### ❌ Don't
- Don't assign a variable twice with `=` to inconsistent values — MetaPost reports "inconsistent equation" and stops. Use `:=` to overwrite.
- Don't exceed the `scaled` numeric limit (values above ~4096, or products thereof) — you'll get "Value is too large"; switch to `double`.
- Don't expect radian trig: `sin`/`cos` operate on... actually use `sind`/`cosd` for degrees and `mexp`/`mlog` for the scaled log/exp; plain `sin` isn't defined — always use `sind`/`cosd`.
- Don't forget `endfig;` and the final `end.` — a missing `end.` hangs the interpreter waiting for input.
- Don't invent a `path.toMetaPost()` bridge — author `.mp` source directly; the numbered EPS/SVG figures are the output.

## Styling, Theming & Customization
- **Colors**: `withcolor (r,g,b)` (0..1), predefined `red green blue white black`, `cmyk(c,m,y,k)`, and mediation `a[c1,c2]`. Load `TEX.mp`/`colorpicture` extensions for named palettes if needed.
- **Pens**: `pencircle` (round), `pensquare`, `makepen` for custom nibs; `pencircle scaled 2pt xscaled 3` for calligraphic (elliptical) pens. `pickup` sets the default.
- **Line styles**: `dashed evenly`, `dashed withdots`, `dashed dashpattern(on Xbp off Ybp)`; `linecap` and `linejoin` internal variables (`butt`/`rounded`/`squared`, `mitered`/`rounded`/`beveled`).
- **Fills/shading**: flat `fill ... withcolor`; smooth shading is manual (loop of bands) or via the `metafun` format's `withshading`.
- **Reusable style**: wrap common option sets in `def`/`vardef` macros; define named colors/pens once at file top.
- **metafun** (a superset used with ConTeXt) adds real gradients, transparency, and richer color — worth it for heavy styling.

## Advanced Features
- **Path algebra**: `intersectionpoint p q`, `intersectiontimes`, `p intersectionpoint q`, `buildcycle(a,b,c)` to form regions, `p cutbefore q`, `subpath`, `reverse`.
- **Directions & tension**: `{dir 45}`, `{curl 0}`, `..tension 1.5..`, `...` for controlling Hobby splines.
- **`boxes`/`rboxes` packages**: automatic boxes-and-arrows diagrams with named box anchors.
- **`graph` package**: Cartesian/log axes, `gdata`/`gdraw` for plotting external data files.
- **Transparency & shading** via `metafun`/`luamplib` when compiled inside LuaTeX.
- **`luamplib`**: embed MetaPost directly in LuaLaTeX documents (`\mp
begin ... \mpthang`), no separate `mpost` run.

## Common Pitfalls & Troubleshooting
- **"Inconsistent equation"**: two `=` constraints conflict, or you meant `:=`. Reduce/relax constraints.
- **"Value is too large"**: `scaled` overflow — recompile with `-numbersystem=double`.
- **Blank/tiny output**: figures are sized in PostScript points (bp); a `(0,0)--(1,1)` figure is 1bp across. Scale by a unit (`u := 1cm`).
- **Labels missing**: TeX label rendering needs `mpost` to find a TeX engine and, for `btex`, a valid `verbatimtex` preamble.
- **SVG not emitted**: set `outputformat:="svg"` (and optionally `outputtemplate`), or pass `-s 'outputformat="svg"'`.
- **Degrees vs radians**: `sind`/`cosd` take degrees; convert radian data first.
- **`end.` omitted**: interpreter waits on stdin — always terminate the file.

## Integration Notes
- **LaTeX**: include EPS via `\includegraphics` (needs `latex`+`dvips`), or use `luamplib` inside LuaLaTeX to embed `.mp` inline.
- **ConTeXt**: MetaPost is first-class (`\startMPcode ... \stopMPcode`) with `metafun` extensions.
- **Web/Markdown**: compile to SVG (`outputformat:="svg"`) and embed the resulting `figure-N.svg`.
- **PDF workflows**: `mptopdf` or `mpost`→`epstopdf`; MPS figures embed directly in pdfTeX.

## Best For / Avoid For
`precise-geometry`, `constrained-diagrams`, `math-figures`, `font-quality-curves`, `tex-labels`, `technical-illustration` — choose MetaPost when a figure is defined by geometric *relationships* (let the solver place points) or needs font-grade Hobby curves with TeX math labels.

Avoid for: interactive/web graphics (use SVG/JS), data dashboards (Plotly/Dash), or when TikZ's larger library ecosystem and inline-in-LaTeX convenience fit better (see `tikz-pgf.md`).

## See Also
- `tikz-pgf.md` — the more widely used LaTeX-native alternative with a huge library ecosystem
- `sympy.md` / `sagemath.md` — produce the math whose results you typeset via `btex...etex`
- `../use-case/mathematical-notation.md`, `../use-case/technical-diagrams.md`
