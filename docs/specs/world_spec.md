# Specification: World Data Model v1.0

## 1. Model Definition
The `World` is the canonical and complete representation of a game environment. It is a pure, serializable data object, independent of any rendering engine.

## 2. World Structure (Schema)
A `World` object must contain, at minimum:

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Unique identifier of the world instance. |
| `layout` | Object | Global dimensions (width, height, px_width, px_height). |
| `grids` | Array | List of logical layers (Grids) composing the space. |
| `entities` | Array | List of objects with position and lexical metadata. |
| `metadata` | Map | Additional information (seeds, weather, global tags). |
| `version` | Integer | Incremental sequence number to track logical changes. |

### 2.1 The Grid (Logical Layer)
Each Grid is a data matrix. It contains no images, only **identifiers** of tiles and their properties.
- `identifier`: Layer name (e.g., "Ground", "Walls", "Collision").
- `size`: (cols, rows).
- `data`: One-dimensional array of integers or symbols.

### 2.2 The Entity (Lexicon)
An entity is a point of interest with intention.
- `type`: Entity type (e.g., "Player", "EnemySpawn", "Trigger").
- `pos`: (x, y) in px and grid coordinates.
- `fields`: Map of custom properties from LDtk.

## 3. Transformation Rules
1. **Determinism**: Given the same LDtk JSON, the Loader MUST produce a bit-for-bit identical `World`.
2. **Immutability**: The `World` is not modified "in-place". Any structural change generates a new `World` or a `WorldDelta`.
3. **Purity (No-Behavior)**: The `World` is silent. It contains no:
    - Logic, callbacks, or lambdas.
    - References to external or rendering systems.
    - Transient execution state (HP, current inventory, pressed buttons).
    - If it's not serializable as pure JSON, it does not belong in the World.
4. **Lifecycle and Versioning**:
    - The World is **Semantically Immutable**.
    - No "hot-patching" of fields.
    - Any change produces a new `World` object with an incremented `version`.
    - Traceability is mandatory: every new World must be able to explain its origin relative to the previous one.

## 4. Data Lifecycle
1. **Load**: JSON -> Raw Data.
2. **Build**: Raw Data -> `World` Model.
3. **Analyze**: `World` -> `LogicalMap` (Graphs, Regions, AI paths).
4. **Interpret**: `World` + `Input` + `Logic` -> `Actions`.
5. **Render**: `World` + `CurrentState` -> Pixels.
