# Architecture Principles: Cognitive Core (v1.x)

This document defines the technical boundaries and guarantees of the `stargateldtk` cognitive core. It establishes the separation between **Mind** (decision-making) and **Body** (execution).

## 1. Separation of Concerns
The core operates in three distinct, independent stages:
1.  **World (Static)**: Passive data structure representing the environment.
2.  **Analysis (Contextual)**: Derivation of logical maps and spatial indexes.
3.  **Tactics (Active)**: Resolution of intentions into decisions.

## 2. Inmutability and Traceability
- Every `World` is immutable. Changes generate a new version.
- Decisions must provide reasons based on verifiable data, not random state.
- Traceability is managed via the `world.version` field.

## 3. Passive Rendering
The rendering engine is a **pure observer**. It does not modify logic or data. Its only role is to represent the `World` and `Actor` states visually.

## 4. Determinism
Given the same logical state and the same intention, the system must always produce the same decision. This ensures that the AI is predictable and debuggable.

## 5. Standard Constraints
The core provides standard constraints (e.g., `avoid_hazard`, `keep_distance`) that guarantee a baseline of safety for all actors without requiring custom logic for every behavior.
