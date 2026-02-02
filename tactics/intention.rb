module Stargateldtk
  module Tactics
    # #0151
    class Intention
      attr_reader :type, :payload

      def initialize(type, payload = {})
        @type = type
        @payload = payload
      end

      def self.reach(gx, gy)
        Intention.new(:reach, { x: gx, y: gy })
      end

      def self.avoid(tag)
        Intention.new(:avoid, { tag: tag })
      end

      def self.hold
        Intention.new(:hold)
      end

      def inspect
        "#<Stargateldtk::Tactics::Intention type:#{@type} payload:#{@payload}>"
      end
    end

    # #0151
    class CompositeIntention
      attr_reader :intentions

      # #0183
      def initialize(intentions = [])
        @intentions = intentions
      end

      def add(id:, kind:, intent:, weight: 1.0, priority: 0)
        @intentions << { id: id, kind: kind, intent: intent, weight: weight, priority: priority }
        self
      end

      def inspect
        "#<Stargateldtk::Tactics::CompositeIntention count:#{@intentions.size}>"
      end
    end
  end
end
