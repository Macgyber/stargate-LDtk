# Specification: Composite Intentions (v1.x)

## Purpose
The `TacticalInterpreter` resolves conflicts between multiple intentions through a rational arbitration system. The `CompositeIntention` formalizes how multiple desires coexist under a strict set of rules.

## Arbitration Laws

### 1. The Law of Veto (Constraints)
**Constraint** intentions act as binary filters. If an action violates a constraint (e.g., entering a `:hazard` tile), it is immediately discarded.
- **Total Veto**: If all candidates are vetoed, the arbiter **must** return an explicit impossibility decision (`Decision::Hold` or `Decision::Fail` with reason `:all_candidates_vetoed`). The system will never choose the "lesser of two evils."

### 2. The Law of Normalized Scoring (Heuristics)
**Heuristic** intentions award points to surviving candidates.
- **Range**: Scores must be normalized within the `[-1.0, 1.0]` range.
- **Interpretation**: The arbiter is agnostic to the meaning of the number; it only performs weighted aggregation.

### 3. Evaluation Order (Pipeline)
Arbitration follows a fixed execution order:
1.  **Filtering (Constraints)**: Elimination of unviable candidates.
2.  **Aggregation (Heuristics)**: Weighted sum of scores for survivors.
3.  **Tie-Breaking (Priority)**: If two candidates have the same final score, the one favored by the intention with higher priority prevails.

### 4. Identity and Traceability
Each intention within a composite set must have a unique identity for auditing.
- **Mandatory Attributes**: `id` (unique symbol), `kind` (`:constraint` or `:heuristic`), `intent` (Intention object).

## Data Structure (Formal Representation)

```ruby
{
  intentions: [
    { id: :safety, kind: :constraint, intent: Intention.avoid(:hazard) },
    { id: :goal,   kind: :heuristic,  intent: Intention.reach(target), weight: 1.0, priority: 10 }
  ]
}
```

## Arbitration Traceability
The `Decision.reason` must include a breakdown of the process:
- `voted_by`: IDs of intentions that contributed to the score.
- `vetoed_by`: IDs of intentions that exercised a veto.
- `vetoed_count`: Total number of candidates discarded.
- `final_scores`: Scores of the winner and close competitors.
