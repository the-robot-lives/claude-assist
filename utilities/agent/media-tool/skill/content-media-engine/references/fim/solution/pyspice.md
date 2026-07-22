# PySpice — Circuit Simulation from Python

PySpice is a Python front-end for SPICE simulators (ngspice, Xyce). You build a
`Circuit` object with unit-aware element methods, call an analysis on its
`simulator()`, and get back NumPy waveforms you plot with Matplotlib. It removes
hand-written netlist bookkeeping while keeping full SPICE analysis power.

**Current Version**: PySpice 1.5+ (current)  **License**: GPL v3
**Runtime**: Python 3.8+; ngspice (shared lib or subprocess) or Xyce backend

## Official Resources & Documentation
- Docs: https://pyspice.fabrice-salvaire.fr/
- GitHub: https://github.com/FabriceSalvaire/PySpice
- PyPI: https://pypi.org/project/PySpice/
- Examples: https://pyspice.fabrice-salvaire.fr/releases/latest/examples/
- ngspice backend: https://ngspice.sourceforge.io/

## Installation & Setup
```bash
pip install PySpice
# Backend simulator:
sudo apt-get install ngspice          # or: brew install ngspice
pyspice-post-installation --install-ngspice-dll   # Windows helper
pyspice-post-installation --check-install         # verify backend
```

### Minimal simulation
```python
from PySpice.Spice.Netlist import Circuit
from PySpice.Unit import *

circuit = Circuit('RC low-pass')
circuit.V('input', 'in', circuit.gnd, 5@u_V)
circuit.R(1, 'in', 'out', 1@u_kΩ)
circuit.C(1, 'out', circuit.gnd, 100@u_nF)

sim = circuit.simulator(temperature=25, nominal_temperature=25)
analysis = sim.transient(step_time=1@u_us, end_time=1@u_ms)
print(analysis['out'][-1])            # final output voltage
```

## Core Syntax / API Reference

### Units (`PySpice.Unit`)
```python
from PySpice.Unit import *
10@u_V      1@u_kΩ     100@u_nF    1@u_mH
1@u_kHz     5@u_ms     1@u_uA      50@u_Ω
```
The `value@u_unit` syntax attaches a unit; arithmetic stays unit-aware.

### Building a circuit
```python
circuit = Circuit('title')
circuit.gnd                             # ground node (SPICE node 0)

# Passives:  method(name, node+, node-, value)
circuit.R(1, 'a', 'b', 4.7@u_kΩ)
circuit.C(1, 'b', circuit.gnd, 1@u_uF)
circuit.L(1, 'a', 'b', 1@u_mH)

# Sources:
circuit.V('in', 'in', circuit.gnd, 5@u_V)                       # DC
circuit.SinusoidalVoltageSource('src', 'in', circuit.gnd,
    amplitude=1@u_V, frequency=1@u_kHz)
circuit.PulseVoltageSource('p', 'in', circuit.gnd,
    initial_value=0@u_V, pulsed_value=5@u_V,
    delay_time=0@u_s, rise_time=1@u_ns, fall_time=1@u_ns,
    pulse_width=1@u_us, period=2@u_us)

# Semiconductors need a model:
circuit.model('Dmod', 'D', IS=1e-14, RS=0.5)
circuit.Diode(1, 'a', 'b', model='Dmod')
circuit.MOSFET(1, 'd', 'g', 's', 'b', model='NMOS')
```

### Raw netlist escape hatch
```python
circuit.raw_spice += '.options reltol=1e-5\n'
print(str(circuit))                     # inspect the generated netlist
```

### Subcircuits
```python
from PySpice.Spice.Netlist import SubCircuitFactory

class Opamp(SubCircuitFactory):
    NAME = 'opamp'
    NODES = ('inp', 'inn', 'out')
    def __init__(self):
        super().__init__()
        self.VCVS('gain', 'out', self.gnd, 'inp', 'inn', voltage_gain=1e6)

circuit.subcircuit(Opamp())
circuit.X('1', 'opamp', 'in+', 'in-', 'vout')
```

### The simulator & analyses
```python
sim = circuit.simulator(temperature=25, nominal_temperature=25)

op   = sim.operating_point()
dc   = sim.dc(Vinput=slice(0, 5, 0.1))               # sweep source 'Vinput'
ac   = sim.ac(start_frequency=1@u_Hz, stop_frequency=1@u_MHz,
              number_of_points=20, variation='dec')
tran = sim.transient(step_time=1@u_us, end_time=1@u_ms)
```

### Reading results (Analysis object)
```python
import numpy as np
v_out = np.array(analysis['out'])       # node voltage waveform
t     = np.array(analysis.time)         # transient time vector
f     = np.array(ac.frequency)          # AC frequency vector
i_v   = np.array(analysis.branches['vinput'])   # source branch current
for name, node in analysis.nodes.items():
    print(name, float(node[-1]))
```

