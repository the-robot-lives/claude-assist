# VTK.js — scientific visualization for the web (WebGL)

VTK.js is Kitware's JavaScript port of the Visualization Toolkit: a WebGL-based library for 3D scientific and medical visualization in the browser. It renders volumes (CT/MRI), polygonal geometry, isosurfaces, glyphs, streamlines, and cut planes through the classic VTK **pipeline** — `Source → Filter → Mapper → Actor → Renderer → RenderWindow`. It targets DICOM/medical imaging, engineering simulation results, and large scientific datasets. For npl-fim, VTK.js output is authored as an ES-module JavaScript program that builds a pipeline and attaches it to a DOM container (or `vtkFullScreenRenderWindow`).

**Current Version**: @kitware/vtk.js 30.x+ (current major, continuously released)  **License**: BSD-3-Clause  **Runtime**: WebGL2 (WebGPU backend experimental); ES modules, tree-shakeable

## Official Resources & Documentation
- Docs & API: https://kitware.github.io/vtk-js/
- Examples gallery: https://kitware.github.io/vtk-js/examples/
- GitHub: https://github.com/Kitware/vtk-js
- npm: https://www.npmjs.com/package/@kitware/vtk.js
- Data formats & readers: https://kitware.github.io/vtk-js/docs/concepts_readers.html

## Installation & Setup

### npm (recommended — enables tree-shaking)
```bash
npm install @kitware/vtk.js
```

### CDN / UMD (quick prototypes)
```html
<script src="https://unpkg.com/@kitware/vtk.js"></script>
<!-- global: vtk.Rendering.Misc.FullScreenRenderWindow, etc. -->
```

### Import model
VTK.js has no single default export. Import each class from its deep path, and import a **rendering profile** once to register the OpenGL backend:
```javascript
import '@kitware/vtk.js/Rendering/Profiles/Geometry';  // for polydata/geometry
// or '.../Profiles/Volume' for volume rendering; '.../Profiles/Glyph' for glyphs
import vtkFullScreenRenderWindow from '@kitware/vtk.js/Rendering/Misc/FullScreenRenderWindow';
```
Every VTK.js class is created with `.newInstance(props)` — there is no `new`.

## Core Syntax / API Reference

### The pipeline objects
```javascript
// Render context
const fsrw = vtkFullScreenRenderWindow.newInstance({ background: [0.1, 0.1, 0.12] });
const renderer    = fsrw.getRenderer();      // vtkRenderer: camera, lights, actors
const renderWindow = fsrw.getRenderWindow();  // vtkRenderWindow: drives frames

// Non-fullscreen: attach to your own element
// const grw = vtkGenericRenderWindow.newInstance();
// grw.setContainer(document.querySelector('#view'));
// grw.resize();
```

### Source → Mapper → Actor (geometry path)
```javascript
import vtkConeSource from '@kitware/vtk.js/Filters/Sources/ConeSource';
import vtkMapper from '@kitware/vtk.js/Rendering/Core/Mapper';
import vtkActor  from '@kitware/vtk.js/Rendering/Core/Actor';

const cone   = vtkConeSource.newInstance({ height: 1.0, radius: 0.5, resolution: 32 });
const mapper = vtkMapper.newInstance();
mapper.setInputConnection(cone.getOutputPort());   // connect pipeline

const actor  = vtkActor.newInstance();
actor.setMapper(mapper);
actor.getProperty().setColor(0.2, 0.6, 1.0);        // RGB 0..1
actor.getProperty().setOpacity(1.0);

renderer.addActor(actor);
renderer.resetCamera();
renderWindow.render();
```

