# Specification: Temporal Horizon (v1.x)

## Purpose
The `TacticalInterpreter` v1.1 introduces awareness of the near future. An agent is not intelligent if its immediate success guarantees subsequent failure. The Temporal Horizon formalizes the evaluation of consequences under rules of prudence and efficiency.

## Laws of the Horizon

### 1. Law of Causal Veto (Forward Filtering)
If an immediate action $A$ at time $T$ leads **inevitably** to a **Total Veto** state at time $T+H$ (within the horizon), action $A$ must be vetoed at time $T$.
- **Definition of Inevitable**: A future state is considered "inevitably vetoed" only if **all** possible actions in that state violate at least one **Constraint** of the present specification.

### 2. Law of Discounted Residual Heuristic (Future Value)
The value of an immediate action is the sum of its present benefit and the weighted potential benefit of the horizon.
- **Formula**: $Score_{total} = Score_T + \gamma \cdot Score_{T+H}$
- **Discount Factor ($\gamma$)**: A value between $(0, 1]$ determining the importance of the future. $\gamma = 0.5$ for high prudence, $\gamma = 1.0$ for full foresight.

### 3. Law of Limit and Short-Circuit (Efficiency)
The horizon must be short ($H \in [1, 3]$), and the simulation must be efficient.
- **Short-Circuit**: If a candidate is vetoed at $T+n$, its future simulation stops immediately.
- **Determinism**: No deep recursion or infinite branching is allowed to preserve the synchronicity guarantee.

### 4. Law of State Evaluation (No-Future-Decision)
The simulation **evaluates states**, not future decisions.
- **Prohibition**: During horizon simulation, no `Decision` objects are invoked, and no recursive composite arbitration is performed. Only state metrics (distance, safety, tags) are measured.

## Integration Model

The arbitration pipeline expands:
1.  **Constraints (Present)**: Veto immediate dangers.
2.  **Forward Simulation (Causal Veto)**: Filter actions leading to inevitable failure in $T+H$.
3.  **Heuristics (Composite)**: Calculate score including the discounted residual value ($\gamma$).

## Temporal Traceability
The `Decision.reason` adds:
- `horizon_vetos`: List of candidate IDs discarded due to future consequences.
- `future_potential`: The projected $Score_{T+H}$ that influenced the choice.
- `discount_factor`: The value of $\gamma$ used.
