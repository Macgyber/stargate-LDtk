# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-02-02

### Added
- **Interactive Nodal Reference**: Transformed `referencia_nodal.md` into a side-by-side interactive carousel system (Spanish).
- **Atomic Nodal Mapping**: Every nodal tag (#XXXX) now corresponds to a unique, independent technical explanation and code snippet.

### Changed
- **Localization (v2)**: All public manuals, specifications, and samples translated to English.
- **Terminology Alignment**: Standardized `SemanticContract` to `SemanticSpecification` across the entire library and documentation.
- **Sample Cleanup**: Localized `cavernas` sample and removed redundant library copies.

## [1.1.0-experimental] - 2026-02-01

### Added
- **Tactical Core**: Deterministic interpreter supporting `CompositeIntention` (Constraints + Heuristics).
- **Temporal Horizon**: Awareness of future states (H=2) with Causal Veto and temporal discounting.
- **Audit Suite (H-Audit v2)**: High-fidelity headless verification for determinism, p95 latency, and chaos stability.
- **Chaos Tactics Lab**: Real-time multi-agent (10+) visualization tool with DragonRuby `primitives` rendering and live hot-reload sync.
- **Contracts**: Formal Technical Contracts (Spatial, Tactical, Temporal, World, Entity Mapping) in English.
- **Known Limits**: Explicit technical documentation of performance boundaries and cognitive scope.

### Changed
- **Architecture**: Enforced strict separation between Deliberation (Core) and Action (Executor).
- **Perception**: Refactored `SpatialAnalyzer` into an intent-aware `LogicalMap` generator.
- **Documentation**: Complete English translation and removal of metaphoric/philosophical language.

### Fixed
- **Rendering**: Corrected Z-sorting in DragonRuby labs to ensure actors remain visible above tactical overlays.
- **Sync**: Implemented `world_version` tracking to prevent actors from making decisions using stale spatial data.

---
🏆 **v1.x Development Completed**
