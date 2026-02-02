# Stargateldtk: LDtk Integration Module 🌌

> [!IMPORTANT]
> **OFFICIAL VERSION (DISTRIBUTION)**
> This is the reference implementation used to develop the **Hot-Reload** and **Fluid Movement** features of Stargateldtk.
> For deep technical understanding and logic mapping, refer to the [Nodal Reference](stargate-ldtk/docs/referencia_nodal.md) (Spanish mandatory manual).

**Stargateldtk** is a runtime for DragonRuby designed for deterministic loading and technical analysis of **LDtk** data. It focuses on data consistency, separation of concerns, and auditable logic.

---

## Technical Specifications

The architecture is built on consistency and traceability:

1.  **Data Integrity**: The `World` is a static data structure. It contains no logic or rendering engine references.
2.  **Determinism**: Given the same JSON input, the `Loader` produces identical and predictable results.
3.  **Derived Processing**: Spatial logic is generated from base data via the `SpatialAnalyzer`.

---

## 📂 Project Structure

The system is organized by clear responsibilities:

- `stargate-ldtk/core/`: Deterministic loading of LDtk files.
- `stargate-ldtk/analysis/`: Spatial analysis (LogicalMap, Collisions).
- `stargate-ldtk/render/`: Passive observers for drawing.
- `stargate-ldtk/tactics/`: Decision and evaluation modules.
- `stargate-ldtk/adapters/`: Bridges for DragonRuby.
- `samples/`: Practical examples and reference exercises.
- `stargate-ldtk/docs/`: Manuals, specifications, and technical guides.

---

## 🛠️ Reference Samples

We have included:
- **[Caverns](samples/cavernas/main.rb)**: A tactics lab using a cavern map to demonstrate integration, smooth rendering, and decision making.
    - Fluid movement with interpolation.
    - Cinematic camera.
    - [Read Sample README](samples/cavernas/README.md)

---

## 🛠️ Usage Workflow

The runtime separates thought from action:

```ruby
# 1. LOAD
ldtk_json = args.gtk.parse_json(args.gtk.read_file("map.json"))
world = Stargateldtk::Core::Loader.load(args, ldtk_json)

# 2. ANALYSIS (Side-effect free)
map = Stargateldtk::Analysis::Spatial.analyze(world)

# 3. REASONING (Queries)
if map.walkable?(gx, gy)
  # The system "understands" the space
end

# 4. RENDER (Visualization)
Stargateldtk::Render::WorldRenderer.draw(args, world, camera)
```

---

## 🧠 Philosophy

This runtime is a tool for organizing game logic clearly.

*   **No hidden states**: Everything the system knows is in the `World` or the `LogicalMap`.
*   **Explicit versioning**: Structural changes increment the world version, guaranteeing traceability.
*   **Engine agnostic**: Although implemented in Ruby for DragonRuby, its data structure is easily portable.

---

## 📑 Design Specifications

For deep-dives into the rules governing this system, consult the design specifications:
*   [World Spec](stargate-ldtk/docs/specs/world_spec.md)
*   [Spatial Spec](stargate-ldtk/docs/specs/spatial_spec.md)
*   [User Manual](stargate-ldtk/docs/user_manual.md)
*   [Integration Guide](stargate-ldtk/docs/integration_guide.md)
*   [Nodal Reference (Spanish)](stargate-ldtk/docs/referencia_nodal.md)

---