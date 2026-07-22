# SPICE Netlist — Circuit Description for Simulation

A SPICE netlist is the text format every analog circuit simulator understands:
element "cards" name components and the nodes they connect, `.model` cards define
device physics, and dot-commands request analyses (DC, AC, transient, noise).
It is the lingua franca between schematic tools, simulators (ngspice, LTspice,
HSPICE, Xyce), and higher-level Python wrappers.

**Format**: SPICE2/3 netlist (ASCII)  **License**: format is open
**Simulators**: ngspice, LTspice, HSPICE, Spectre, Xyce, PySpice (front-end)

## Official Resources & Documentation
- ngspice manual: https://ngspice.sourceforge.io/docs.html
- LTspice: https://www.analog.com/en/resources/design-tools-and-calculators/ltspice-simulator.html
- Xyce: https://xyce.sandia.gov/
- Classic SPICE reference: http://bwrcs.eecs.berkeley.edu/Classes/IcBook/SPICE/
- Model libraries: manufacturer `.lib`/`.mod` files

## Installation & Setup
```bash
# ngspice (open source, batch + interactive)
sudo apt-get install ngspice          # or: brew install ngspice
ngspice circuit.cir                    # run a netlist

# LTspice: GUI download from analog.com (also runs netlists in batch)
# Python front-ends:
pip install spicelib PyLTSpice
```

### Netlist skeleton
```spice
* First line is ALWAYS the title (treated as a comment)
.title RC low-pass
V1 in 0 DC 5 AC 1
R1 in out 1k
C1 out 0 100n
.ac dec 20 1 1meg
.tran 1u 10m
.end
```
- Line 1 is the mandatory title. `.end` terminates the deck.
- Node `0` is global ground. Nodes may be names or numbers.

## Core Syntax / API Reference

### Element cards (first letter = type)
```spice
Rname  n+ n- value                 ; resistor      R1 a b 4.7k
Cname  n+ n- value [IC=v]          ; capacitor     C1 out 0 100n IC=0
Lname  n+ n- value [IC=i]          ; inductor      L1 a b 1m
Dname  n+ n- modelname             ; diode         D1 a b Dmod
Qname  nc nb ne modelname          ; BJT           Q1 c b e QNPN
Mname  nd ng ns nb modelname L= W= ; MOSFET        M1 d g s b NMOS L=1u W=10u
Jname  nd ng ns modelname          ; JFET
Xname  n1 n2 ... subname [params]  ; subcircuit call
Ename  n+ n- nc+ nc- gain          ; VCVS (voltage-controlled voltage source)
Gname  n+ n- nc+ nc- gm            ; VCCS
Fname  n+ n- Vctrl gain            ; CCCS
Hname  n+ n- Vctrl r               ; CCVS
Kname  Lx Ly coupling              ; mutual inductance
Bname  n+ n- V=<expr>              ; behavioral source (ngspice)
```

### Number suffixes (mind M vs MEG!)
```
T=1e12  G=1e9  MEG=1e6  K=1e3  m=1e-3  u=1e-6  n=1e-9  p=1e-12  f=1e-15
```
`1M` is **one milli** (0.001), not mega. Use `1MEG` for 10^6 — a classic bug.

### Independent sources
```spice
V1 in 0 DC 5 AC 1 SIN(0 1 1k)      ; DC op point, AC probe, transient waveform
I1 0 out DC 1m
```
Transient waveform functions:
```spice
PULSE(v1 v2 delay trise tfall width period)
SIN(offset amplitude freq delay damping phase)
PWL(t1 v1 t2 v2 t3 v3 ...)
EXP(v1 v2 td1 tau1 td2 tau2)
SFFM(offset amp fc modidx fs)      ; single-freq FM
```

### `.model` cards
```spice
.model Dmod  D   (IS=1e-14 RS=0.5 N=1.2 CJO=2p)
.model QNPN  NPN (BF=200 VAF=100 IS=1e-16)
.model NMOS  NMOS (LEVEL=1 KP=120u VTO=0.7 LAMBDA=0.02)
```

### Subcircuits
```spice
.subckt opamp inp inn out vcc vee PARAMS: gain=1e6
Rin  inp inn 10Meg
Eout out 0 inp inn {gain}
.ends opamp

X1 in+ in- vo vdd vss opamp PARAMS: gain=2e5
```

### Analysis dot-commands
```spice
.op                                 ; DC operating point
.dc V1 0 5 0.1                       ; sweep source V1 from 0..5 step 0.1
.ac dec 20 1 1meg                    ; AC: 20 pts/decade, 1 Hz..1 MHz
.tran 1u 10m 0 5u                    ; transient: step tstop [tstart [tmax]]
.tran 1u 10m UIC                     ; use initial conditions (skip .op)
.noise v(out) V1 dec 10 1 100k       ; noise analysis
.tf v(out) V1                        ; transfer function / impedances
.four 1k v(out)                      ; Fourier of transient
```

