# StargateLDtk v0.8.0-alpha 🌌

> **Estado**: Auditado · Funcional · Sin usuarios en producción

Runtime de mapas tácticos 2D para DragonRuby, con análisis espacial y motor de decisiones determinista.

---

## 🎯 Qué Es

StargateLDtk convierte mapas de LDtk en estructuras de datos puras y consultables para juegos tácticos.

**NO es**:
- Un motor de juego completo
- Un editor de mapas
- Un framework de rendering

**SÍ es**:
- Un loader de LDtk a datos puros
- Un analizador espacial (walkability, pathfinding)
- Un motor de decisiones tácticas determinista

---

## 📦 Instalación

```ruby
# En tu app/main.rb
require "lib/stargate-LDtk/bootstrap.rb"
```

---

## 🚀 Uso Básico

### 1. Cargar Mapa

```ruby
def load_world(args, filename)
  raw_json = args.gtk.read_file("app/worlds/#{filename}.json")
  ldtk_json = args.gtk.parse_json(raw_json)
  
  args.state.world = StargateLDtk::Core::Loader.load(args, ldtk_json)
end
```

### 2. Análisis Espacial

```ruby
def update_logic(args)
  return if args.state.logical_map && 
            args.state.logical_map.world_version == args.state.world.version
  
  args.state.logical_map = StargateLDtk::Analysis::Spatial.analyze(args.state.world)
end
```

### 3. Consultas

```ruby
# Walkability
args.state.logical_map.walkable?(grid_x, grid_y)

# Pathfinding
path = args.state.logical_map.find_path(from_x, from_y, to_x, to_y)

# Entidades
spawns = args.state.world.entities.select { |e| e.type == "EnemySpawn" }
```

---

## 📚 Documentación

- **[User Manual](docs/user_manual.md)**: Guía de integración
- **[Referencia Nodal](docs/referencia_nodal.md)**: Documentación técnica completa (sistema #NNNN)
- **[Visión Futura](docs/vision_adelantada_a_su_tiempo.md)**: Ideas archivadas para evolución futura

---

## 🧱 Arquitectura

### Principios

1. **Datos puros**: `World` es inmutable, sin comportamiento
2. **Validación estricta**: Input externo nunca es confiable
3. **Determinismo**: Mismos datos → mismas decisiones
4. **Separación**: Lógica ≠ Rendering ≠ Game State

---

## ⚠️ Cuándo NO Usar

- Mapas simples sin IA táctica
- Prototipos rápidos
- Juegos sin necesidad de replay/determinismo
- Física continua (Stargate es discreto)

---

## 📊 Estado del Proyecto

**Versión**: 0.8.0-alpha (Auditado 2026-02-02)  
**Calificación**: 8.0/10 (funcional, auditable, sin usuarios reales)  
**Desarrollo**: Sellado hasta validación en producción

### Correcciones Aplicadas

- ✅ Nomenclatura consistente (`StargateLDtk`)
- ✅ Validación de entrada estricta
- ✅ Constantes centralizadas
- ✅ Código legacy eliminado
- ✅ Documentación arquitectónica completa

### Política de Cambios

**No expandir sin necesidad real.**

El proyecto se reabre solo si:
- Aparece un bug crítico
- Un proyecto real lo requiere
- Una limitación duele de verdad

---

## 🔧 Estructura

```
stargate-ldtk/
├── core/           # Datos puros (World, Grid, Entity)
├── analysis/       # Análisis espacial (LogicalMap)
├── tactics/        # Motor de decisiones (Intention, Decision)
├── render/         # Rendering para DragonRuby
├── adapters/       # Conversión de coordenadas
├── engine/         # Ejecutor de decisiones
└── docs/           # Documentación técnica
```

---

## 📜 Licencia

Este proyecto es de código abierto. Úsalo, modifícalo, aprende de él.

---

## ✍️ Nota Final

Este proyecto no está abandonado.  
Está **completo**.

Si vuelves a él en meses o años:
- Lee `docs/referencia_nodal.md` primero
- Respeta los marcadores `#NNNN`
- No agregues features "porque sí"

**Archivado con honores**: 2026-02-02