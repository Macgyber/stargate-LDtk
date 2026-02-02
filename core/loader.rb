module Stargateldtk
  module Core
    # #0002
    class Loader
      def self.load(args, ldtk_json, version: 0)
        levels = ldtk_json["levels"] || []
        level = levels[0] # Phoenix MVP: Single level focus
        return nil unless level

        # #0004
        first_layer = (level["layerInstances"] || []).first
        gsize = (first_layer ? first_layer["__gridSize"] : (ldtk_json["defaultGridSize"] || 16)).to_i

        # #0005
        layout = {
          px_width:  level["pxWid"].to_i,
          px_height: level["pxHei"].to_i,
          width:     (level["pxWid"].to_i / gsize).to_i,
          height:    (level["pxHei"].to_i / gsize).to_i,
          tile_size: gsize
        }

        # #0006
        grids = []
        entities = []
        (level["layerInstances"] || []).each do |layer|
          if layer["__type"] == "Entities"
            layer["entityInstances"].each do |e|
              # #0007
              entities << Entity.new(
                id: e["iid"],
                type: e["__identifier"],
                pos: { 
                  x: e["px"][0], 
                  y: e["px"][1],
                  grid_x: e["__grid"][0], 
                  grid_y: e["__grid"][1] 
                },
                fields: extract_fields(e["fieldInstances"])
              )
            end
          else
            # #0008
            visual_tiles = (layer["autoLayerTiles"] || layer["gridTiles"] || []).map do |t|
              { px: t["px"], src: t["src"], f: t["f"], t: t["t"] }
            end

            grids << Grid.new(
              identifier: layer["__identifier"],
              size: { cols: layer["__cWid"], rows: layer["__cHei"] },
              data: layer["intGridCsv"] || [],
              visual_data: visual_tiles
            )
          end
        end

        # #0009
        World.new(
          id: level["iid"],
          layout: layout,
          grids: grids,
          entities: entities,
          metadata: { 
            bg_color: level["__bgColor"], 
            toc: ldtk_json["toc"] || [] 
          },
          version: version
        )
      end

      private

      def self.extract_fields(field_instances)
        fields = {}
        (field_instances || []).each { |f| fields[f["__identifier"]] = f["__value"] }
        fields
      end
    end
  end
end
