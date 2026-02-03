module StargateLDtk
  module Tactics
    # #0152
    class Decision
      attr_reader :type, :payload, :reason

      def initialize(type:, payload: {}, reason: {})
        @type = type
        @payload = payload
        @reason = reason
      end

      # #0155
      def self.move_to(gx, gy, reason)
        Decision.new(type: :move, payload: { x: gx, y: gy }, reason: reason)
      end

      def self.hold(reason)
        Decision.new(type: :hold, reason: reason)
      end

      def self.fail(reason)
        Decision.new(type: :fail, reason: reason)
      end

      def to_h
        { type: @type, payload: @payload, reason: @reason }
      end

      def inspect
        "#<StargateLDtk::Tactics::Decision type:#{@type} reason:#{@reason[:rule]}>"
      end
    end
  end
end
