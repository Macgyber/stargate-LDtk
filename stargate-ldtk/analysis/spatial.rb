module StargateLDtk
  module Analysis
    # #0051
    class Spatial
      def self.analyze(world, config = {})
        return nil unless world

        # #0058
        validate_world!(world)

        # #0059
        contract = SemanticSpecification.new(config[:mapping] || { 0 => :empty })

        # #0060
        grid_id = config[:collision_grid] || "Collision"
        collision_grid = world.grids.find { |g| g.identifier == grid_id }
        
        # #0053
        raise "Spatial Analysis Error: Grid '#{grid_id}' not found in World." unless collision_grid
        
        # #0061
        topology = extract_topology(collision_grid, contract)

        # #0054
        LogicalMap.new(
          world: world,
          topology: topology,
          contract: contract
        )
      end

      private

      # #0058
      def self.validate_world!(world)
        world.grids.each do |grid|
          expected_size = grid.size[:cols] * grid.size[:rows]
          if grid.data.size != expected_size
            raise "Error: Grid '#{grid.identifier}' size mismatch. Expected #{expected_size}, got #{grid.data.size}."
          end
        end
      end

      # #0061
      def self.extract_topology(grid, contract)
        grid.data.map { |v| contract.tag_for(v) }
      end
    end

    # #0052
    class SemanticSpecification
      attr_reader :mapping

      def initialize(mapping)
        @mapping = mapping
      end

      # #0052
      def tag_for(value)
        @mapping[value] || :blocked
      end

      def to_h
        @mapping
      end
    end

    # #0054
    class LogicalMap
      attr_reader :world_id, :world_version, :layout, :contract

      def initialize(world:, topology:, contract:)
        @world_id = world.id
        @world_version = world.version
        @layout = world.layout
        @topology = topology
        @contract = contract
        @entities = world.entities
        
        # #0055
        build_spatial_index!
      end

      # #0054
      def has_tag?(gx, gy, tag)
        tag_at(gx, gy) == tag
      end

      # #0054
      def tag_at(gx, gy)
        return :out_of_bounds if gx < 0 || gy < 0 || gx >= @layout[:width] || gy >= @layout[:height]
        @topology[gy * @layout[:width] + gx]
      end

      # #0054
      def walkable?(gx, gy)
        tag_at(gx, gy) == :empty
      end

      # #0055
      def entities_at(gx, gy)
        @spatial_index[[gx, gy]] || []
      end

      # #0056
      def distance(x1, y1, x2, y2)
        queue = [[x1, y1, 0]]
        visited = { [x1, y1] => true }
        
        while !queue.empty?
          cx, cy, d = queue.shift
          return d if cx == x2 && cy == y2
          
          neighbors(cx, cy).each do |n|
            next if visited[[n[:x], n[:y]]]
            next unless walkable?(n[:x], n[:y])
            
            visited[[n[:x], n[:y]]] = true
            queue << [n[:x], n[:y], d + 1]
          end
        end
        
        9999
      end

      # #0054
      def find_entities(type)
        @entities.select { |e| e.type == type }
      end

      # #0057
      def neighbors(gx, gy)
        [[0, 1], [0, -1], [1, 0], [-1, 0]].map do |dx, dy|
          nx, ny = gx + dx, gy + dy
          next nil if nx < 0 || ny < 0 || nx >= @layout[:width] || ny >= @layout[:height]
          { x: nx, y: ny, tag: tag_at(nx, ny) }
        end.compact
      end

      # #0054
      def to_h
        {
          world_id: @world_id,
          world_version: @world_version,
          layout: @layout,
          contract: @contract.to_h,
          topology_summary: {
            size: @topology.size,
            tags: @topology.uniq
          },
          entity_count: @entities.size
        }
      end

      # #0054
      def inspect
        "#<StargateLDtk::Analysis::LogicalMap world:#{@world_id} v:#{@world_version} (#{@layout[:width]}x#{@layout[:height]})>"
      end

      private

      # #0055
      def build_spatial_index!
        @spatial_index = {}
        @entities.each do |e|
          gx = e.pos[:grid_x]
          gy = e.pos[:grid_y]
          @spatial_index[[gx, gy]] ||= []
          @spatial_index[[gx, gy]] << e
        end
      end
    end
  end
end
