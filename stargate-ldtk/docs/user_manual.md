# User Manual: StargateLDtk v0.8.0-alpha 📘

This manual describes how to integrate and operate the **StargateLDtk** runtime in your DragonRuby project.

---

## 1. Installation and Setup

Copy the `lib/stargate-LDtk` folder into your DragonRuby project's `lib/` directory.

In your `app/main.rb`, load the library:

```ruby
require "lib/stargate-LDtk/bootstrap.rb"
```

---

## 2. Asset Integration (Spritesheets)

> [!IMPORTANT]
> **Path Matching**: LDtk stores paths to tilesets relative to the project file. When loading in DragonRuby, you must ensure the sprites are present in the `sprites/` directory.

**Tips for Spritesheets**:
1.  **Manual Override**: When rendering, you may need to map the LDtk tileset path to your actual DragonRuby path (e.g., `sprites/tileset.png`).
2.  **Y-Flip**: Remember that LDtk is Y-down and DragonRuby is Y-up. The library includes `Adapters::LDtkToDragonRuby` to help with these conversions.

---

## 3. Ergonomics & Development Flow

### A. Automatic Hot-Reload (Map)
To iterate fast without pressing `Ctrl+R`, use a file monitor in your `tick` loop:

```ruby
# Monitor the .ldtk file modification time
if args.gtk.stat_file("path/to/map.ldtk").mtime > @last_reload
  reload_map!
end
```

### B. Position Persistence (Sacred Position)
To avoid walking through multiple rooms after every reload, implement a persistence service:

```ruby
# Save player grid pos to YAML
$gtk.write_file("dev_pos.yaml", $gtk.serialize_state({x: px, y: py}))

# Load on startup
data = $gtk.deserialize_state($gtk.read_file("dev_pos.yaml"))
player.pos = data if data
```

---

## 4. Lifecycle

To maintain system integrity, data flow is unidirectional.

### A. World Loading
The `Loader` converts an LDtk JSON into a `World` object.

```ruby
def load_world(args, filename)
  raw_json = args.gtk.read_file("app/worlds/#{filename}.json")
  ldtk_json = args.gtk.parse_json(raw_json)
  
  # Produces an immutable pure data object
  args.state.world = Stargateldtk::Core::Loader.load(args, ldtk_json)
end
```

### B. Spatial Analysis
The Analyzer derives a `LogicalMap` from the current version of the `World`.

```ruby
def update_logic(args)
  # Runs when the world changes (or on the first frame)
  return if args.state.logical_map && args.state.logical_map.world_version == args.state.world.version
  
  args.state.logical_map = StargateLDtk::Analysis::Spatial.analyze(args.state.world)
end
```

### C. Passive Rendering
The renderer draws based exclusively on `World` data.

```ruby
def tick(args)
  # ... loading and analysis logic ...
  
  # The renderer does not make decisions; it only observes.
  camera = { x: args.state.player.x, y: args.state.player.y, zoom: 3.0 }
  StargateLDtk::Render::WorldRenderer.draw(args, args.state.world, camera)
end
```

---

## 3. Queries and Reasoning

The `LogicalMap` is where the game's spatial reasoning occurs.

### Walkability Check
```ruby
def can_move_to?(gx, gy)
  # Query the logical map, not sprites.
  args.state.logical_map.walkable?(gx, gy)
end
```

### Entity Access
```ruby
# Get all enemy spawns
spawns = args.state.world.entities.select { |e| e.type == "EnemySpawn" }

spawns.each do |e|
  puts "Enemy at grid: #{e.pos[:grid_x]}, #{e.pos[:grid_y]}"
end
```

---

The `World` contains the **static map configuration**. Changing game state (enemy HP, inventory, etc.) should live in a separate layer, referencing entities by their `iid`.

> [!TIP]
> Do not attempt to mutate the `World` object directly to save game state. Use the `World` to know *where* things are and your own game logic to know *what* is happening to them.

---

1.  **Separation of Logic**: The renderer should not calculate logical states; it should only represent data.
2.  **Loader Usage**: It is recommended to use the official loader to guarantee schema compatibility.
3.  **Observability**: Use `world.version` to track changes in level state.

---

## 6. Troubleshooting

*   **Is my screen grey?**: Check if the JSON is being read correctly. Use `puts args.state.world.id`.
*   **Do collisions not match up?**: Ensure your LDtk layer is named correctly (e.g. "IntGrid_layer") and the `mapping` in `Spatial.analyze` matches.
*   **Can't see my entities?**: Check if your rendering loop is iterating over `world.entities`.

---

## 7. DragonRuby Notes (Rendering Gotchas)

The Core is **headless** and provides data in native LDtk coordinates (Y-down). When rendering in DragonRuby, use `Adapters`:

- **Screen Y**: Use `adapter.screen_y` or `adapter.grid_y_to_screen`.
- **Texture Y**: Use `adapter.source_y` to invert the texture atlas coordinate.

> [!IMPORTANT]
> DragonRuby reads textures from bottom to top. Failing to use `adapter.source_y` results in vertically flipped tiles.
