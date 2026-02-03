# Spatial Analysis Module - Execution Flow

> **Purpose**: This document explains what `analysis/spatial.rb` does, following its execution order.

---

## Overview

**What it does**: Converts a `World` (raw map data) into a `LogicalMap` (queryable spatial intelligence).

**Why it exists**: Games need to ask questions like "Can I walk here?", "What entities are at this position?", "What's the shortest path?". This module makes those queries possible.

---

## Execution Flow

### #0051: Entry Point - `Spatial.analyze`

**What happens**: This is the main function that converts `World` → `LogicalMap`.

**Input**: 
- `world` - A `World` object from `Loader`
- `config` - Configuration hash (optional)

**Output**: `LogicalMap` object (or `nil` if world is invalid)

**Serialized**:
```ruby
# #0051
class Spatial
  def self.analyze(world, config = {})
    return nil unless world
    # ... validation and processing
  end
end
```

**Why static method**: No state needed. Pure transformation function.

---

### #0058: World Validation

**What happens**: Verifies that all grids have correct data size.

**Why critical**: If a grid says it's 10x10 but has 99 cells, queries will crash or return wrong data.

**Serialized**:
```ruby
# #0058
validate_world!(world)

# Implementation:
def self.validate_world!(world)
  world.grids.each do |grid|
    expected_size = grid.size[:cols] * grid.size[:rows]
    if grid.data.size != expected_size
      raise "Error: Grid '#{grid.identifier}' size mismatch. Expected #{expected_size}, got #{grid.data.size}."
    end
  end
end
```

**Fail-fast**: If data is corrupt, crash immediately with clear error message.

---

### #0059: Semantic Contract Creation

**What happens**: Creates a mapping from raw numbers (0, 1, 2...) to semantic tags (`:empty`, `:solid`, `:water`).

**Why needed**: LDtk stores collision as integers. We need human-readable tags for game logic.

**Serialized**:
```ruby
# #0059
contract = SemanticSpecification.new(config[:mapping] || { 0 => :empty })
```

**Default mapping**: If no mapping provided, assumes `0 = :empty` (walkable).

**Example custom mapping**:
```ruby
{
  0 => :empty,
  1 => :solid,
  2 => :water,
  3 => :lava
}
```

---

### #0060: Collision Grid Selection

**What happens**: Finds the grid that contains walkability data.

**Why configurable**: Different projects name their collision layer differently ("Collision", "Walkable", "Ground", etc.).

**Serialized**:
```ruby
# #0060
grid_id = config[:collision_grid] || "Collision"
collision_grid = world.grids.find { |g| g.identifier == grid_id }
```

**Default**: Looks for a grid named `"Collision"`.

---

### #0053: Grid Existence Validation

**What happens**: Crashes if the specified collision grid doesn't exist.

**Why fail-fast**: Better to crash at load time than silently fail during gameplay.

**Serialized**:
```ruby
# #0053
raise "Spatial Analysis Error: Grid '#{grid_id}' not found in World." unless collision_grid
```

**Error message**: Tells you exactly which grid name it was looking for.

---

### #0061: Topology Extraction

**What happens**: Converts raw integer array into semantic tag array.

**Example**:
- Input: `[0, 0, 1, 0, 1, 1]`
- Contract: `{ 0 => :empty, 1 => :solid }`
- Output: `[:empty, :empty, :solid, :empty, :solid, :solid]`

**Serialized**:
```ruby
# #0061
topology = extract_topology(collision_grid, contract)

# Implementation:
def self.extract_topology(grid, contract)
  grid.data.map { |v| contract.tag_for(v) }
end
```

**Performance**: O(n) where n = number of tiles.

---

### #0054: LogicalMap Construction

**What happens**: Creates the final queryable map object.

**Serialized**:
```ruby
# #0054
LogicalMap.new(
  world: world,
  topology: topology,
  contract: contract
)
```

**What LogicalMap contains**:
- `@world_id` - Which world this map represents
- `@world_version` - Version for cache invalidation
- `@layout` - Dimensions (width, height, tile_size)
- `@topology` - Semantic tag array
- `@contract` - Tag mapping
- `@entities` - All entities from world
- `@spatial_index` - Fast entity lookup by position

---

## LogicalMap Class

### #0052: SemanticSpecification

**What it does**: Maps integers to semantic tags.