### Control / housekeeping
```spice
.include models.lib
.lib /path/cmos.lib tt               ; library section
.param rload=1k
R1 out 0 {rload}
.temp 27
.options reltol=1e-4 method=gear
.save v(out) i(V1)
.meas tran vpp PP v(out)             ; measurement (ngspice)
```

### ngspice interactive control block
```spice
.control
run
plot v(in) v(out)
wrdata out.csv v(out)
.endc
```

## Analysis / Output Types
- **.op** — bias point. **.dc** — DC sweep. **.ac** — frequency response (Bode).
- **.tran** — time domain. **.noise** — spectral noise. **.tf/.sens** — small
  signal. **.four/.disto** — harmonic/distortion. Monte-Carlo & temperature
  sweeps via `.param`/`.step`/`.dc TEMP`.

## How-To (worked recipes)

### How to plot and style simulation output (the visual analog of "add color")
Netlists are text; the "styling" surface is the plot. In ngspice, drive it from
a `.control` block or gnuplot:
```spice
.control
run
set color0=white
plot vdb(out) xlabel 'Hz' ylabel 'dB'      ; magnitude Bode, log x auto for .ac
hardcopy bode.svg vdb(out)                  ; write a vector figure
.endc
```
`plot v(out) v(in)` overlays traces; `gnuplot out v(out)` exports via gnuplot
where you control colors/line styles.

### How to sweep a parameter (design exploration)
```spice
.param rl=1k
R1 out 0 {rl}
.step param rl 1k 10k 1k               ; ngspice: rerun for each value
.ac dec 20 1 1meg
```

### How to model a transient pulse response
```spice
V1 in 0 PULSE(0 5 0 1n 1n 1u 2u)
R1 in out 1k
C1 out 0 1n
.tran 1n 5u
```

### How to instantiate a reusable op-amp subcircuit
```spice
.subckt oa inp inn out
Eo out 0 inp inn 1e6
.ends
X1 sig 0 amp oa
Rf amp sig 100k
.tran 1u 1m
```

### How to import vendor models and run a corner
```spice
.include bjt_2n2222.lib
Q1 c b e Q2N2222
.dc VCE 0 10 0.1 IB 10u 50u 10u        ; nested sweep for I-V curves
```

## Do's and Don'ts

### ✅ Do
- Remember the mandatory title line — the parser treats line 1 as a comment.
- Use `MEG` for 10^6; reserve `M` only when you truly mean milli.
- Define node `0` as ground and reference at least one node to it.
- Give every semiconductor a matching `.model` (or `.include` its library).
- Terminate with `.end`.

### ❌ Don't
- Don't write `1M` for a megaohm — it becomes 1 mΩ and silently ruins results.
- Don't leave a node floating (no DC path to ground) — convergence fails.
- Don't reuse a reference name (`R1` twice) — later cards override silently.
- Don't mix simulator-specific syntax (LTspice `.tran` options vs ngspice) in a
  portable deck.
- Don't forget `UIC` when you rely on `IC=` initial conditions.

## Styling, Theming & Customization
- Output styling lives in the plotter: ngspice `plot`/`hardcopy`, gnuplot,
  or export CSV (`wrdata`) and style in matplotlib.
- `.probe`/`.save` select which signals are retained; smaller sets plot faster.
- Bode plots: `vdb()` for magnitude in dB, `vp()` for phase.

## Advanced Features
- **Behavioral sources** `B` with arbitrary `V=`/`I=` expressions.
- **`.meas`** extracts numeric metrics (rise time, gain, bandwidth) headlessly.
- **Monte-Carlo / mismatch** via `.param` with `gauss()`/`agauss()` (ngspice).
- **`.step`** for multi-run parameter/temperature corners.
- **`.include`/`.lib`** for large model decks and process corners.

## Common Pitfalls & Troubleshooting
- **"singular matrix" / no convergence** → floating node, missing ground, or
  zero-value series element; add a large shunt resistor or check topology.
- **Wrong magnitudes** → `M` vs `MEG` suffix confusion.
- **"model not found"** → forgot `.include` / `.lib`, or model name typo.
- **Flat AC response** → source lacks `AC 1` magnitude.
- **Transient ignores IC** → add `UIC` to `.tran`.

## Integration Notes
- Exported by KiCad/LTspice schematics; consumed by ngspice/Xyce/HSPICE.
- PySpice and spicelib wrap deck generation and result parsing in Python.
- Not a diagram format — pair with plots (matplotlib/gnuplot) for figures.

## Best For / Avoid For
`analog-simulation`, `spice`, `frequency-response`, `transient`, `device-models`
— choose a raw netlist for portable, scriptable simulation. Avoid for schematic
*drawing* (use CircuiTikZ/SchemDraw/KiCad) and for symbolic/closed-form analysis
(use Lcapy).

## See Also
- [pyspice.md](pyspice.md) — Python API that emits & runs these netlists
- [lcapy.md](lcapy.md) — symbolic analysis + schematic drawing
- [kicad.md](kicad.md) — schematic capture that exports netlists
- [circuitikz.md](circuitikz.md) — draw the circuit you simulate
- ../use-case/engineering-diagrams.md
