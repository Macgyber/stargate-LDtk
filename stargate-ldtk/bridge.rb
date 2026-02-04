# StargateLDtk::Bridge
# =====================
# "El Puente entre la creación y el runtime"
# Versión: 1.0 (Feature Complete)
#
# CONTRATO DE USO:
# ----------------
# Este módulo es una FACHADA diseñada para eliminar la fricción inicial.
#
# LIMITACIÓN:
# El Bridge soporta un ÚNICO mundo activo. 
# No está diseñado para múltiples llamadas simultáneas a Bridge.run.
#
# SI NECESITAS:
# - Control total sobre el renderizado.
# - Lógica de cámara avanzada o personalizada.
# - Optimización manual profunda.
#
# ENTONCES: No uses este módulo. Usa Core, Analysis y Adapters directamente.
#
# REGLA DE ORO:
# Si el usuario define un método `tick` global, el Bridge se retira y deja
# que el usuario controle el ciclo de vida. Si no, el Bridge toma el control.

module StargateLDtk
  module Bridge
    class << self
      
      # Punto de entrada principal
      def run(map:, zoom: 4.0)
        @map_path = map
        @zoom = zoom
        @current_zoom = zoom # Inicializar zoom actual
        @cam_x = 0
        @cam_y = 0
        @error = nil
        
        @monitor = StargateLDtk::Services::LiveMonitor.new(@map_path)
        
        init_world
      end

      # El "Pulso" del Bridge: Publica estado formal y vocaliza salud.
      def pulse(args)
        handle_hot_reload(args)
        
        # 1. Preparar Bus Semántico (PROTOCOL 0.1.0)
        args.state.ldtk ||= { 
          version: "0.1.0-alpha", 
          status: :loading, 
          diagnostics: [],
          camera: { x: 0, y: 0 },
          world: { px_width: 0, px_height: 0, tile_size: 16 },
          entities: []
        }
        
        return if @error
        unless @world
          args.state.ldtk.status = :error
          return
        end
        
        # 2. Vocalización (Sólo si hay cambios o primer pulso)
        unless @vocalized
          puts "✅ World: [#{@map_path}] cargado con éxito."
          @vocalized = true
        end

        # 3. Actualizar Cámara (Seguimiento del Jugador)
        actualizar_vision(args)

        # 4. Publicación de Datos (Contrato Estricto)
        ldtk = args.state.ldtk
        ldtk.status = :active
        ldtk.camera.x = @cam_x
        ldtk.camera.y = @cam_y
        ldtk.zoom     = @current_zoom || @zoom
        ldtk.world.px_width  = @world.layout[:px_width]
        ldtk.world.px_height = @world.layout[:px_height]
        ldtk.world.tile_size = @world.layout[:tile_size]

        # 5. Sincronización de Entidades (Blueprint -> Living State)
        # Solo inicializamos si el bus está vacío (Primer frame o reset)
        if ldtk.entities.empty? && !@world.entities.empty?
          ldtk.entities = @world.entities.map do |e| 
            { 
              iid: e.id,
              type: e.type, 
              x: e.pos[:x], 
              y: e.pos[:y],
              w: (e.fields["width"] || 16),
              h: (e.fields["height"] || 16),
              fields: e.fields,
              tile: e.tile,
              vx: 0, vy: 0, # Propiedades físicas base
              on_ground: false,
              flip_h: false
            } 
          end
          puts "🛰️  Bridge: #{ldtk.entities.size} entidades transferidas al Bus Semántico."
        end
      end

      # El loop interno (Legacy/Auto-Pilot)
      def tick(args)
        pulse(args)
        
        return render_error(args) if @error
        return unless @world
        
        render_mundo(args)
      end

      def wall?(x, y)
        return false unless @world
        # Buscar la primera capa de IntGrid (convención: la más profunda para muros)
        grid = @world.grids.find { |g| g.data && !g.data.empty? }
        return false unless grid
        
        # Escalar coordenadas a grid (OPERAMOS EN PIXELS DE MUNDO, NO ESCALADOS)
        gx = (x / grid.grid_size).to_i
        gy = (y / grid.grid_size).to_i
        
        return true if gx < 0 || gx >= grid.size[:cols] || gy < 0 || gy >= grid.size[:rows]
        
        # El valor 1 usualmente es "Wall" en nuestras plantillas
        grid.data[gy * grid.size[:cols] + gx] == 1
      end

      # 🌌 RECONSTRUCTION API (Mecánica de Magia)
      # Permite modificar el mundo en tiempo real de forma "invisible"
      def reconstruct_wall(gx, gy, value = 1)
        return unless @world
        grid = @world.grids.find { |g| g.data && !g.data.empty? }
        return unless grid
        
        index = gy * grid.size[:cols] + gx
        if index >= 0 && index < grid.data.size
          grid.data[index] = value
          
          # Si estamos poniendo un muro, también inyectamos un tile visual 
          # para que no sea un muro invisible (usando el tile 1 del atlas)
          if value == 1
            # Evitar duplicados
            px = [gx * grid.grid_size, gy * grid.grid_size]
            unless grid.visual_data.any? { |t| t[:px] == px }
              grid.visual_data << { px: px, src: [0, 0], f: 0, t: 1 }
            end
          end
        end
      end

      private

      def handle_hot_reload(args)
        # Si el archivo cambió, recargamos el mundo
        if @monitor && @monitor.stargate_internal_changed?
          init_world
        end
      end

      def init_world
        # Limpiamos errores previos para permitir "auto-sanado" tras una corrección
        @error = nil
        @vocalized = false # Re-vocalizar al cargar nuevo mundo
        
        raw = $gtk.read_file(@map_path)
        unless raw
          @error = "No se encontró el archivo del mapa: #{@map_path}"
          return
        end
        
        begin
          json = $gtk.parse_json(raw)
          @world = StargateLDtk::Core::Loader.load($args, json, map_path: @map_path, version: 1)
          @adapter = StargateLDtk::Adapters::LDtkToDragonRuby.new(@world)
        rescue => e
          @error = "El mapa no pudo cargarse. Revisa que sea un archivo LDtk válido."
          puts "--- ERROR DE LECTURA (Bridge) ---"
          puts e.message
          puts e.backtrace
        end
      end

      def actualizar_vision(args)
        ldtk = args.state.ldtk
        return unless ldtk && ldtk.status == :active
        
        # 1. DETERMINAR OBJETIVO (Mecánica de 'R' para World View)
        intents = ldtk.intents
        is_world_view = intents && intents.world_view_held
        
        # Objetivo de Zoom (4.0 normal, ajustable para ver mundo completo)
        # Calculamos zoom necesario para ver todo el mundo en 1280x720
        # Evitamos división por cero
        w_px = ldtk.world.px_width > 0 ? ldtk.world.px_width : 1280
        h_px = ldtk.world.px_height > 0 ? ldtk.world.px_height : 720
        
        zoom_fit_x = 1240.0 / w_px
        zoom_fit_y = 680.0 / h_px
        zoom_world = [zoom_fit_x, zoom_fit_y].min
        target_zoom = is_world_view ? zoom_world : @zoom
        
        # Interpolación sutil de zoom para suavidad
        @current_zoom ||= @zoom
        @current_zoom += (target_zoom - @current_zoom) * 0.1
        
        # Dimensiones escaladas actuales
        ancho_mundo = ldtk.world.px_width * @current_zoom
        alto_mundo  = ldtk.world.px_height * @current_zoom
        
        player = ldtk.entities.find { |e| e.type == "PlayerSpawn" }
        
        if is_world_view
          # Centrar el mundo completo
          target_x = (ancho_mundo / 2) - 640
          target_y = (alto_mundo / 2) - 360
        elsif player
          # Centrado absoluto en el player
          target_x = (player.x * @current_zoom) - 640
          target_y = (alto_mundo - (player.y * @current_zoom)) - 360
        else
          target_x = (ancho_mundo / 2) - 640
          target_y = (alto_mundo / 2) - 360
        end

        # Interpolación de posición de cámara para fluidez
        @cam_x += (target_x - @cam_x) * 0.1
        @cam_y += (target_y - @cam_y) * 0.1

        # Actualizar zoom efectivo en el bus para que Visibility se sincronice
        ldtk.zoom = @current_zoom
      end


      def render_mundo(args)
        ldtk = args.state.ldtk
        return unless ldtk && ldtk.status == :active

        args.outputs.background_color = [20, 20, 30]
        # Garantía de zoom inicial para evitar errores matemáticos
        efectivo_zoom = @current_zoom || @zoom || 4.0
        
        alto_total = ldtk.world.px_height * efectivo_zoom
        ox, oy = -ldtk.camera.x, -ldtk.camera.y

        # 1. Renderizar Capas (Grids)
        @world.grids.reverse_each do |grid|
          # Validación de recursos para evitar fallos silenciosos
          if grid.visual_data && !grid.tileset_path
            @error = "La capa '#{grid.identifier}' no tiene Tileset asociado en LDtk."
            return
          end

          next unless grid.visual_data
          
          grid.visual_data.each do |tile|
            t_size = grid.grid_size * efectivo_zoom
            args.outputs.sprites << {
              x: ox + (tile[:px][0] * efectivo_zoom),
              y: oy + (alto_total - (tile[:px][1] * efectivo_zoom) - t_size),
              w: t_size, h: t_size,
              path: grid.tileset_path,
              source_x: tile[:src][0],
              source_y: @adapter.source_y(grid.tileset_height, tile[:src][1], grid.grid_size),
              source_w: grid.grid_size, source_h: grid.grid_size
            }
          end
        end

        # 2. Renderizar Entidades (Basado en el BUS SEMÁNTICO MUTABLE)
        ldtk.entities.each do |ent|
          e_w = ent.w * efectivo_zoom
          e_h = ent.h * efectivo_zoom
          
          # Lógica Visual Especial según Estado Mutante
          r, g, b, a = 255, 255, 255, 255
          if ent.type == "Lever"
            r, g, b = ent.fields["active"] ? [100, 255, 100] : [255, 150, 50]
          elsif ent.type == "Gate"
            if ent.fields["closed"]
               r, g, b = [255, 50, 50]
            else
               r, g, b, a = [100, 100, 255, 120]
            end
          end

          # Selección de Sprite
          path = ent.tile ? ent.tile[:path] : nil
          
          # Fallbacks de Desarrollo
          unless path
            if ent.type == "PlayerSpawn"
              path = "sprites/square/blue.png"
            else
              path = "sprites/square/white.png" # Usamos cuadrado blanco como base universal
              r, g, b = [255, 0, 255] if ent.type != "Lever" && ent.type != "Gate"
            end
          end

          # 2.5 Animación de Flotar (Bobbing) para el Jugador
          y_offset = (ent.type == "PlayerSpawn") ? (Math.sin(args.state.tick_count * 0.1) * 4) : 0

          # 2.6 Construcción de la Primitiva (Renderizado Inteligente)
          # Usamos efectivo_zoom para que todo escale junto
          sprite = {
            x: ox + (ent.x * efectivo_zoom) - (e_w / 2),
            y: oy + (alto_total - (ent.y * efectivo_zoom) - (e_h / 2)) + y_offset,
            w: e_w, h: e_h,
            path: path,
            flip_horizontally: ent.flip_h,
            r: r, g: g, b: b, a: a
          }

          # Solo aplicamos coordenadas de recorte si es un Tile de Tileset
          if ent.tile
            sprite[:source_x] = ent.tile[:source_x]
            sprite[:source_y] = @adapter.source_y(ent.tile[:atlas_h], ent.tile[:source_y], ent.tile[:source_h])
            sprite[:source_w] = ent.tile[:source_w]
            sprite[:source_h] = ent.tile[:source_h]
          end

          args.outputs.sprites << sprite

          # 3. EXTRAS DEL ALMA (Labels de Diálogo sobre Entidades)
          if ent.fields["dialogue"]
            args.outputs.labels << {
              x: ox + (ent.x * efectivo_zoom),
              y: oy + (alto_total - (ent.y * efectivo_zoom) + 10),
              text: ent.fields["dialogue"],
              size_enum: -1, alignment_enum: 1, r: 255, g: 255, b: 255
            }
          end
        end

        # 4. LA RAYA (Permanentemente eliminada)
      end

      # Eliminamos el método render_direccion por completo

      def render_error(args)
        args.outputs.background_color = [30, 0, 0]
        args.outputs.labels << { 
          x: 640, y: 360, text: @error, 
          alignment_enum: 1, r: 255, g: 100, b: 100, size_enum: 2 
        }
        args.outputs.labels << { 
          x: 640, y: 320, text: "Revisa los archivos o consulta la consola para más detalles.", 
          alignment_enum: 1, r: 200, g: 200, b: 200, size_enum: -1 
        }
      end

    end
  end
end

# Inyección condicional del Puente en el Global Tick de DragonRuby.
# Se ejecutará al final del archivo para asegurar que no pisa código del usuario.
# [Pendiente de implementación en la fase de ejecución]
