# Specification: Entity Mapping (v1.x)

This document defines how to translate external data (LDtk, JSON) into meanings that the **Cognitive Core** can process.

## Translation Model

The Core does not observe "what it is" (sprite, sound), but "what it means" (influence, obstacle).

### 1. Terrain Entities (Static Entities)
Any entity that alters the topography of the `LogicalMap`.

| LDtk Attribute | Meaning in World | Cognitive Effect |
| :--- | :--- | :--- |
| `tags: ["hazard"]` | `metadata: { hazard: true }` | Vetoed by `Intention.avoid(:hazard)` |
| `tags: ["slow"]` | `metadata: { cost: 2.0 }` | Increases BFS distance |
| `Identifier: "Wall"` | `tile_data: :collision` | Unreachable (Graph broken here) |

### 2. Entities of Interest (Dynamic Entities)
Entities that the agent can interact with or that serve as objectives.

| LDtk Attribute | Meaning in World | Usage in Tactics |
| :--- | :--- | :--- |
| `Identifier: "Target"` | `World.entities(type: :target)` | Used by `Intention.reach(x, y)` |
| `fields: { power: 10 }` | `Entity.fields[:power]` | Used for custom heuristics |

## Mapping Best Practices

1.  **Semantics over Identity**: Don't map "NPC_01"; map "Actor" with "Team: Enemy".
2.  **Versioning**: Always include `world.version` in the context to ensure the mind does not act on an old map after a hot-reload.
3.  **Standardized Tags**: Use a fixed set of tags (`hazard`, `walkable`, `goal`) so that the `SpatialAnalyzer` remains consistent.
