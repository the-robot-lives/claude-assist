# Fritzing

## What
Fritzing is an open-source (GPL v3+) visual electronics-design application built in C++/Qt, offering three integrated views — breadboard, schematic, and PCB layout. It is a native desktop app (Windows/macOS/Linux) aimed at education, Arduino/microcontroller prototyping, and maker projects; the primary consumer is the Fritzing application itself, which opens `.fzz` project files.

## How
- **LLM emits:** Fritzing project data — `.fzz` (Fritzing Archive) projects and `.fzp` (Fritzing Part) definitions, with custom parts backed by `.svg` graphics. Realistically the LLM describes/assembles the circuit; the artifact is authored/edited in the GUI.
- **Render path:** open the `.fzz` in the Fritzing desktop app, switch between breadboard/schematic/PCB views, then export. Manufacturing output goes through the Fab Lab tool.
- **Typical final artifact:** SVG, PNG, PDF (documentation) or Gerber/Excellon (fabrication).

## Why
- **Reach for it when:** the goal is an approachable, photorealistic breadboard diagram for a tutorial or classroom, or a simple-to-medium PCB where visual clarity matters more than dense professional routing.
- **Limitations:** it's a GUI-driven desktop tool (not a text-emit-and-render pipeline), tuned for simple-to-medium complexity; team collaboration relies on file-system/Git workflows with manual merge, and it lacks built-in simulation.
- **Relative to siblings:** Fritzing is the beginner/maker counterpart to KiCad — where KiCad targets professional multi-layer boards with scripting and Gerber precision, Fritzing prioritizes the visual breadboard-to-PCB transition for non-engineers.

## Source
- Solution reference: `fim/solution/fritzing.md`
