# 🌌 STARGATE RECONSTRUCTION LAYER
# Protocol: Stargate-LLM-IA
# Objective: Restore causality for missing Interprete and pulse methods.
# -----------------------------------------------------------------------------

module Interprete
  @sprites = {}

  def self.register_sprites(config)
    @sprites = config
  end

  def self.sprite_config(type)
    @sprites[type] || {}
  end

  def self.screen_pos(x, y, zoom, cam_x, cam_y)
    # Bus Semántico: Obtenemos el alto total para el flip Y
    alto_mundo = ($args.state.ldtk.world.px_height || 0) * zoom
    
    # Proyecto de coordenadas de mundo a pantalla (Flipped Y for LDtk -> DR)
    # Formula: (alto_total - y_scaled) - cam_y
    [(x * zoom) - cam_x, (alto_mundo - (y * zoom)) - cam_y]
  end

  def self.wall?(level_data, x, y)
    # Puente de colisión al Bridge
    StargateLDtk::Bridge.wall?(x, y)
  end
end

module StargateLDTK
  def self.pulse(args)
    # Orquestación del Bridge para mantener el contrato de main.rb
    # Asumimos el mapa por defecto o el que esté configurado
    @bridge ||= StargateLDtk::Bridge
    unless @booted
      @bridge.run(map: "maps/sample.ldtk") # Fallback mapping
      @booted = true
    end

    @bridge.tick(args)

    world = @bridge.instance_variable_get(:@world)
    return {} unless world

    {
      entities: world.entities.map { |e| 
        { 
          type: e.type, 
          x: e.pos[:x], 
          y: world.layout[:px_height] - e.pos[:y] - 16,
          flip_h: false 
        } 
      },
      zoom: @bridge.instance_variable_get(:@zoom) || 1.0,
      camera_x: @bridge.instance_variable_get(:@cam_x) || 0,
      camera_y: @bridge.instance_variable_get(:@cam_y) || 0
    }
  end

  def self.render_world(args)
    StargateLDtk::Bridge.render_mundo(args)
  end

  def self.render_ui(args)
    # UI rendering if needed
  end
end

puts "🩹 [RECONSTRUCTION] Causal aliases established: Interprete, StargateLDTK."
