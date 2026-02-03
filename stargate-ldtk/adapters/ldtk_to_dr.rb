module StargateLDtk
  module Adapters
    # #0251
    class LDtkToDragonRuby
      attr_reader :world
      
      def initialize(world)
        @world = world
      end

      # #0252
      def screen_y(ldtk_py, object_h, offset_y = 0)
        offset_y + @world.layout[:px_height] - ldtk_py - object_h
      end

      # #0252
      def grid_y_to_screen(gy, grid_size, offset_y = 0)
        screen_y(gy * grid_size, grid_size, offset_y)
      end

      # #0253
      def source_y(atlas_h, ldtk_src_y, tile_h)
        atlas_h - ldtk_src_y - tile_h
      end
    end
  end
end
