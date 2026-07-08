# VTK.js

## What
VTK.js is a scientific visualization library for medical imaging, engineering simulations, and data analysis in the browser. It provides GPU volume rendering, DICOM/medical image support, slice views, and surface extraction. Primary consumer is browser JavaScript (WebGL).

## How
- The LLM emits JavaScript that imports VTK.js modules, creates a `vtkFullScreenRenderWindow`, reads data via `vtkHttpDataSetReader` (e.g. a `.vti` volume), builds a `vtkVolumeMapper` + `vtkVolume` actor, adds it to the renderer, resets the camera, and renders.
- Turned into a viewable artifact via npm (`npm install @kitware/vtk.js`) or a CDN `<script>` include of `@kitware/vtk.js`, rendering into a full-screen WebGL window.
- Typical final artifact: an interactive WebGL scientific/volume visualization.

## Why
- Reach for VTK.js when the domain is scientific/medical volumetric data: GPU ray-cast volume rendering, DICOM imaging, axial/sagittal/coronal slice views, surface extraction/contouring, and scientific colormaps.
- Tradeoffs (from best practices): large datasets need LOD, progressive loading, cached intermediate representations, and careful GPU memory management for volumes.
- Versus [[paraview-web]] — VTK.js renders client-side in the browser and shares Kitware's VTK lineage; ParaView Web targets server-side rendering of massive datasets. For general (non-scientific) 3D, use [[three_js]] or [[babylon_js]].

## Source
- Solution reference: `fim/solution/vtk_js.md`
