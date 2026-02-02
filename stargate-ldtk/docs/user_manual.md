# User Manual: Stargateldtk v1.0 📘

This manual describes how to integrate and operate the **Stargateldtk** runtime in your DragonRuby project.

---

## 1. Installation and Setup

Copy the `lib/stargateldtk` folder into your DragonRuby project's `lib/` directory.

In your `app/main.rb`, load the necessary components:

```ruby
require "lib/stargateldtk/bootstrap.rb"
```

---

## 2. Lifecycle

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
  
  args.state.logical_map = Stargateldtk::Analysis::Spatial.analyze(args.state.world)
end
```

### C. Passive Rendering
The renderer draws based exclusively on `World` data.

```ruby
def tick(args)
  # ... loading and analysis logic ...
  
  # The renderer does not make decisions; it only observes.
  camera = { x: args.state.player.x, y: args.state.player.y, zoom: 3.0 }
  Stargateldtk::Render::WorldRenderer.draw(args, args.state.world, camera)
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
*   **Do collisions not match up?**: Ensure your LDtk layer is named exactly "Collision" (or adjust the Analyzer).
*   **Can't see my entities?**: Check if the Renderer has a debug configuration for the entity type you created.

---

## 7. DragonRuby Notes (Rendering Gotchas)

The Core is **headless** and provides data in native LDtk coordinates (Y-down). When rendering in DragonRuby, keep in mind its **Y-up** coordinate system:

- **Screen Y**: `pos_y = offset_y + world_px_height - (ldtk_px_y) - tile_size`
- **Texture Y**: DragonRuby reads textures from bottom to top.
  - `source_y = atlas_height - ldtk_src_y - tile_size`

> [!IMPORTANT]
> If you don't invert the Y axis when reading the spritesheet, the wrong tiles will be drawn.
