# Specification: Spatial Analyzer v1.0

## 1. The Role
The `SpatialAnalyzer` is not a physics engine. It is a **Context Deriver**. Its sole job is to process a `World` (pure data) and produce a `LogicalMap` (information with intention).

## 2. Output: The LogicalMap
Unlike the `World`, which represents the file, the `LogicalMap` is an interpretation of the data for use in game logic.

| Structure | Content |
| :--- | :--- |
| `nav_mesh` | Graph or matrix of walkable cells. |
| `regions` | Areas grouped by tag (e.g., "SafeZone", "Hazard"). |
| `influence` | Heatmaps (proximity to spawns, points of interest). |
| `world_version`| Integer | World version from which these data derive. |
| `queries` | Methods | Data reading (e.g., `walkable?`). |

## 3. Analyzer Rules
1. **Input Purity**: Only reads `World`. Does not read `Input`, `Tick`, or `Random`.
2. **Consistency**: Same World -> Same LogicalMap.
3. **Immutable Structure**: The `LogicalMap` is a snapshot. If the World changes, a new `LogicalMap` is generated.
4. **Causality**: No global reads. Data flows from `World` to `LogicalMap`.
5. **Behavior Purity**: Contains no lambdas or closures. Queries are methods defined on its internal data.
6. **No Side Effects**: Does not modify the `World`. Does not emit game logs. Does not trigger sounds.

## 4. Analysis Stages
1. **Raw Scan**: Reads the `Grids` from the World.
2. **Semantic Filter**: Converts tile IDs into meanings (e.g., "Tile #1" -> "Wall").
3. **Graph Construction**: Generates connections between walkable cells.
4. **Feature Extraction**: Locates and labels points of interest based on Entities.

## 5. Integration Example (Ruby-ish)
```ruby
# LogicalMap is the result of analysis
map = Stargateldtk::Analysis::Spatial.analyze(world)

map.walkable?(gx, gy)     # => Boolean
map.find_region("Hazard") # => [Rect, Rect, ...]
# Structural Pathfinding (not AI, not tactical)
map.distance(gx1, gy1, gx2, gy2) # => Integer
```
