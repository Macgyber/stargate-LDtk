# Changelog

Todas las versiones del proyecto están documentadas aquí.

---

## [0.8.0-alpha] - 2026-02-02 - AUDITADO Y SELLADO

### 🎯 Estado Final
- **Calificación**: 8.0/10 (funcional, auditable, sin usuarios reales)
- **Desarrollo**: Sellado hasta validación en producción
- **Política**: No expandir sin necesidad real

### ✅ Correcciones Aplicadas

#### Nomenclatura
- Renombrado `Stargateldtk` → `StargateLDtk` en todos los archivos (13 archivos)
- Actualizada documentación para reflejar nombre consistente

#### Validación
- Agregada validación estricta de entrada en `Loader.load`
- Input externo ahora validado antes de procesamiento
- Errores claros con `ArgumentError`

#### Constantes
- Extraídas constantes de formato LDtk:
  - `ENTITIES_LAYER_TYPE = "Entities"`
  - `LEVELS_KEY = "levels"`
  - `LAYERS_KEY = "layerInstances"`
  - `GRID_DATA_KEY = "intGridCsv"`
  - `DEFAULT_GRID_SIZE = 16`

#### Inmutabilidad
- **BREAKING**: Eliminado método `World#next_version`
- Razón: Violaba principio de inmutabilidad
- Version ahora es solo dato, no comportamiento

#### Documentación
- Agregados anchor comments en clases críticas (`World`, `Loader`)
- Creado `ARCHIVE_NOTICE.md` con política de archivo
- Creado `DECISIONS_NOT_TAKEN.md` (qué NO se hizo y por qué)
- Creado `PROJECT_CEILING.md` (límites de identidad)
- Creado `FUTURE_MAINTAINER_NOTE.md` (contexto para el futuro)

### 🔧 Archivos Modificados
- `core/world.rb`
- `core/loader.rb`
- `analysis/spatial.rb`
- `tactics/intention.rb`
- `tactics/decision.rb`
- `tactics/temporal.rb`
- `tactics/interpreter.rb`
- `render/world_renderer.rb`
- `adapters/ldtk_to_dr.rb`
- `engine/executor.rb`
- `docs/referencia_nodal.md`
- `README.md`
- `CHANGELOG.md`

### 🪦 Código Legacy Eliminado
- `World#next_version` (auto-incremento de versión)

---

## [0.7.0] - 2026-02-02

### Added
- Interactive nodal reference in `docs/referencia_nodal.md`
- Atomic nodal mapping (each #XXXX tag has unique explanation)

### Changed
- Localization v2: Manuals and specs translated to English
- Terminology: `SemanticContract` → `SemanticSpecification`
- Sample cleanup

---

## [0.6.0] - 2026-02-01

### Added
- **Tactical Core**: Deterministic interpreter with `CompositeIntention`
- **Temporal Horizon**: Future state awareness (H=2)
- **Audit Suite**: Headless verification for determinism
- **Chaos Tactics Lab**: Multi-agent visualization tool
- **Formal contracts**: Spatial, Tactical, Temporal, World, Entity Mapping
- **Known limits**: Performance boundaries documentation

### Changed
- Architecture: Strict Deliberation/Executor separation
- Perception: `SpatialAnalyzer` → `LogicalMap` generator
- Documentation: Complete English translation

### Fixed
- Rendering: Z-sorting corrected
- Sync: `world_version` tracking implemented

---

## [0.5.0] - 2026-01-30

### Added
- Hot-reload system for LDtk maps
- Fluid movement with interpolation

### Changed
- Rendering improvements
- Spatial analysis optimization

---

## [0.4.0] - 2026-01-29

### Added
- Tactical decision engine
- Intention system

---

## [0.3.0] - 2026-01-28

### Added
- Basic spatial analysis
- LogicalMap for walkability queries

---

## [0.2.0] - 2026-01-27

### Added
- LDtk to internal format loader
- Core data structures (World, Grid, Entity)

---

## [0.1.0] - 2026-01-26

### Added
- Basic LDtk map rendering
- DragonRuby adapters

---

## [0.0.1] - 2026-01-25

### Added
- Initial project structure
- Basic bootstrap
- First functional prototype

