# Stargateldtk: Spatial Analysis

This document details the functioning of the **Stargateldtk** spatial analyzer. The system interprets map data and facilitates information queries.

## ⚖️ Rules

### 1. Semantic Specification
The analyzer does not assume arbitrary meanings. Data meaning is declared via a `SemanticSpecification`.
- **Default**: If no configuration is provided, the system assumes `{ 0 => :empty }` and marks everything else as `:blocked`.
- **Extensibility**: You can map any LDtk value to logical tags such as `:water`, `:lava`, `:platform`, etc.

### 2. Structural Integrity (Hard Validation)
To prevent failures, the `SpatialAnalyzer` validates that data size matches the layout dimensions (`width * height`). Any discrepancy raises an error.

### 3. Data Indexing
The `LogicalMap` organizes information for efficient querying:
- **Spatial Index**: Entities are automatically indexed by grid cell (`grid_x`, `grid_y`).
- **Topology**: The map exposes its `neighbors`, allowing algorithms like A* to function over a pure graph structure without knowing engine details.

---

## 🛠️ Usage Examples

### Defining a Custom Semantic Specification:
```ruby
config = {
  collision_grid: "Physics", # LDtk layer name
  mapping: {
    0 => :empty,
    1 => :solid,
    2 => :hazard,
    3 => :ladder
  }
}

map = Stargateldtk::Analysis::Spatial.analyze(world, config)
```

### Smart Queries:
```ruby
# Query logical tags
if map.has_tag?(10, 5, :hazard)
  # Player is in danger
end

# Query entities in a specific cell (O(1))
enemies = map.entities_at(10, 5).select { |e| e.type == "Enemy" }

# Get neighbors for pathfinding
neighbors = map.neighbors(current_x, current_y).select { |n| n.tag == :empty }
```

### Observability:
The `LogicalMap` is fully observable. You can inspect it in the console or serialize it:
```ruby
puts map.inspect # => #<Stargateldtk::Analysis::LogicalMap world:123 v:1 (20x15)>
args.gtk.write_file("map_debug.json", map.to_h.to_json)
```
