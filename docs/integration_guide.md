# Stargateldtk: Integration Guide

This guide is designed for developers looking for a technical implementation of LDtk and DragonRuby integration.

---

## 1. Coordinate System Management (Y-Mapping) ⚖️

A central technical consideration for this project is the difference between spatial systems:

- **LDtk**: Uses a **Y-Down** system (0 is top). This is standard in map editing tools.
- **DragonRuby**: Uses a **Y-Up** system (0 is bottom). This is standard in game engines following Cartesian plane math.

### The Solution: The Adapter
To save you from thinking about this every time you draw, the runtime includes an `LDtkToDragonRuby` adapter:

```ruby
# Example usage in the renderer
# Inverts the Y axis for the screen
sx = tile[:px][0]
sy = adapter.screen_y(tile[:px][1], 8) # (LDtk_py, tile_height)

# Inverts the Y axis for the Spritesheet (Texture)
src_y = adapter.source_y(atlas_h, tile[:src][1], 8)
```

> [!IMPORTANT]
> Never calculate Y manually in the render loop. Use the adapter to guarantee your world looks the same as in the LDtk editor.

---

## 2. Grid-Based Movement (Interpolation)

By default, a grid-based engine tends to look "choppy" because the player teleports from one square to another. To achieve a fluid feel without breaking mathematical logic, we implement **State Separation**:

1. **Logical State**: The player is on grid `(x: 5, y: 5)`. Determines collisions and AI.
2. **Visual State**: The player has a floating position `(x: 5.23, y: 5.0)`. This is what the eye sees.

### Example Code (Lerp)
```ruby
def update_visuals(args)
  # Linear Interpolation (LERP)
  # The sprite chases the logical position at a rate of 20% per frame.
  @visual_pos[:x] += (@player[:x] - @visual_pos[:x]) * 0.2
  @visual_pos[:y] += (@player[:y] - @visual_pos[:y]) * 0.2
end
```

---

## 3. FAQ ❓

### Why isn't my Hot-Reload working?
DragonRuby is very sensitive to paths. Ensure your `.ldtk` files are inside the `mygame/worlds/` folder. If they are outside, the engine will not be able to track changes in real time.

### How do I check if a wall is walkable?
Don't ask the sprites; ask the `LogicalMap`:
```ruby
if map.walkable?(gx, gy)
  # Move
end
```

### Is my game screen black?
Check two things:
1. That the `Loader` returned a `World` object.
2. That your camera is centered. In the Lab we use:
   `target_x = (@visual_pos[:x] * grid_size) - 640`