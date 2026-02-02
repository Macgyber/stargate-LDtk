module Stargateldtk
  module Render
    # #0101
    class WorldRenderer
      def self.draw(args, world, camera = nil)
        return unless world
        
        # #0102
        args.outputs.primitives << { 
          x: 0, y: 0, w: 1280, h: 720, 
          r: 0, g: 0, b: 0, 
          primitive_marker: :solid 
        }

        # #0103
        cam_x = camera ? camera[:x] : 0
        cam_y = camera ? camera[:y] : 0
        zoom  = camera ? camera[:zoom] : 1.0

        # #0104
        world.grids.each { |grid| draw_debug_grid(args, grid, zoom, cam_x, cam_y) }
        world.entities.each { |entity| draw_entity(args, entity, zoom, cam_x, cam_y) }
      end

      private

      # #0106
      def self.draw_debug_grid(args, grid, zoom, cam_x, cam_y)
        # Placeholder for tile rendering.
      end

      # #0105
      def self.draw_entity(args, entity, zoom, cam_x, cam_y)
        sx = (entity.pos[:x] - cam_x) * zoom + 640
        sy = 360 - (entity.pos[:y] - cam_y) * zoom
        
        args.outputs.primitives << { 
          x: sx, y: sy, w: 16 * zoom, h: 16 * zoom, 
          r: 200, g: 200, b: 255, 
          primitive_marker: :solid 
        }
        
        args.outputs.primitives << { 
          x: sx, y: sy + (20 * zoom), 
          text: entity.type, 
          size_enum: -2, 
          r: 255, g: 255, b: 255, 
          primitive_marker: :label 
        }
      end
    end
  end
end
