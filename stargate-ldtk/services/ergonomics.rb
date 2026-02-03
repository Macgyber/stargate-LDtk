module StargateLDtk
  module Services
    # #0301 - Posición Sagrada (Persistencia de desarrollo)
    class SacredPosition
      PATH = "dev/dev_player_pos.yaml"

      def self.save(player, world_version)
        return unless player
        data = { x: player[:x], y: player[:y], world_version: world_version }
        $gtk.write_file(PATH, $gtk.serialize_state(data))
      end

      def self.load
        raw = $gtk.read_file(PATH)
        return nil unless raw
        $gtk.deserialize_state(raw) rescue nil
      end
    end

    # #0302 - Monitor de Cambios Nativo
    class LiveMonitor
      def initialize(path)
        @path = path
        @last_mtime = get_mtime
      end

      def changed?
        current = get_mtime
        if current > @last_mtime
          @last_mtime = current
          return true
        end
        false
      end

      private

      def get_mtime
        $gtk.ffi_file.mtime(@path).to_i
      end
    end
  end
end
