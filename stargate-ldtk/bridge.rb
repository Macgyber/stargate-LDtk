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
      def run(map:, zoom: 3.0)
        @map_path = map
        @zoom = zoom
        @cam_x = 0
        @cam_y = 0
        @error = nil
        
        # Monitor de cambios (Silencioso y humilde)
        @monitor = StargateLDtk::Services::LiveMonitor.new(@map_path)
        
        init_world
        
        # Inyección condicional: Solo si el usuario NO ha definido un tick global.
        unless Object.private_method_defined?(:tick)
          puts "🌉 Bridge: Tomando el control del ciclo de vida (vía inyección)."
          Object.send(:define_method, :tick) do |args|
            StargateLDtk::Bridge.tick(args)
          end
        end
      end

      # El loop interno que DragonRuby llamará por nosotros
      def tick(args)
        handle_hot_reload(args)
        
        return render_error(args) if @error
        return unless @world
        
        actualizar_vision(args)
        render_mundo(args)
      end

      private

      def handle_hot_reload(args)
        # Si el archivo cambió, recargamos el mundo
        if @monitor && @monitor.changed?(args)
          init_world
        end
      end

      def init_world
        # Limpiamos errores previos para permitir "auto-sanado" tras una corrección
        @error = nil
        
        raw = $gtk.read_file(@map_path)
        unless raw
          @error = "No se encontró el archivo del mapa: #{@map_path}"
          return
        end
        
        begin
          # NOTA: Recargar el mundo resetea el estado visual (cámara, etc.).
          # Esto es intencional para mantener el Bridge simple y robusto.
          json = $gtk.parse_json(raw)
          @world = StargateLDtk::Core::Loader.load($args, json, version: 1)
          @adapter = StargateLDtk::Adapters::LDtkToDragonRuby.new(@world)
        rescue => e
          # Error humano en pantalla, error técnico en consola
          @error = "El mapa no pudo cargarse. Revisa que sea un archivo LDtk válido."
          puts "--- ERROR DE LECTURA (Bridge) ---"
          puts e.message
          puts e.backtrace
        end
      end

      def actualizar_vision(args)
        # NOTA: El centrado asume un viewport de 1280x720 (estándar DR).
        ancho_total = @world.layout[:px_width] * @zoom
        alto_total  = @world.layout[:px_height] * @zoom
        @cam_x = (ancho_total / 2) - 640
        @cam_y = (alto_total / 2) - 360
      end

      def render_mundo(args)
        args.outputs.background_color = [20, 20, 30]
        alto_total = @world.layout[:px_height] * @zoom
        ox, oy = -@cam_x, -@cam_y

        @world.grids.reverse_each do |grid|
          # Validación de recursos para evitar fallos silenciosos
          if grid.visual_data && !grid.tileset_path
            @error = "La capa '#{grid.identifier}' no tiene Tileset asociado en LDtk."
            return
          end

          next unless grid.visual_data
          
          grid.visual_data.each do |tile|
            t_size = grid.grid_size * @zoom
            args.outputs.sprites << {
              x: ox + (tile[:px][0] * @zoom),
              y: oy + (alto_total - (tile[:px][1] * @zoom) - t_size),
              w: t_size, h: t_size,
              path: grid.tileset_path,
              source_x: tile[:src][0],
              source_y: @adapter.source_y(grid.tileset_height, tile[:src][1], grid.grid_size),
              source_w: grid.grid_size, source_h: grid.grid_size
            }
          end
        end
      end

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
