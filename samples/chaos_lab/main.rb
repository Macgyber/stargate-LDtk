# Stargateldtk Sample: Chaos Tactics Lab (Single File)
# --------------------------------------------------
# To run this sample from the DragonRuby root:
# 1. Ensure 'lib/stargateldtk' is present.
# 2. Copy this file to 'mygame/app/main.rb'.
# 3. Copy assets and data to the corresponding folders.

# #0001
require "lib/stargateldtk/bootstrap.rb"

# --- UTILIDAD: Hot Reload ---
# #0201
class HotReloadService
  def initialize(args, path)
    @path = path
    args.state.sync_data ||= { mtime: 0, hash: 0 }
  end

  def changed?(args)
    data = args.state.sync_data
    st = args.gtk.stat_file(@path)
    new_mtime = (st && st.mtime) ? st.mtime : 0
    if new_mtime > 0 && new_mtime != data[:mtime]
      data[:mtime] = new_mtime
      return true
    end
    raw = args.gtk.read_file(@path)
    return false unless raw
    new_hash = raw.hash
    if new_hash != data[:hash]
      data[:hash] = new_hash
      return true
    end
    false
  end
end

# --- LÓGICA: Chaos Tactics Lab ---
class ChaosTacticsLab
  def initialize(args)
    @map_file = "lib/stargateldtk/samples/chaos_lab/data/world.ldtk"
    @world = nil
    @map = nil
    @adapter = nil
    @player = { x: 5, y: 5 }
    @visual_pos = { x: 5.0, y: 5.0 } # Smoothing (Lerp)
    @move_cooldown = 0
    
    @zoom = 4.0
    @gs = 32
    @cam_x = 0
    @cam_y = 0
    
    @world_v = args.state.world_version || 0
    @sync_status = "Scanning..."
    
    load_and_analyze(args)
    spawn_player
    
    if @world
      wh_scaled = @world.layout[:px_height] * @zoom
      @cam_x = (@player[:x] * @gs) - 640
      @cam_y = (wh_scaled - (@player[:y] * @gs) - @gs) - 360
    end
  end

  def tick(args)
    handle_input(args)
    update_visuals(args)
    update_camera(args)
    render(args)
  end

  private

  def load_and_analyze(args)
    @last_raw = args.gtk.read_file(@map_file)
    return if @last_raw.nil?

    begin
      json = args.gtk.parse_json(@last_raw)
      # #0002
      @world = Stargateldtk::Core::Loader.load(args, json, version: @world_v)
      # #0051
      @map = Stargateldtk::Analysis::Spatial.analyze(@world, { 
        collision_grid: "IntGrid_layer",
        mapping: { 0 => :empty, 1 => :hazard } 
      })
      # #0251
      @adapter = Stargateldtk::Adapters::LDtkToDragonRuby.new(@world)
      @sync_status = "LIVE: #{@world.layout[:width]}x#{@world.layout[:height]} (v#{@world_v})"
    rescue => e
      @sync_status = "ERROR: #{e.message}"
    end
  end

  def spawn_player
    return unless @map && @world
    return if @map.walkable?(@player[:x], @player[:y])
    h = @world.layout[:height].to_i
    w = @world.layout[:width].to_i
    h.times do |gy|
      w.times do |gx|
        if @map.walkable?(gx, gy)
          @player[:x], @player[:y] = gx, gy
          @visual_pos[:x], @visual_pos[:y] = gx.to_f, gy.to_f
          return
        end
      end
    end
  end

  def handle_input(args)
    return unless @map
    @move_cooldown -= 1 if @move_cooldown > 0
    return if @move_cooldown > 0
    
    dx, dy = 0, 0
    k = args.inputs.keyboard
    dx = -1 if k.left
    dx = 1  if k.right
    dy = -1 if k.up
    dy = 1  if k.down
    
    if dx != 0 || dy != 0
      nx, ny = @player[:x] + dx, @player[:y] + dy
      if @map.walkable?(nx, ny)
        @player[:x], @player[:y] = nx, ny
        @move_cooldown = 6
      end
    end

    if args.inputs.keyboard.key_down.r
      @world_v += 1
      load_and_analyze(args)
      spawn_player
    end
  end

  def update_visuals(args)
    @visual_pos[:x] += (@player[:x] - @visual_pos[:x]) * 0.1
    @visual_pos[:y] += (@player[:y] - @visual_pos[:y]) * 0.1
  end

  def update_camera(args)
    return unless @world
    wh_scaled = @world.layout[:px_height] * @zoom
    target_x = (@visual_pos[:x] * @gs) + (@gs/2) - 640
    target_y = (wh_scaled - (@visual_pos[:y] * @gs) - @gs) + (@gs/2) - 360
    @cam_x += (target_x - @cam_x) * 0.05
    @cam_y += (target_y - @cam_y) * 0.05
  end

  def render(args)
    args.outputs.background_color = [15, 15, 25]
    unless @world && @adapter
      args.outputs.labels << { x: 640, y: 360, text: "MAP NOT FOUND: #{@map_file}", alignment_enum: 1, r: 255 }
      return
    end
    
    wh_scaled = @world.layout[:px_height] * @zoom
    ox, oy = -@cam_x, -@cam_y

    @world.grids.reverse_each do |grid|
      next if grid.visual_data.empty?
      grid.visual_data.each do |tile|
        args.outputs.sprites << {
          x: ox + (tile[:px][0] * @zoom),
          y: oy + (wh_scaled - (tile[:px][1] * @zoom) - @gs),
          w: @gs, h: @gs,
          path: "lib/stargateldtk/samples/chaos_lab/assets/cavernas.png",
          source_x: tile[:src][0],
          # #0253
          source_y: @adapter.source_y(256, tile[:src][1], 8),
          source_w: 8, source_h: 8
        }
      end
    end
    
    args.outputs.sprites << {
      x: ox + (@visual_pos[:x] * @gs),
      y: oy + (wh_scaled - (@visual_pos[:y] * @gs) - @gs),
      w: @gs, h: @gs,
      path: "lib/stargateldtk/samples/chaos_lab/assets/player/green.png"
    }
    
    args.outputs.labels << { x: 30, y: 700, text: "CHAOS TACTICS LAB (v#{@world_v})", r: 255, g: 255, b: 255 }
    args.outputs.labels << { x: 30, y: 680, text: "Status: #{@sync_status}", size_enum: -2, r: 150, g: 250, b: 150 }
  end
end

# --- CORE TICK ---
def tick args
  # HotReload synchronization for this sample
  args.state.sync ||= HotReloadService.new(args, "lib/stargateldtk/samples/chaos_lab/data/world.ldtk")

  if args.state.sync.changed?(args)
    args.state.lab = nil
  end

  args.state.lab ||= ChaosTacticsLab.new(args)
  args.state.lab.tick(args)
end