### Volume rendering path
```javascript
import '@kitware/vtk.js/Rendering/Profiles/Volume';
import vtkVolume from '@kitware/vtk.js/Rendering/Core/Volume';
import vtkVolumeMapper from '@kitware/vtk.js/Rendering/Core/VolumeMapper';
import vtkColorTransferFunction from '@kitware/vtk.js/Rendering/Core/ColorTransferFunction';
import vtkPiecewiseFunction from '@kitware/vtk.js/Common/DataModel/PiecewiseFunction';
import vtkHttpDataSetReader from '@kitware/vtk.js/IO/Core/HttpDataSetReader';

const reader = vtkHttpDataSetReader.newInstance({ fetchGzip: true });
reader.setUrl('/data/headsq.vti').then(() => reader.loadData()).then(() => {
  const mapper = vtkVolumeMapper.newInstance();
  mapper.setInputConnection(reader.getOutputPort());
  mapper.setSampleDistance(0.7);

  const ctf = vtkColorTransferFunction.newInstance();
  ctf.addRGBPoint(0,   0.0, 0.0, 0.0);
  ctf.addRGBPoint(255, 1.0, 0.9, 0.8);

  const otf = vtkPiecewiseFunction.newInstance();   // opacity
  otf.addPoint(0,   0.0);
  otf.addPoint(120, 0.0);
  otf.addPoint(255, 0.6);

  const volume = vtkVolume.newInstance();
  volume.setMapper(mapper);
  volume.getProperty().setRGBTransferFunction(0, ctf);
  volume.getProperty().setScalarOpacity(0, otf);
  volume.getProperty().setInterpolationTypeToLinear();
  volume.getProperty().setShade(true);

  renderer.addVolume(volume);
  renderer.resetCamera();
  renderWindow.render();
});
```

### Readers (data ingest)
```javascript
// Common IO classes:
import vtkXMLImageDataReader   from '@kitware/vtk.js/IO/XML/XMLImageDataReader';    // .vti
import vtkXMLPolyDataReader    from '@kitware/vtk.js/IO/XML/XMLPolyDataReader';     // .vtp
import vtkPLYReader            from '@kitware/vtk.js/IO/Geometry/PLYReader';        // .ply
import vtkSTLReader            from '@kitware/vtk.js/IO/Geometry/STLReader';        // .stl
import vtkOBJReader            from '@kitware/vtk.js/IO/Misc/OBJReader';            // .obj
import vtkHttpDataSetReader    from '@kitware/vtk.js/IO/Core/HttpDataSetReader';    // vtk.js JSON
```

### Filters (transform data in the pipeline)
```javascript
import vtkImageMarchingCubes from '@kitware/vtk.js/Filters/General/ImageMarchingCubes';
const mc = vtkImageMarchingCubes.newInstance({ contourValue: 100.0 });
mc.setInputConnection(reader.getOutputPort());
mapper.setInputConnection(mc.getOutputPort());   // isosurface -> geometry
```
Common filters: `ImageMarchingCubes` (isosurface), `Cutter` (slice plane), `WarpScalar`, `Calculator`, `TubeFilter`, `Glyph3DMapper`, `OutlineFilter`.

### Interaction & camera
```javascript
const cam = renderer.getActiveCamera();
cam.setPosition(0, 0, 5); cam.setFocalPoint(0, 0, 0); cam.setViewUp(0, 1, 0);
renderer.resetCameraClippingRange();
// FullScreenRenderWindow wires a trackball interactor automatically.
// Image/slice interaction: import ...InteractorStyleImage / ...ManipulatorStyle
```

## Visualization Types (what VTK.js renders)
Volume rendering (GPU ray casting), polygonal surfaces (mesh geometry), isosurfaces/contours (marching cubes), 2D image slices (axial/sagittal/coronal via `ImageMapper`/`ImageSlice`), glyphs (arrows/spheres at points), streamlines/tubes, cut planes, cone/sphere/arrow/plane/line **source** primitives, point clouds, molecular/graph structures, and scalar-bar/orientation-widget overlays.

## How-To

