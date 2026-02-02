# Known Limits: Stargate Cognitive Core (v1.x)

This document outlines the known limitations and constraints of the Stargate Cognitive Core.

## 1. Performance Considerations

### Spatial Query Limits
- **O(1) Access**: Entity lookups by grid cell are constant time.
- **Memory Overhead**: Large worlds (e.g., 2000x2000) will consume significant memory due to the expanded logical topology.
- **Initialization**: First-frame analysis for massive levels may cause a frame drop (GC pressure).

## 2. Cognitive Limits (Tactical Mind)

### Temporal Myopia
The current `TemporalHorizon` is limited ($H \leq 3$). The AI cannot plan long-term strategies (e.g., "Find the key in another room"). It only plans for surviving the immediate future.

### Lack of Memory
The `TacticalInterpreter` is stateless frame-to-frame. It does not "remember" past failures. If it gets stuck in an oscillating loop between two equal-priority behaviors, it will continue to oscillate unless a tie-breaker or context flag changes.

### No Global Coordination
Agents do not communicate. If two agents are chasing the same player, they do not coordinate to surround them; they simply react to their individual intentions.

## 3. Data Integrity Rules

### LDtk Versioning
Tested against LDtk 1.3.x+. Major schema changes in future LDtk versions may require an update to the `Core::Loader`.

### Grid Constraints
- The analyzer expects a **uniform grid size**. Layers with different grid sizes (e.g., a 16px layer and an 8px layer) are not yet supported in the same `LogicalMap`.

## 4. Determinism

The system is deterministic provided that:
1. The **Semantic Specification** is constant.
2. The **Entity Translation** logic is pure (no random calls).
3. The **Arbitration Weights** are stable.
