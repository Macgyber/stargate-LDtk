module Stargateldtk
  module Core
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
        "#<Stargateldtk::Core::World id:#{@id} v:#{@version} grids:#{@grids.size} entities:#{@entities.size}>"
      end

      def next_version(updates = {})
        World.new(
          id: updates[:id] || @id,
          layout: updates[:layout] || @layout,
          grids: updates[:grids] || @grids,
          entities: updates[:entities] || @entities,
          metadata: updates[:metadata] || @metadata,
          version: @version + 1
        )
      end
    end

    # --- PUBLIC API ---
    class Grid
      attr_reader :identifier, :size, :data, :visual_data

      def initialize(identifier:, size:, data:, visual_data: [])
        @identifier = identifier
        @size = size # { cols:, rows: }
        @data = data # Flat array of IDs/Values
        @visual_data = visual_data
      end

      def to_h
        { identifier: @identifier, size: @size, data: @data, visual_data: @visual_data }
      end

      def inspect
        "#<Stargateldtk::Core::Grid #{@identifier} (#{@size[:cols]}x#{@size[:rows]}) visual_tiles:#{@visual_data.size}>"
      end
    end

    # --- PUBLIC API ---
    class Entity
      attr_reader :id, :type, :pos, :fields

      def initialize(id:, type:, pos:, fields: {})
        @id = id
        @type = type
        @pos = pos # { x:, y:, grid_x:, grid_y: }
        @fields = fields
      end

      def to_h
        { id: @id, type: @type, pos: @pos, fields: @fields }
      end

      def inspect
        "#<Stargateldtk::Core::Entity #{@type} (#{@pos[:x]},#{@pos[:y]})>"
      end
    end
  end
end
