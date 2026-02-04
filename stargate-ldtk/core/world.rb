module StargateLDtk
  module Core
    # World is a pure data container.
    # It must NOT:
    # - infer meaning from data
    # - mutate internal state
    # - depend on external formats
    # - manage its own versioning
    #
    # #0003
    class World
      attr_reader :id, :layout, :grids, :entities, :metadata, :version

      def initialize(id:, layout:, grids: [], entities: [], metadata: {}, version: 0)
        @id = id
        @layout = layout # { px_width:, px_height:, width:, height: }
        @grids = grids
        @entities = entities
        @metadata = metadata
        @version = version
      end

      def to_h
        {
          id: @id,
          layout: @layout,
          grids: @grids.map(&:to_h),
          entities: @entities.map(&:to_h),
          metadata: @metadata,
          version: @version
        }
      end

      def inspect
        "#<StargateLDtk::Core::World id:#{@id} v:#{@version} grids:#{@grids.size} entities:#{@entities.size}>"
      end
    end

    # --- PUBLIC API ---
    class Grid
      attr_reader :identifier, :size, :data, :visual_data, :tileset_path, :tileset_height, :grid_size

      def initialize(identifier:, size:, data:, visual_data: [], tileset_path: nil, tileset_height: 0, grid_size: 16)
        @identifier = identifier
        @size = size # { cols:, rows: }
        @data = data # Flat array of IDs/Values
        @visual_data = visual_data
        @tileset_path = tileset_path
        @tileset_height = tileset_height
        @grid_size = grid_size
      end

      def to_h
        { identifier: @identifier, size: @size, data: @data, visual_data: @visual_data }
      end

      def inspect
        "#<StargateLDtk::Core::Grid #{@identifier} (#{@size[:cols]}x#{@size[:rows]}) visual_tiles:#{@visual_data.size}>"
      end
    end

    # --- PUBLIC API ---
    class Entity
      attr_reader :id, :type, :pos, :fields, :tile

      def initialize(id:, type:, pos:, fields: {}, tile: nil)
        @id = id
        @type = type
        @pos = pos # { x:, y:, grid_x:, grid_y: }
        @fields = fields
        @tile = tile # { tileset_uid:, x:, y:, w:, h: }
      end

      def to_h
        { id: @id, type: @type, pos: @pos, fields: @fields }
      end

      def inspect
        "#<StargateLDtk::Core::Entity #{@type} (#{@pos[:x]},#{@pos[:y]})>"
      end
    end
  end
end
