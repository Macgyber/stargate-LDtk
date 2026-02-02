# Hot-Reload Technical Report: Stargateldtk

## Introduction
Hot-reloading in **Stargateldtk** allows for deep structural changes to levels without restarting the game. This report details the technical implementation of versioning and cache invalidation.

## Technical Implementation

### 1. The Versioned Loader (#0003)
The `Loader` injects a unique, incremental version number into every `World` object. 
- **Atoms**: The `version` is a primitive integer.
- **Trigger**: Any JSON parse event resulting in a new structure increments this value.

### 2. Derived Invalidation
The `LogicalMap` and `WorldRenderer` use this version to decide whether to recompute their internal structures.
```ruby
# LogicalMap invalidation logic
return if current_map.world_version == world.version
```

## Consistency Guarantees
- **Data Safety**: Since the `World` is immutable, active calculations aren't corrupted by the reload. The system simply starts using the new version in the next frame.
- **Auditability**: Nodal logs (#0177) track which decision was made with which map version.

## Limitations
- **Entities**: Hot-reloading entities requires a persistent `iid` (Instance ID) to maintain state (like HP) across reloads.
- **Topology**: Changing tile meanings in the `SemanticSpecification` requires a full re-analysis of the `World`.