### How to add colors, colormaps & opacity (the styling recipe)
```javascript
// Geometry: solid color + material props on the actor's Property
actor.getProperty().setColor(0.9, 0.3, 0.2);       // RGB 0..1 (NOT 0..255)
actor.getProperty().setOpacity(0.85);
actor.getProperty().setEdgeVisibility(true);
actor.getProperty().setInterpolationToPhong();      // smooth shading

// Color BY a data array with a preset colormap:
import vtkColorMaps from '@kitware/vtk.js/Rendering/Core/ColorTransferFunction/ColorMaps';
import vtkColorTransferFunction from '@kitware/vtk.js/Rendering/Core/ColorTransferFunction';
const preset = vtkColorMaps.getPresetByName('Cool to Warm');   // or 'jet', 'viridis', 'rainbow'
const lut = vtkColorTransferFunction.newInstance();
lut.applyColorMap(preset);
lut.setMappingRange(0, 255);
mapper.setLookupTable(lut);
mapper.setScalarVisibility(true);
mapper.setColorModeToMapScalars();
```
Actor colors are RGB in **0..1**. To color by scalar data, attach a `ColorTransferFunction` (from a named preset in `ColorMaps`) as the mapper's lookup table.

### How to render three orthogonal slice views (axial/sagittal/coronal)
```javascript
import vtkImageSlice  from '@kitware/vtk.js/Rendering/Core/ImageSlice';
import vtkImageMapper from '@kitware/vtk.js/Rendering/Core/ImageMapper';

const imapper = vtkImageMapper.newInstance();
imapper.setInputConnection(reader.getOutputPort());
imapper.setSliceAtFocalPoint(true);
imapper.setSlicingMode(vtkImageMapper.SlicingMode.K);   // I=sagittal, J=coronal, K=axial
const islice = vtkImageSlice.newInstance();
islice.setMapper(imapper);
islice.getProperty().setColorWindow(2000);   // CT window/level
islice.getProperty().setColorLevel(500);
renderer.addActor(islice);
```

### How to extract and render an isosurface from a volume
```javascript
import vtkImageMarchingCubes from '@kitware/vtk.js/Filters/General/ImageMarchingCubes';
const surface = vtkImageMarchingCubes.newInstance({ contourValue: 80.0, computeNormals: true });
surface.setInputConnection(reader.getOutputPort());

const smapper = vtkMapper.newInstance({ scalarVisibility: false });
smapper.setInputConnection(surface.getOutputPort());
const sactor = vtkActor.newInstance();
sactor.setMapper(smapper);
sactor.getProperty().setColor(0.9, 0.85, 0.8);
renderer.addActor(sactor);
renderWindow.render();
```

### How to capture the render as a PNG (export)
```javascript
renderWindow.captureImages()[0].then((imgURI) => {
  const a = document.createElement('a');
  a.href = imgURI; a.download = 'render.png'; a.click();
});
```
`captureImages()` returns an array of Promises resolving to data-URIs — the standard screenshot/export path.

## Do's and Don'ts

### ✅ Do
- Import a **rendering profile** (`Rendering/Profiles/Geometry` or `.../Volume`) exactly once before creating render objects — it registers the WebGL backend.
- Create every object with `Class.newInstance(props)`; never `new vtkClass()`.
- Connect the pipeline with `setInputConnection(src.getOutputPort())`; use `setInputData()` only for a concrete dataset you already hold.
- Call `renderer.resetCamera()` after adding actors and `renderWindow.render()` after any change — VTK.js does not auto-render.
- Use `container`-based `vtkGenericRenderWindow` + `.resize()` when embedding in a layout (not fullscreen).

### ❌ Don't
- Don't pass 0..255 colors to `setColor` — it expects 0..1 floats; 255 clamps to white.
- Don't forget to `.render()` after mutating props — the canvas will look frozen.
- Don't import from `'@kitware/vtk.js'` root for production and expect small bundles; import deep paths so tree-shaking works.
- Don't load huge volumes without downsampling/LOD — WebGL texture and memory limits will crash the context.
- Don't invent an `⟨npl:fim:vtk⟩` DSL as the actual output — that block is only a planning annotation; the deliverable is the JS pipeline code above.
- Don't reuse one mapper across actors expecting independent colors — give each actor its own mapper/property.

