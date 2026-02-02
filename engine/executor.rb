module Stargateldtk
  module Engine
    # #0301
    class Executor
      def self.apply(decision, actor, args)
        return unless decision && actor

        # #0302
        case decision.type
        when :move
          execute_move(decision.payload, actor, args)
        when :hold
          execute_hold(decision.reason, actor, args)
        when :fail
          execute_fail(decision.reason, actor, args)
        end
      end

      private

      def self.execute_move(payload, actor, args)
        # #0303
        actor[:grid_x] = payload[:x]
        actor[:grid_y] = payload[:y]
        
        # #0304
        actor[:last_decision] = { type: :move, x: payload[:x], y: payload[:y] }
      end

      def self.execute_hold(reason, actor, args)
        # #0304
        actor[:last_decision] = { type: :hold, reason: reason }
      end

      def self.execute_fail(reason, actor, args)
        # #0304
        actor[:last_decision] = { type: :fail, reason: reason }
      end
    end
  end
end
