module StargateLDtk
  module Tactics
    # #0154
    class Interpreter
      def self.decide(map, intention, context = {})
        return Decision.fail({ rule: :missing_input }) unless map && intention

        # #0177
        if context[:required_version] && map.world_version != context[:required_version]
          return Decision.fail({ 
            rule: :version_mismatch, 
            expected: context[:required_version], 
            actual: map.world_version 
          })
        end

        # #0178
        if intention.is_a?(CompositeIntention)
          arbitrate(map, intention, context)
        else
          solve_single(map, intention, context)
        end
      end

      # #0179
      private

      def self.arbitrate(map, composite, context)
        # #0172
        candidates = map.neighbors(context[:x], context[:y]) + [{ x: context[:x], y: context[:y], tag: map.tag_at(context[:x], context[:y])}]

        # #0173
        vetoed_by = {}
        valid_candidates = candidates.reject do |cand|
          veto = composite.intentions.find do |i|
            i[:kind] == :constraint && violates_constraint?(map, i[:intent], cand, context)
          end
          if veto
            vetoed_by[cand] = veto[:id]
            true
          else
            false
          end
        end

        # #0164
        temporal_scores = {}
        horizon_vetos = {}
        
        valid_candidates = valid_candidates.reject do |cand|
          is_valid, future_score, veto_reason = Temporal.evaluate(map, composite, cand, context)
          if is_valid
            temporal_scores[cand] = future_score
            false
          else
            horizon_vetos[cand] = veto_reason
            true
          end
        end

        # #0180
        if valid_candidates.empty?
          return Decision.hold({ 
            rule: :all_candidates_vetoed_future, 
            vetoed_present: vetoed_by.size,
            vetoed_future: horizon_vetos.size
          })
        end

        # #0165
        scores = {}
        valid_candidates.each do |cand|
          present_score = 0.0
          composite.intentions.select { |i| i[:kind] == :heuristic }.each do |i|
            present_score += score_heuristic(map, i, cand, context) * (i[:weight] || 1.0)
          end
          scores[cand] = present_score + (temporal_scores[cand] || 0.0)
        end

        # #0166
        max_score = scores.values.max
        winners = valid_candidates.select { |cand| scores[cand] == max_score }

        final_winner = winners.size > 1 ? resolve_ties(winners, composite) : winners.first

        if final_winner[:x] == context[:x] && final_winner[:y] == context[:y]
          Decision.hold({ rule: :arbitrated_hold, final_scores: scores.values.uniq })
        else
          Decision.move_to(final_winner[:x], final_winner[:y], {
            rule: :arbitrated_decision,
            voted_by: composite.intentions.map { |i| i[:id] },
            vetoed_count: vetoed_by.size + horizon_vetos.size,
            future_potential: temporal_scores[final_winner],
            final_score: max_score,
            alternatives: winners.size - 1
          })
        end
      end

      # #0167
      def self.violates_constraint?(map, intent, candidate, context)
        case intent.type
        when :avoid
          map.has_tag?(candidate[:x], candidate[:y], intent.payload[:tag])
        else
          false
        end
      end

      # #0168
      def self.score_heuristic(map, config, candidate, context)
        intent = config[:intent]
        case intent.type
        when :reach
          target = intent.payload
          new_dist  = map.distance(candidate[:x], candidate[:y], target[:x], target[:y])
          current_dist = map.distance(context[:x], context[:y], target[:x], target[:y])
          
          if new_dist < current_dist
            return 1.0 
          elsif new_dist == current_dist
            return (candidate[:x] == context[:x] && candidate[:y] == context[:y]) ? -0.1 : 0.0
          else
            return -1.0 
          end
        else
          0.0
        end
      end

      # #0169
      def self.resolve_ties(winners, composite)
        highest_prio_intent = composite.intentions.select { |i| i[:kind] == :heuristic }.max_by { |i| i[:priority] || 0 }
        return winners.first unless highest_prio_intent
        
        winners.first
      end

      # #0170
      def self.solve_single(map, intention, context)
        case intention.type
        when :reach
          solve_reach(map, intention.payload, context)
        when :hold
          Decision.hold({ rule: :intentional_wait })
        else
          Decision.fail({ rule: :unknown_intention, type: intention.type })
        end
      end

      # #0171
      def self.solve_reach(map, payload, context)
        target_x = payload[:x]
        target_y = payload[:y]
        current_x = context[:x]
        current_y = context[:y]

        return Decision.hold({ rule: :already_at_target }) if current_x == target_x && current_y == target_y

        candidates = map.neighbors(current_x, current_y).select do |n|
          map.walkable?(n[:x], n[:y]) && !map.has_tag?(n[:x], n[:y], :hazard)
        end

        if candidates.empty?
          return Decision.hold({ rule: :no_safe_path, status: :blocked })
        end

        next_step = candidates.min_by do |n|
          (n[:x] - target_x).abs + (n[:y] - target_y).abs
        end

        # #0181
        Decision.move_to(next_step[:x], next_step[:y], { 
          rule: :pathfinding_step,
          heuristic: :manhattan,
          avoided: [:hazard],
          distance_to_target: (next_step[:x] - target_x).abs + (next_step[:y] - target_y).abs 
        })
      end
    end
  end
end