## Styling, Theming & Customization
- **Actor material** (`actor.getProperty()`): `setColor(r,g,b)`, `setOpacity`, `setEdgeVisibility`, `setLineWidth`, `setPointSize`, `setInterpolationToPhong/Flat/Gouraud`, `setAmbient/Diffuse/Specular/SpecularPower`, `setRepresentation` (Points/Wireframe/Surface).
- **Colormaps**: `vtkColorMaps.getPresetByName('Viridis' | 'Cool to Warm' | 'jet' | 'Grayscale' | 'rainbow')`, applied via `ColorTransferFunction.applyColorMap`.
- **Volume transfer functions**: `ColorTransferFunction` (RGB by scalar) + `PiecewiseFunction` (opacity by scalar) fully control appearance; `setGradientOpacity`, `setShade`, `setUseGradientOpacity`.
- **Scene**: `fsrw`/renderer `setBackground([r,g,b])` (or two-color gradient background), lights via `renderer.addLight` / `createLightKit`.
- **Overlays**: `vtkScalarBarActor` (color legend), `vtkOrientationMarkerWidget` (axes cube), `vtkAxesActor`.

## Advanced Features
- **Widgets** (`Widgets/*`): interactive plane/sphere/line/distance/angle widgets for measurement and cropping.
- **Picking**: `vtkCellPicker` / hardware selector for click-to-select on cells/points.
- **Glyphing**: `vtkGlyph3DMapper` to instance a shape at every point (vector fields, molecules).
- **Multiple viewports**: several `vtkRenderer`s in one `RenderWindow` with `setViewport([x0,y0,x1,y1])`.
- **WebXR**: `Rendering/WebXR` helpers for VR/AR viewing of scientific scenes.
- **WebGPU backend**: `Rendering/Profiles/*` + WebGPU render window (experimental) for larger datasets.
- **Data conversion**: `vtk-js`'s companion tools export ParaView/VTK datasets to the `.vti`/`.vtp`/vtk.js JSON formats readers expect.

## Common Pitfalls & Troubleshooting
- **Blank canvas**: missing profile import, or you forgot `renderWindow.render()` / `resetCamera()`.
- **White everything**: colors given in 0..255 instead of 0..1.
- **Nothing after data load**: readers are async — chain `.setUrl(...).then(() => reader.loadData()).then(...)` before building the mapper.
- **Context lost / crash on big data**: exceeds WebGL texture/memory limits — downsample, use `setSampleDistance`, or LOD.
- **Volume renders but is invisible**: opacity transfer function maps your value range to 0 — set `PiecewiseFunction` points across the actual scalar range.
- **Layout embed clipped**: call `renderWindow`/`genericRenderWindow.resize()` after the container changes size.
- **CORS on remote data**: `HttpDataSetReader` fetches need proper CORS headers on the data host.

## Integration Notes
- **React/Vue**: create the pipeline in a mount effect, store instances in a ref, and `delete()`/`renderWindow.delete()` on unmount to free GL resources.
- **ParaViewWeb / trame**: VTK.js is the client renderer for server-driven ParaView sessions.
- **itk.js / itk-wasm**: pairs with itk-wasm for DICOM/NIfTI decoding before handing image data to VTK.js.
- **Bundlers**: works with Vite/webpack; ensure the loader handles VTK.js's `glsl`/worker imports (Kitware provides rules).

## Best For / Avoid For
`scientific-visualization`, `medical-imaging`, `volume-rendering`, `dicom`, `isosurface`, `simulation-results`, `webgl-3d` — choose VTK.js when you need true scientific 3D (volumes, slices, contours, colormaps) in the browser with a proven pipeline model.

Avoid for: general/game 3D and product renders (use three.js/Babylon), simple charts (Plotly/ECharts), or lightweight 2D — VTK.js is heavy and specialized.

## See Also
- `three_js.md` / `babylon.md` — general-purpose WebGL 3D engines for non-scientific scenes
- `plotly_js.md` — 3D surface/scatter charts when full VTK power is overkill
- `ipywidgets.md` — notebook-side interactive scientific viz (itkwidgets/pyvista analog)
- `../use-case/scientific-computing.md`, `../use-case/3d-visualization.md`