## Analysis / Output Types
- `operating_point()` — DC bias.
- `dc(Src=slice(a,b,step))` — DC sweep.
- `ac(...)` — frequency response (complex; use `np.abs`, `np.angle`).
- `transient(step_time, end_time, ...)` — time domain.
- `noise(...)`, `dc_sensitivity(...)`, `polezero(...)` — advanced.

## How-To (worked recipes)

### How to plot and style results (visual analog of "add color")
Analyses return NumPy arrays — style with Matplotlib as usual:
```python
import matplotlib.pyplot as plt, numpy as np
ac = sim.ac(start_frequency=1@u_Hz, stop_frequency=1@u_MHz,
            number_of_points=20, variation='dec')
gain_db = 20*np.log10(np.abs(ac['out']))
plt.semilogx(np.array(ac.frequency), gain_db, color='crimson', lw=2)
plt.xlabel('Hz'); plt.ylabel('dB'); plt.grid(True, which='both')
plt.savefig('bode.svg')
```

### How to run a transient and measure a value
```python
tran = sim.transient(step_time=1@u_us, end_time=5@u_ms)
vout = np.array(tran['out'])
print('settled to', vout[-1], 'V; peak', vout.max())
```

### How to sweep a DC source for an I-V curve
```python
circuit.V('in', 'in', circuit.gnd, 0@u_V)
dc = sim.dc(Vin=slice(0, 5, 0.05))
plt.plot(np.array(dc['in']), np.array(dc.branches['vin']))
```

### How to parameterize and re-run
```python
for r in (1, 4.7, 10):
    circuit.R1.resistance = (r)@u_kΩ    # mutate element, re-simulate
    a = circuit.simulator().transient(step_time=1@u_us, end_time=1@u_ms)
    plt.plot(np.array(a.time), np.array(a['out']), label=f'{r}k')
plt.legend()
```

### How to inspect the generated netlist
```python
print(str(circuit))                     # exactly what ngspice receives
```

## Do's and Don'ts

### ✅ Do
- Attach units with `@u_*` on every value so scaling is unambiguous.
- Use `circuit.gnd` for ground, never a bare `0` string mixed with names.
- Wrap analyses in `np.array(...)` before heavy NumPy math.
- Give semiconductors a `circuit.model(...)` before instantiating them.
- Print `str(circuit)` when debugging — it reveals the real netlist.

### ❌ Don't
- Don't forget to install/verify the ngspice backend — import succeeds but
  `simulator()` fails without it.
- Don't leave a node with no DC path to ground (convergence failure, as in raw
  SPICE).
- Don't confuse element method names with SPICE letters — `circuit.V(...)`
  creates a `V…` card; the first arg is the *name suffix*.
- Don't reuse element names within one circuit.
- Don't expect AC results to be real — they're complex; take `abs`/`angle`.

## Styling, Theming & Customization
- All visualization is Matplotlib — colors, linestyles, dual-axis Bode plots,
  and themes come from Matplotlib, not PySpice.
- Use `variation='dec'|'oct'|'lin'` on `ac()` to control the frequency axis.
- Export vector figures (`savefig('x.svg')`) for docs.

## Advanced Features
- **Shared-library ngspice** for fast, in-process re-simulation loops.
- **Behavioral sources / raw_spice** injection for constructs the API lacks.
- **Temperature & Monte-Carlo** sweeps via repeated `simulator(temperature=…)`.
- **Xyce backend** for large/parallel simulations.
- **Unit arithmetic** carries through to computed quantities.

## Common Pitfalls & Troubleshooting
- **`NgSpiceSharedError` / backend not found** → ngspice not installed or DLL
  path unset; run `pyspice-post-installation --check-install`.
- **Convergence errors** → floating nodes, missing ground, discontinuous
  sources; add shunt resistance or `.options`.
- **KeyError on a node** → node name typo; nodes are the strings you used.
- **AC plot looks wrong** → forgot `np.abs`/`20*log10` for magnitude.
- **Slow loops** → prefer the shared-lib backend and mutate elements in place.

## Integration Notes
- Fits Jupyter/Livebook-style notebooks; results plot inline via Matplotlib.
- Emits standard SPICE — you can dump `str(circuit)` to a `.cir` for ngspice.
- Pairs with SchemDraw/CircuiTikZ for the schematic figure of a simulated ckt.

## Best For / Avoid For
`spice-in-python`, `parametric-sweeps`, `bode-plots`, `notebooks` — choose
PySpice to script numerical simulations and plot them. Avoid for symbolic /
closed-form transfer functions (use Lcapy) and for schematic drawing.

## See Also
- [spice-netlist.md](spice-netlist.md) — the underlying netlist format
- [lcapy.md](lcapy.md) — symbolic analysis + schematic drawing
- [schemdraw.md](schemdraw.md) — draw the circuit you simulate
- [kicad.md](kicad.md) — capture that exports SPICE netlists
- ../use-case/engineering-diagrams.md
