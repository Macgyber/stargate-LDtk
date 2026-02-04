module StargateLDtk
  module Core
    # Loader is LDtk-specific.
    # This is NOT a canonical importer.
    # Output must always be validated before use.
    #
    # #0002
    class Loader
      # LDtk format constants
      ENTITIES_LAYER_TYPE = "Entities"
      LEVELS_KEY = "levels"
      LAYERS_KEY = "layerInstances"
      GRID_DATA_KEY = "intGridCsv"
      DEFAULT_GRID_SIZE = 16

      def self.load(args, ldtk_json, map_path: "", version: 0)
        # Input validation
        raise ArgumentError, "ldtk_json must be a Hash" unless ldtk_json.is_a?(Hash)
        raise ArgumentError, "ldtk_json must have 'levels' key" unless ldtk_json.key?(LEVELS_KEY)
        
        # Determinar base de rutas (relativo al archivo .ldtk)
        base_dir = map_path.include?("/") ? map_path.split("/")[0..-2].join("/") : ""
        base_dir += "/" unless base_dir.empty?

        levels = ldtk_json[LEVELS_KEY] || []
        level = levels[0] # Phoenix MVP: Single level focus
        return nil unless level

        # #0004
        first_layer = (level[LAYERS_KEY] || []).first
        gsize = (first_layer ? first_layer["__gridSize"] : (ldtk_json["defaultGridSize"] || DEFAULT_GRID_SIZE)).to_i

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
        (level[LAYERS_KEY] || []).each do |layer|
          if layer["__type"] == ENTITIES_LAYER_TYPE
            # Validate entityInstances exists
            next unless layer["entityInstances"]
            
            layer["entityInstances"].each do |e|
              # Buscar metadata del tileset para la entidad si tiene tile
              e_tile = nil
              if e["__tile"]
                t_def = (ldtk_json["defs"]["tilesets"] || []).find { |ts| ts["uid"] == e["__tile"]["tilesetUid"] }
                if t_def
                  e_tile = {
                    path: "#{base_dir}#{t_def["relPath"]}",
                    source_x: e["__tile"]["x"],
                    source_y: e["__tile"]["y"], # Se calibrará en el Bridge
                    source_w: e["__tile"]["w"],
                    source_h: e["__tile"]["h"],
                    atlas_h: t_def["pxHei"]
                  }
                end
              end

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
                fields: extract_fields(e["fieldInstances"]),
                tile: e_tile
              )
            end
          else
            # #0008
            visual_tiles = (layer["autoLayerTiles"] || layer["gridTiles"] || []).map do |t|
              { px: t["px"], src: t["src"], f: t["f"], t: t["t"] }
            end

            # Buscar metadata del tileset (Fase 1: Búsqueda lineal en defs)
            t_def = (ldtk_json["defs"]["tilesets"] || []).find { |ts| ts["uid"] == layer["__tilesetDefUid"] }
            t_path = t_def ? t_def["relPath"] : layer["__tilesetRelPath"]
            t_path = "#{base_dir}#{t_path}" if t_path && !t_path.start_with?("/")
            
            t_height = t_def ? t_def["pxHei"] : 0

            grids << Grid.new(
              identifier: layer["__identifier"],
              size: { cols: layer["__cWid"], rows: layer["__cHei"] },
              data: layer[GRID_DATA_KEY] || [],
              visual_data: visual_tiles,
              tileset_path: t_path,
              tileset_height: t_height,
              grid_size: layer["__gridSize"] || DEFAULT_GRID_SIZE
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
