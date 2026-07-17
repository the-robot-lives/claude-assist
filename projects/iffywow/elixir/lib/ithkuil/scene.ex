defmodule Ithkuil.Scene do
  @moduledoc """
  Deterministic scene compiler: canonical coordinate -> render model.

  Faithful port of `../../web/src/scene.js` (+ `registry.js`, `util.js`).
  Both compilers must be node-for-node identical — same constants, same
  stable node IDs (`"g0.s3.mod"`), same placement math, same 0.1-rounded
  coordinates — so every runtime draws the same word identically.

  Output model:

      %{
        schema: "ithkuil-coordinate/1",
        latinized: String.t() | nil,
        integer: String.t() | nil,     # unsigned decimal string, codec-provided
        coordinate: wire,              # canonical tagged arrays (Elixir data)
        view_box: [number],            # [x, y, w, h]
        nodes: [node]
      }

  Each node: `%{id, kind, path, compact, exploded}` plus `:parent_id` for
  child nodes and `:socket` metadata on socket markers. A placement is
  `%{translate: [x, y], rotate: deg, scale: s, visible: bool}` — the
  renderer's only "logic" is choosing `compact` or `exploded`.

  ## JS numeric parity notes

    * `Math.imul(a, b) >>> 0` == `band(a * b, 0xFFFFFFFF)` for unsigned 32-bit
      `a`, `b`: imul is the signed low 32-bit word of the product; `>>> 0`
      reinterprets it unsigned, which is exactly the masked big-int product.
      All 32-bit wraparound here uses `band(..., 0xFFFFFFFF)` accordingly.
    * `Math.round` rounds half toward +infinity (`Math.round(-2.5) == -2`),
      unlike Elixir's `round/1` (half away from zero) — see `js_round/1`.
    * `r1/1` rounds to 0.1 and normalizes `-0.0` to `0.0`, like the JS `r1`.
    * Floating-point expressions replicate the JS evaluation order exactly
      (IEEE-754 doubles are order-sensitive).
  """

  import Bitwise

  alias Ithkuil.Coord
  alias Ithkuil.JSON

  @schema_version 1

  # Constants — MUST match web/src/scene.js.
  @base_r 40
  @anchor_r 46
  @marker_r 64
  @orbit_r 118
  @box_half 26
  @child_factor 0.5
  @compact_mod_scale 0.5
  @exploded_mod_scale 1.4
  @diac_ring_compact 18
  @diac_ring_exploded 36
  @compact_advance 130
  @exploded_advance 400
  @pad 18

  # Fixed socket inventory — MUST match web/src/registry.js SOCKETS.
  # Every possible socket has a fixed angle (degrees, SVG y-down: -90 is up);
  # empty sockets are hidden and occupied sockets never move.
  @socket_defs %{
    0 => {"upper", -90},
    1 => {"upper_right", -45},
    2 => {"right", 0},
    3 => {"lower_right", 45},
    4 => {"lower", 90},
    5 => {"lower_left", 135},
    6 => {"left", 180},
    7 => {"upper_left", -135}
  }
  @socket_count map_size(@socket_defs)

  @type placement :: %{translate: [number()], rotate: number(), scale: number(), visible: boolean()}
  @type scene_node :: map()
  @type model :: %{
          schema: String.t(),
          latinized: String.t() | nil,
          integer: String.t() | nil,
          coordinate: Coord.wire(),
          view_box: [number()],
          nodes: [scene_node()]
        }

  @doc """
  Compile a **canonical** coordinate into a render model.

  Options (codec-provided facts, embedded verbatim):

    * `:latinized` — romanized form or nil
    * `:integer` — unsigned decimal string or nil

  Use `Ithkuil.to_scene/1` for the validating/canonicalizing entry point.
  """
  @spec compile(Coord.t(), keyword()) :: model()
  def compile({:ithkuil_word, _version, glyphs} = coord, opts \\ []) do
    {nodes_rev, bounds} =
      glyphs
      |> Enum.with_index()
      |> Enum.reduce({[], nil}, fn {glyph, gi}, {nodes, bounds} ->
        emit_glyph(glyph, gi, nodes, bounds)
      end)

    %{
      schema: "ithkuil-coordinate/#{@schema_version}",
      latinized: Keyword.get(opts, :latinized),
      integer: Keyword.get(opts, :integer),
      coordinate: Coord.to_wire(coord),
      view_box: view_box(bounds, @pad),
      nodes: Enum.reverse(nodes_rev)
    }
  end

  # ------------------------------------------------------------------
  # Glyph / socket emission (mirrors compileScene / emitSocket)
  # ------------------------------------------------------------------

  defp emit_glyph({:glyph, _cc, base, orientation, sockets}, gi, nodes, bounds) do
    id = "g#{gi}"
    cc_x = gi * @compact_advance
    ce_x = gi * @exploded_advance
    orient_deg = orientation_degrees(orientation)

    node = %{
      id: id,
      kind: "base",
      path: base_path(base),
      compact: placement(cc_x, 0, orient_deg, 1),
      exploded: placement(ce_x, 0, orient_deg, 1)
    }

    bounds =
      bounds
      |> extend(cc_x, 0, @base_r + 8)
      |> extend(ce_x, 0, @base_r + 8)

    Enum.reduce(sockets, {[node | nodes], bounds}, fn sock, {n, b} ->
      emit_socket(n, b, id, sock, {cc_x, 0}, {ce_x, 0}, orient_deg, 0)
    end)
  end

  defp emit_socket(
         nodes,
         bounds,
         parent_id,
         {socket_id, {:modifier, shape, m_orientation, diacritics, child_sockets}},
         {ccx, ccy},
         {cex, cey},
         frame_deg,
         depth
       ) do
    {name, base_angle} = socket_def(socket_id)
    angle = base_angle + frame_deg
    dx = :math.cos(rad(angle))
    dy = :math.sin(rad(angle))
    k = :math.pow(@child_factor, depth)
    prefix = "#{parent_id}.s#{socket_id}"

    anchor_x = ccx + dx * @anchor_r * k
    anchor_y = ccy + dy * @anchor_r * k
    marker_x = cex + dx * @marker_r * k
    marker_y = cey + dy * @marker_r * k
    orbit_x = cex + dx * @orbit_r * k
    orbit_y = cey + dy * @orbit_r * k
    box_h = @box_half * k

    # 1. radial connector: exact center -> orbit box
    link = %{
      id: prefix <> ".link",
      parent_id: parent_id,
      kind: "connector",
      path: "M #{f(r1(cex))} #{f(r1(cey))} L #{f(r1(orbit_x))} #{f(r1(orbit_y))}",
      compact: hidden(),
      exploded: placement(0, 0)
    }

    # 2. socket indicator circle + orbit box outline
    marker = %{
      id: prefix <> ".marker",
      parent_id: parent_id,
      kind: "socket-marker",
      path:
        circle_path(marker_x, marker_y, max(2.5, 4 * k)) <>
          " " <> rect_path(orbit_x, orbit_y, box_h),
      compact: hidden(),
      exploded: placement(0, 0),
      socket: %{
        id: socket_id,
        name: name,
        occupied: true,
        anchor: [r1(anchor_x), r1(anchor_y)],
        orbit_center: [r1(orbit_x), r1(orbit_y)]
      }
    }

    # 3. the modifier itself — same node, two projections
    mod_deg = orientation_degrees(m_orientation) + frame_deg
    mod_id = prefix <> ".mod"

    mod_node = %{
      id: mod_id,
      parent_id: parent_id,
      kind: "modifier",
      path: modifier_path(shape),
      compact: placement(anchor_x, anchor_y, mod_deg, @compact_mod_scale * k),
      exploded: placement(orbit_x, orbit_y, mod_deg, @exploded_mod_scale * k)
    }

    nodes = [mod_node, marker, link | nodes]

    bounds =
      bounds
      |> extend(anchor_x, anchor_y, (16 + @diac_ring_compact) * k + 8)
      |> extend(orbit_x, orbit_y, box_h + @diac_ring_exploded * k + 10)
      |> extend(marker_x, marker_y, 6)

    # 4. diacritics orbit the modifier's own local center in fixed 45-degree slots
    nodes =
      diacritics
      |> Enum.with_index()
      |> Enum.reduce(nodes, fn {d, j}, acc ->
        slot = rad(-90 + j * 45 + mod_deg)
        sx = :math.cos(slot)
        sy = :math.sin(slot)
        rot = diacritic_rotation(d)

        diacritic = %{
          id: "#{mod_id}.d#{j}",
          parent_id: mod_id,
          kind: "diacritic",
          path: diacritic_path(d),
          compact:
            placement(
              anchor_x + sx * @diac_ring_compact * k,
              anchor_y + sy * @diac_ring_compact * k,
              rot,
              max(0.5, 0.8 * k)
            ),
          exploded:
            placement(
              orbit_x + sx * @diac_ring_exploded * k,
              orbit_y + sy * @diac_ring_exploded * k,
              rot,
              max(0.5, k)
            )
        }

        [diacritic | acc]
      end)

    # 5. recurse: the modifier's own sockets orbit ITS center
    Enum.reduce(child_sockets, {nodes, bounds}, fn child, {n, b} ->
      emit_socket(n, b, mod_id, child, {anchor_x, anchor_y}, {orbit_x, orbit_y}, mod_deg, depth + 1)
    end)
  end

  # ------------------------------------------------------------------
  # Placements, bounds, small paths
  # ------------------------------------------------------------------

  defp placement(tx, ty, rotate \\ 0, scale \\ 1, visible \\ true) do
    %{
      translate: [r1(tx), r1(ty)],
      rotate: r1(rotate),
      scale: js_round(scale * 1000) / 1000,
      visible: visible
    }
  end

  defp hidden, do: placement(0, 0, 0, 1, false)

  defp circle_path(cx, cy, r) do
    x0 = f(r1(cx - r))
    x1 = f(r1(cx + r))
    y = f(r1(cy))
    rr = f(r1(r))
    "M #{x0} #{y} A #{rr} #{rr} 0 1 0 #{x1} #{y} A #{rr} #{rr} 0 1 0 #{x0} #{y}"
  end

  defp rect_path(cx, cy, h) do
    "M #{f(r1(cx - h))} #{f(r1(cy - h))} H #{f(r1(cx + h))} V #{f(r1(cy + h))} H #{f(r1(cx - h))} Z"
  end

  defp extend(nil, x, y, r), do: {x - r, y - r, x + r, y + r}

  defp extend({min_x, min_y, max_x, max_y}, x, y, r) do
    {min(min_x, x - r), min(min_y, y - r), max(max_x, x + r), max(max_y, y + r)}
  end

  defp view_box(nil, _pad), do: [-60, -60, 120, 120]

  defp view_box({min_x, min_y, max_x, max_y}, pad) do
    [
      r1(min_x - pad),
      r1(min_y - pad),
      r1(max_x - min_x + 2 * pad),
      r1(max_y - min_y + 2 * pad)
    ]
  end

  # ------------------------------------------------------------------
  # Registry (port of web/src/registry.js)
  # ------------------------------------------------------------------

  @doc "Schema version stamped into the model."
  def schema_version, do: @schema_version

  @doc "Socket `{name, angle_degrees}` by id (fixed inventory, id mod 8)."
  def socket_def(id) do
    Map.fetch!(@socket_defs, Integer.mod(id, @socket_count))
  end

  @doc "Orientation id (0..3) -> degrees."
  def orientation_degrees(id), do: Integer.mod(id, 4) * 90

  @doc """
  Base glyph stroke path, centered on (0,0), extent ~ +/-40.
  Deterministic placeholder geometry (seed namespace 0x10000 + id) —
  replacing it with official Ithkuil IV paths is a rendering change only.
  """
  def base_path(id) do
    s = hash32(0x10000 + id)
    {r_k, s} = rand_next(s)
    k = 4 + trunc(r_k * 3)
    {pts, s} = ring_points(s, k, 34)
    {d, s} = polyline(pts, s, 26)
    {r_t, _s} = rand_next(s)
    tilt = (r_t - 0.5) * 0.45
    sx = :math.cos(tilt) * 34
    sy = :math.sin(tilt) * 34
    d <> " M #{f(r1(-sx))} #{f(r1(-sy))} L #{f(r1(sx))} #{f(r1(sy))}"
  end

  @doc "Modifier stroke path, centered on (0,0), extent ~ +/-16 (seed 0x20000 + id)."
  def modifier_path(id) do
    s = hash32(0x20000 + id)
    {r_k, s} = rand_next(s)
    k = 3 + trunc(r_k * 2)
    {pts, s} = ring_points(s, k, 15)
    {d, _s} = polyline(pts, s, 12)
    d
  end

  @doc "Diacritic mark path (four families: dot, bar, chevron, arc; seed 0x30000 + id)."
  def diacritic_path(id) do
    case rem(hash32(0x30000 + id), 4) do
      0 -> "M -3 0 A 3 3 0 1 0 3 0 A 3 3 0 1 0 -3 0"
      1 -> "M -5 0 L 5 0"
      2 -> "M -5 3 L 0 -4 L 5 3"
      _ -> "M -5 2 Q 0 -6 5 2"
    end
  end

  @doc "Deterministic rotation (multiples of 45 degrees) for a diacritic mark (seed 0x40000 + id)."
  def diacritic_rotation(id), do: rem(hash32(0x40000 + id), 8) * 45

  # ------------------------------------------------------------------
  # Deterministic helpers (port of web/src/util.js)
  # ------------------------------------------------------------------

  # 32-bit avalanche hash. JS: x = imul(x ^ (x >>> 16), 0x045d9f3b) >>> 0, twice.
  defp hash32(n) do
    x = band(bxor(band(n, 0xFFFFFFFF), 0x9E3779B9), 0xFFFFFFFF)
    x = band(bxor(x, bsr(x, 16)) * 0x045D9F3B, 0xFFFFFFFF)
    x = band(bxor(x, bsr(x, 16)) * 0x045D9F3B, 0xFFFFFFFF)
    band(bxor(x, bsr(x, 16)), 0xFFFFFFFF)
  end

  # LCG state step. JS: s = (imul(s, 1664525) + 1013904223) >>> 0; s / 2^32.
  # State is threaded explicitly (the JS version closes over mutable `s`).
  defp rand_next(s) do
    s2 = band(s * 1_664_525 + 1_013_904_223, 0xFFFFFFFF)
    {s2 / 4_294_967_296, s2}
  end

  defp ring_points(s, k, radius) do
    Enum.map_reduce(0..(k - 1), s, fn i, s ->
      # JS: a = -PI/2 + (i/k)*2*PI + (rand()-0.5)*0.9  (first rand call)
      {r_a, s} = rand_next(s)
      a = -:math.pi() / 2 + i / k * 2 * :math.pi() + (r_a - 0.5) * 0.9
      # JS: d = radius * (0.55 + 0.45*rand())          (second rand call)
      {r_d, s} = rand_next(s)
      d = radius * (0.55 + 0.45 * r_d)
      {{:math.cos(a) * d, :math.sin(a) * d}, s}
    end)
  end

  defp polyline([{x0, y0} | _] = pts, s, wobble) do
    {segments, {_prev, s}} =
      pts
      |> Enum.drop(1)
      |> Enum.with_index(1)
      |> Enum.map_reduce({hd(pts), s}, fn {{x, y}, i}, {{px, py}, s} ->
        if rem(i, 2) == 1 do
          # Quadratic: midpoint wobbled — mx rand first, then my rand.
          {r_mx, s} = rand_next(s)
          mx = (px + x) / 2 + (r_mx - 0.5) * wobble
          {r_my, s} = rand_next(s)
          my = (py + y) / 2 + (r_my - 0.5) * wobble
          {" Q #{f(r1(mx))} #{f(r1(my))} #{f(r1(x))} #{f(r1(y))}", {{x, y}, s}}
        else
          {" L #{f(r1(x))} #{f(r1(y))}", {{x, y}, s}}
        end
      end)

    {"M #{f(r1(x0))} #{f(r1(y0))}" <> Enum.join(segments), s}
  end

  defp rad(deg), do: deg * :math.pi() / 180

  @doc """
  Round to 0.1 with JS `Math.round` semantics (ties toward +infinity) and
  `-0.0` normalized to `0.0`. Mirrors `r1` in web/src/util.js.
  """
  def r1(n) do
    v = js_round(n * 10) / 10
    if v == 0.0, do: 0.0, else: v
  end

  # JS Math.round: nearest integer, ties toward +infinity.
  # (Math.round(-2.5) == -2; Math.round(0.49999999999999994) == 0 — computing
  # x - floor(x) avoids the classic floor(x + 0.5) tie bug.)
  defp js_round(x) when is_integer(x), do: x * 1.0

  defp js_round(x) when is_float(x) do
    floor = Float.floor(x)
    if x - floor >= 0.5, do: floor + 1.0, else: floor
  end

  defp f(n), do: JSON.format_number(n)
end
