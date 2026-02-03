module StargateLDtk
  module Tactics
    # #0153
    module Temporal
      # #0157
      def self.evaluate(map, composite, cand_node, context, horizon: 2, gamma: 0.5)
        frontier = [[cand_node[:x], cand_node[:y], 1]]
        max_future_score = -1.0
        can_survive = false
        veto_reasons = []

        # #0158
        visit_queue = frontier
        visited = { [cand_node[:x], cand_node[:y]] => true }

        while !visit_queue.empty?
          cx, cy, d = visit_queue.shift
          
          node = { x: cx, y: cy, tag: map.tag_at(cx, cy) }
          
          if d >= horizon
            if has_safe_out?(map, composite, node)
              can_survive = true
              score = score_state(map, composite, node, context)
              max_future_score = [max_future_score, score].max
            end
            next
          end

          # #0160
          map.neighbors(cx, cy).each do |n|
            next if visited[[n[:x], n[:y]]]
            
            is_vetoed = composite.intentions.any? do |i|
              i[:kind] == :constraint && map.has_tag?(n[:x], n[:y], i[:intent].payload[:tag])
            end
            
            unless is_vetoed
              visited[[n[:x], n[:y]]] = true
              visit_queue << [n[:x], n[:y], d + 1]
            end
          end
        end

        # #0161
        if !can_survive && horizon > 0
          return [false, 0.0, :causal_veto]
        end

        [true, max_future_score * gamma, nil]
      end

      private

      
      # #0161
  def self.has_safe_out?(map, composite, node)
        candidates = map.neighbors(node[:x], node[:y]) + [node]
        candidates.any? do |c|
          !composite.intentions.any? do |i|
            i[:kind] == :constraint && map.has_tag?(c[:x], c[:y], i[:intent].payload[:tag])
          end
        end
      end

      
      # #0162
  def self.score_state(map, composite, node, context)
        total = 0.0
        heuristics = composite.intentions.select { |i| i[:kind] == :heuristic }
        return 0.0 if heuristics.empty?

        heuristics.each do |h|
          intent = h[:intent]
          case intent.type
          when :reach
            target = intent.payload
            dist = map.distance(node[:x], node[:y], target[:x], target[:y])
            current_dist = map.distance(context[:x], context[:y], target[:x], target[:y])
            
            if dist < current_dist
              total += 1.0 * (h[:weight] || 1.0)
            elsif dist == current_dist
              total += 0.0
            else
              total -= 1.0 * (h[:weight] || 1.0)
            end
          end
        end
        total / heuristics.size
      end
    end
  end
end