**Serialized**:
```ruby
# #0052
class SemanticSpecification
  def initialize(mapping)
    @mapping = mapping # { 0 => :empty, 1 => :solid }
  end

  def tag_for(value)
    @mapping[value] || :blocked # Defensive default
  end
end
```

**Defensive default**: Unknown values become `:blocked` (safe fallback).

---

### #0055: Spatial Index Building

**What happens**: Creates a hash map for fast entity lookup by grid position.

**Why needed**: Finding "all entities at (5, 3)" would be O(n) without index. With index, it's O(1).

**Serialized**:
```ruby
# #0055
def build_spatial_index!
  @spatial_index = {}
  @entities.each do |e|
    gx = e.pos[:grid_x]
    gy = e.pos[:grid_y]
    @spatial_index[[gx, gy]] ||= []
    @spatial_index[[gx, gy]] << e
  end
end
```

**Data structure**: `{ [x, y] => [entity1, entity2, ...] }`

**Usage**:
```ruby
map.entities_at(5, 3) # => [player, chest]
```

---

### #0056: Distance Calculation (BFS)

**What happens**: Finds shortest walkable path distance between two points.

**Algorithm**: Breadth-First Search (BFS) - guarantees shortest path.

**Serialized**:
```ruby
# #0056
def distance(x1, y1, x2, y2)
  queue = [[x1, y1, 0]]
  visited = { [x1, y1] => true }
  
  while !queue.empty?
    cx, cy, d = queue.shift
    return d if cx == x2 && cy == y2
    
    neighbors(cx, cy).each do |n|
      next if visited[[n[:x], n[:y]]]
      next unless walkable?(n[:x], n[:y])
      
      visited[[n[:x], n[:y]]] = true
      queue << [n[:x], n[:y], d + 1]
    end
  end
  
  9999 # Infinity (no path exists)
end
```

**Performance**: O(V + E) where V = tiles, E = edges.

**Returns**: Distance in tiles, or `9999` if unreachable.

---

### #0057: Neighbor Calculation

**What happens**: Returns all valid adjacent tiles (4-directional).

**Serialized**:
```ruby
# #0057
def neighbors(gx, gy)
  [[0, 1], [0, -1], [1, 0], [-1, 0]].map do |dx, dy|
    nx, ny = gx + dx, gy + dy
    next nil if nx < 0 || ny < 0 || nx >= @layout[:width] || ny >= @layout[:height]
    { x: nx, y: ny, tag: tag_at(nx, ny) }
  end.compact
end
```

**Directions**: Up, Down, Right, Left (no diagonals).

**Bounds checking**: Filters out tiles outside map.

---

## Query API

### Core Queries

**`tag_at(gx, gy)`** - What semantic tag is at this position?
```ruby
map.tag_at(5, 3) # => :empty
```

**`walkable?(gx, gy)`** - Can I walk here?
```ruby
map.walkable?(5, 3) # => true
```

**`entities_at(gx, gy)`** - What entities are here?
```ruby
map.entities_at(5, 3) # => [player, chest]
```

**`distance(x1, y1, x2, y2)`** - Shortest path distance?
```ruby
map.distance(0, 0, 5, 5) # => 10
```

**`neighbors(gx, gy)`** - Adjacent tiles?
```ruby
map.neighbors(5, 3) # => [{x: 5, y: 4, tag: :empty}, ...]
```

---

## Design Principles

1. **Immutability**: `LogicalMap` never changes after creation. New world = new map.
2. **Fail-fast**: Invalid data crashes immediately with clear errors.
3. **Defensive defaults**: Unknown values become `:blocked` (safe).
4. **Performance**: Spatial index makes entity queries O(1).
5. **Separation**: Analysis is pure logic. No rendering, no game state.

---

## Usage Example

```ruby
# 1. Load world
world = Loader.load(args, ldtk_json)

# 2. Analyze
map = Spatial.analyze(world, {
  collision_grid: "Collision",
  mapping: { 0 => :empty, 1 => :solid }
})

# 3. Query
if map.walkable?(player_x, player_y)
  # Move player
end

enemies = map.find_entities("Enemy")
distance = map.distance(player_x, player_y, enemy_x, enemy_y)
```

---

**Version**: 0.8.0-alpha  
**Module**: `StargateLDtk::Analysis::Spatial`  
**Dependencies**: `StargateLDtk::Core::World`
