# Referencia Nodal: StargateLDtk 🌐

**Versión**: 0.8.0-alpha

Este documento es el manual técnico de estudio de la librería. Mapea cada identificador numérico (`#XXXX`) en el código fuente a una explicación detallada de su mecánica interna, lógica de diseño y comportamiento esperado.

---

## Índice de Módulos y Rangos
- **Módulo 1: Bootstrap & Engine** (#0001 - #0019)
- **Módulo 2: Core (Data & Loader)** (#0020 - #0050)
- **Módulo 3: Analysis (Spatial)** (#0051 - #0100)
- **Módulo 4: Render (Visuals)** (#0101 - #0150)
- **Módulo 5: Tactics (AI & Decision)** (#0151 - #0250)
- **Módulo 6: Adapters & Utils** (#0251 - #0350)
- **Módulo 7: Sistemas Globales & Futuro** (#1000+)

---

<details>
<summary>## 1. Módulo: Bootstrap & Engine (#0010 - #0019)</summary>

### #0010: Bootloader de Infraestructura

**Qué hace**: Carga las clases de datos fundamentales del sistema.

**Por qué primero**: `World`, `Grid` y `Entity` son las estructuras base que todos los demás módulos necesitan. Sin estas clases, nada más puede funcionar.

**Orden de carga**:
1. `core/world.rb` - Define `World` (contenedor principal)
2. `core/loader.rb` - Define `Loader` (convierte LDtk JSON → World)

**Serializado**:
```ruby
# #0010
require_relative "stargate-ldtk/core/world.rb"
require_relative "stargate-ldtk/core/loader.rb"
```

**Decisión técnica**: Se usa `require_relative` en vez de `require` absoluto para que el módulo sea portable. Si se mueve la carpeta, los paths relativos siguen funcionando.

---

### #0013: Carga de Analítica

**Qué hace**: Integra el módulo de análisis espacial.

**Por qué después del core**: `Spatial` necesita que `World` ya esté definido porque analiza objetos `World` y genera `LogicalMap`.

**Serializado**:
```ruby
# #0013
require_relative "stargate-ldtk/analysis/spatial.rb"
```

**Función**: Permite consultas topológicas (walkability, pathfinding) sobre el `World`.

---

### #0014: Carga de Renderizado

**Qué hace**: Integra el módulo de visualización.

**Por qué después de análisis**: El renderer necesita tanto `World` (para saber qué dibujar) como potencialmente `LogicalMap` (para debug visual).

**Serializado**:
```ruby
# #0014
require_relative "stargate-ldtk/render/world_renderer.rb"
```

**Principio**: El renderer es **pasivo**. Solo observa datos, nunca los modifica.

---

### #0015: Carga de Tácticas

**Qué hace**: Integra el cerebro del sistema para razonamiento de actores.

**Por qué después de análisis**: Las tácticas necesitan `LogicalMap` para tomar decisiones basadas en el espacio.

**Orden interno**:
1. `intention.rb` - Define qué quiere hacer un actor
2. `decision.rb` - Define qué decidió hacer
3. `temporal.rb` - Awareness de estados futuros
4. `interpreter.rb` - Convierte intención → decisión

**Serializado**:
```ruby
# #0015
require_relative "stargate-ldtk/tactics/intention.rb"
require_relative "stargate-ldtk/tactics/decision.rb"
require_relative "stargate-ldtk/tactics/temporal.rb"
require_relative "stargate-ldtk/tactics/interpreter.rb"
```

**Arquitectura**: Separación estricta entre **Deliberación** (Tactics) y **Acción** (Executor).

---

### #0016: Carga de Adaptadores

**Qué hace**: Carga utilidades de conversión específicas para DragonRuby.

**Por qué al final**: Los adaptadores dependen de que todo lo demás ya esté cargado.

**Serializado**:
```ruby
# #0016 - Adapters
require_relative "adapters/ldtk_to_dr.rb"
```

**Función**: Convierte coordenadas LDtk (Y-down) a DragonRuby (Y-up).

---

### #0012: Sello de Disponibilidad

**Qué hace**: Confirma que el sistema está listo.

**Por qué al final**: Solo se imprime después de que todos los módulos se cargaron sin errores.

**Serializado**:
```ruby
# #0012
puts "🌌 StargateLDtk v0.8.0-alpha: Initialized."
```

**Propósito**: Mensaje técnico en consola que confirma:
- ✅ Todos los módulos se cargaron
- ✅ No hubo errores de sintaxis
- ✅ El sistema está listo para usar

**Versión**: Debe coincidir con `CHANGELOG.md` y tags de git.

</details>

---

<details>
<summary>## 2. Módulo: Core - Data Structures (#0002 - #0009)</summary>

### #0002: Loader - Zona de Desconfianza

**Qué hace**: Convierte JSON de LDtk en objetos `World` internos.

**Por qué es crítico**: Este es el único punto donde entra data externa no confiable. Todo lo que pase de aquí debe estar validado.

**Arquitectura**:
- **Input**: JSON de LDtk (formato externo, puede estar corrupto)
- **Output**: `World` (formato interno, garantizado válido)

**Validaciones**:
```ruby
# #0002
raise ArgumentError, "ldtk_json must be a Hash" unless ldtk_json.is_a?(Hash)
raise ArgumentError, "ldtk_json must have 'levels' key" unless ldtk_json.key?(LEVELS_KEY)
```

**Constantes de formato**:
```ruby
ENTITIES_LAYER_TYPE = "Entities"
LEVELS_KEY = "levels"
LAYERS_KEY = "layerInstances"
GRID_DATA_KEY = "intGridCsv"
DEFAULT_GRID_SIZE = 16
```

**Decisión**: Constantes extraídas para evitar magic strings y facilitar cambios de formato LDtk.

---

### #0004: Detección de Grid Size

**Qué hace**: Determina el tamaño de celda del mapa.

**Por qué es necesario**: LDtk permite grid size variable. Necesitamos detectarlo para convertir coordenadas pixel → grid.

**Serializado**:
```ruby
# #0004
first_layer = (level[LAYERS_KEY] || []).first
gsize = (first_layer ? first_layer["__gridSize"] : (ldtk_json["defaultGridSize"] || DEFAULT_GRID_SIZE)).to_i
```

**Fallback**: Si no hay layers, usa `defaultGridSize`. Si tampoco existe, usa `16` (estándar LDtk).

---

### #0005: Construcción de Layout

**Qué hace**: Calcula dimensiones del mundo en pixels y en grid.

**Serializado**:
```ruby
# #0005
layout = {
  px_width:  level["pxWid"].to_i,
  px_height: level["pxHei"].to_i,
  width:     (level["pxWid"].to_i / gsize).to_i,
  height:    (level["pxHei"].to_i / gsize).to_i,
  tile_size: gsize
}
```

**Uso posterior**: `Spatial` usa `layout.width` y `layout.height` para crear `LogicalMap`.

---

### #0006: Procesamiento de Layers

**Qué hace**: Itera sobre todas las capas del nivel y las clasifica.

**Tipos de layer**:
1. **Entities** (`__type == "Entities"`) → van a `entities[]`
2. **Tiles/IntGrid** (resto) → van a `grids[]`

**Serializado**:
```ruby
# #0006
grids = []
entities = []
(level[LAYERS_KEY] || []).each do |layer|
  if layer["__type"] == ENTITIES_LAYER_TYPE
    # Procesar entidades (#0007)
  else
    # Procesar grids (#0008)
  end
end
```

---

### #0007: Extracción de Entidades

**Qué hace**: Convierte `entityInstances` de LDtk en objetos `Entity`.

**Validación**: Verifica que `entityInstances` exista antes de iterar.

**Serializado**:
```ruby
# #0007
next unless layer["entityInstances"]

layer["entityInstances"].each do |e|
  entities << Entity.new(
    id: e["iid"],
    type: e["__identifier"],
    pos: { 
      x: e["px"][0], 
      y: e["px"][1],
      grid_x: e["__grid"][0], 
      grid_y: e["__grid"][1] 
    },
    fields: extract_fields(e["fieldInstances"])
  )
end
```

**Campos custom**: `extract_fields` convierte `fieldInstances` en hash simple.

---

### #0008: Extracción de Grids

**Qué hace**: Convierte layers de tiles en objetos `Grid`.

**Tipos de tiles**:
- `autoLayerTiles` - Tiles generados automáticamente
- `gridTiles` - Tiles manuales
- `intGridCsv` - Data de walkability/collision

**Serializado**:
```ruby
# #0008
visual_tiles = (layer["autoLayerTiles"] || layer["gridTiles"] || []).map do |t|
  { px: t["px"], src: t["src"], f: t["f"], t: t["t"] }
end

grids << Grid.new(
  identifier: layer["__identifier"],
  size: { cols: layer["__cWid"], rows: layer["__cHei"] },
  data: layer[GRID_DATA_KEY] || [],
  visual_data: visual_tiles
)
```

**Uso posterior**: `WorldRenderer` usa `visual_data` para dibujar. `Spatial` usa `data` para walkability.

---

### #0009: Construcción de World

**Qué hace**: Ensambla todas las piezas en un objeto `World` inmutable.

**Serializado**:
```ruby
# #0009
World.new(
  id: level["iid"],
  layout: layout,
  grids: grids,
  entities: entities,
  metadata: { 
    bg_color: level["__bgColor"], 
    toc: ldtk_json["toc"] || [] 
  },
  version: version
)
```

**Inmutabilidad**: Una vez creado, `World` no se modifica. Cualquier cambio requiere crear nuevo `World`.

</details>

```ruby
# loader.rb
# #0002
class Loader
  def self.load(args, ldtk_json, version: 0)
    levels = ldtk_json["levels"] || []
    # ...
```

### #0003: Estructura World (El Átomo de Datos)
**Estructura World**: La "Única Fuente de Verdad" (SSOT) del sistema. Es un objeto de datos estrictamente inmutable. Emplea un campo `version` (entero atómico) que funciona como un "Sello de Honestidad": cualquier cambio en el diseño del nivel resulta en un nuevo objeto con versión incrementada. Esto permite que los sistemas de análisis y renderizado detecten cambios en tiempo constante O(1) e invaliden sus cachés solo cuando es estrictamente necesario.

```ruby
# world.rb
# #0003
class World
  attr_reader :id, :layout, :grids, :entities, :metadata, :version
  # ...
end
```

### #0004: Extracción de gridSize (Resolución Espacial)
**Extracción de gridSize**: Define la granularidad del espacio lógico. El sistema busca primero el `__gridSize` específico de la capa superior para respetar la intención del diseñador, cayendo en el `defaultGridSize` del proyecto solo en su ausencia. Esta resolución es crítica porque determina la escala de todas las coordenadas de rejilla posteriores.

```ruby
# loader.rb
# #0004
first_layer = (level["layerInstances"] || []).first
gsize = (first_layer ? first_layer["__gridSize"] : (ldtk_json["defaultGridSize"] || 16)).to_i
```

### #0005: Normalización de Layout (Marco de Referencia)
**Normalización de Layout**: Establece las dimensiones absolutas del mundo tanto en píxeles como en unidades de rejilla. Al pre-calcular el `width` y `height` en celdas durante la carga, se eliminan divisiones costosas en tiempo de ejecución durante las fases de análisis espacial y tácticas. Es el contrato de límites para el resto de la tubería.

```ruby
# loader.rb
# #0005
layout = {
  px_width:  level["pxWid"].to_i,
  px_height: level["pxHei"].to_i,
  width:     (level["pxWid"].to_i / gsize).to_i,
  height:    (level["pxHei"].to_i / gsize).to_i,
  tile_size: gsize
}
```

### #0006: Filtro de Capas (Separación de Preocupaciones)
**Filtro de Capas**: Proceso de clasificación selectiva. Discrimina entre capas de entidades (lógica pura) y capas de rejilla (visual/topológica). Esto permite que el sistema de IA ignore el ruido de tiles puramente decorativos mientras que el renderizador ignora metadatos de comportamiento, optimizando el consumo de memoria y la velocidad de iteración.

```ruby
# loader.rb
# #0006
grids = []
entities = []
(level["layerInstances"] || []).each do |layer|
  if layer["__type"] == "Entities"
    # ...
```

### #0007: Diccionario de Entidades (Persistencia y Semántica)
**Diccionario de Entidades**: Captura la identidad y el estado de los actores. Utiliza el `iid` (Global Unique ID de LDtk) para asegurar que una entidad pueda mantener su estado (ej. vida, inventario) incluso si el mundo se recarga por Hot-Reload. Los `fields` permiten inyectar parámetros de comportamiento personalizados directamente desde el editor de niveles sin tocar una línea de código.

```ruby
# loader.rb
# #0007
entities << Entity.new(
  id: e["iid"],
  type: e["__identifier"],
  pos: { ... },
  fields: extract_fields(e["fieldInstances"])
)
```

### #0008: Traducción de Rejillas (Compresión de Atlas)
**Traducción de Rejillas**: Transforma los datos verbosos de tiles de LDtk en objetos `Grid` ligeros. Extrae solo los punteros necesarios: posición en pantalla (`px`) y posición en el atlas fuente (`src`). Al ignorar flags de flipping o rotación complejos no esenciales para la lógica, reduce el footprint de datos del mapa en memoria.

```ruby
# loader.rb
# #0008
visual_tiles = (layer["autoLayerTiles"] || layer["gridTiles"] || []).map do |t|
  { px: t["px"], src: t["src"], f: t["f"], t: t["t"] }
end

grids << Grid.new(
  identifier: layer["__identifier"],
  size: { cols: layer["__cWid"], rows: layer["__cHei"] },
  data: layer["intGridCsv"] || [],
  visual_data: visual_tiles
)
```

### #0009: Consolidación y Sellado (Freeze Final)
**Consolidación y Sellado**: El acto final del cargador. Ensambla todas las partes analizadas en una instancia de `World`. Al pasar la `version` actual, se sella el estado del universo para ese cuadro de ejecución. Este patrón garantiza que ninguna parte del código pueda mutar accidentalmente el mapa a mitad de un ciclo táctico, manteniendo la integridad referencial absoluta.

```ruby
# loader.rb
# #0009
World.new(
  id: level["iid"],
  layout: layout,
  grids: grids,
  entities: entities,
  metadata: { ... },
  version: version
)
```
</details>

---

<details>
<summary>## 3. Módulo: Analysis (#0051 - #0100)</summary>

### #0051: Spatial.analyze

**Qué hace**: Convierte `World` (datos crudos) → `LogicalMap` (inteligencia espacial consultable).

**Input**: `world` (objeto World), `config` (hash opcional)  
**Output**: `LogicalMap` o `nil`

**Serializado**:
```ruby
# #0051
class Spatial
  def self.analyze(world, config = {})
    return nil unless world
    # ...
  end
end
```

---

### #0052: SemanticSpecification

**Qué hace**: Mapea enteros a tags semánticos.

**Por qué**: LDtk guarda colisión como números. Necesitamos tags legibles (`:empty`, `:solid`).

**Serializado**:
```ruby
# #0052
class SemanticSpecification
  def initialize(mapping)
    @mapping = mapping
  end

  def tag_for(value)
    @mapping[value] || :blocked
  end
end
```

**Default defensivo**: Valores desconocidos → `:blocked`.

---

### #0053: Grid Validation

**Qué hace**: Crash si el grid de colisión no existe.

**Por qué fail-fast**: Mejor crash en load que fallo silencioso durante gameplay.

**Serializado**:
```ruby
# #0053
raise "Spatial Analysis Error: Grid '#{grid_id}' not found in World." unless collision_grid
```

---

### #0058: World Validation

**Qué hace**: Valida que todos los grids tengan el tamaño correcto de datos.

**Por qué crítico**: Si un grid dice 10x10 pero tiene 99 celdas, las consultas fallarán.

**Serializado**:
```ruby
# #0058
def self.validate_world!(world)
  world.grids.each do |grid|
    expected_size = grid.size[:cols] * grid.size[:rows]
    if grid.data.size != expected_size
      raise "Error: Grid '#{grid.identifier}' size mismatch..."
    end
  end
end
```

---

### #0059: Contract Creation

**Qué hace**: Crea mapeo de números → tags semánticos.

**Serializado**:
```ruby
# #0059
contract = SemanticSpecification.new(config[:mapping] || { 0 => :empty })
```

**Default**: `0 = :empty` (caminable).

---

### #0060: Collision Grid Selection

**Qué hace**: Encuentra el grid que contiene datos de walkability.

**Serializado**:
```ruby
# #0060
grid_id = config[:collision_grid] || "Collision"
collision_grid = world.grids.find { |g| g.identifier == grid_id }
```

**Default**: Busca grid llamado `"Collision"`.

---

### #0061: Topology Extraction

**Qué hace**: Convierte array de enteros → array de tags semánticos.

**Ejemplo**:
- Input: `[0, 0, 1, 0, 1, 1]`
- Contract: `{ 0 => :empty, 1 => :solid }`
- Output: `[:empty, :empty, :solid, :empty, :solid, :solid]`

**Serializado**:
```ruby
# #0061
topology = extract_topology(collision_grid, contract)

def self.extract_topology(grid, contract)
  grid.data.map { |v| contract.tag_for(v) }
end
```

---

### #0054: LogicalMap Construction

**Qué hace**: Crea el objeto de mapa consultable final.

**Serializado**:
```ruby
# #0054
LogicalMap.new(
  world: world,
  topology: topology,
  contract: contract
)
```

**Contenido**:
- `@world_id`, `@world_version` - Identificación
- `@layout` - Dimensiones
- `@topology` - Tags semánticos
- `@entities` - Entidades del mundo
- `@spatial_index` - Lookup O(1) por posición

---

### #0055: Spatial Index

**Qué hace**: Crea hash map para lookup rápido de entidades por posición.

**Performance**: `entities_at(x, y)` es O(1) en vez de O(n).

**Serializado**:
```ruby
# #0055
def build_spatial_index!
  @spatial_index = {}
  @entities.each do |e|
    gx = e.pos[:grid_x]
    gy = e.pos[:grid_y]
    @spatial_index[[gx, gy]] ||= []
    @spatial_index[[gx, gy]] << e
  end
end
```

---

### #0056: Distance Calculation (BFS)

**Qué hace**: Encuentra distancia de camino caminable más corto.

**Algoritmo**: Breadth-First Search.

**Serializado**:
```ruby
# #0056
def distance(x1, y1, x2, y2)
  queue = [[x1, y1, 0]]
  visited = { [x1, y1] => true }
  
  while !queue.empty?
    cx, cy, d = queue.shift
    return d if cx == x2 && cy == y2
    
    neighbors(cx, cy).each do |n|
      next if visited[[n[:x], n[:y]]]
      next unless walkable?(n[:x], n[:y])
      
      visited[[n[:x], n[:y]]] = true
      queue << [n[:x], n[:y], d + 1]
    end
  end
  
  9999
end
```

**Retorna**: Distancia en tiles, o `9999` si inalcanzable.

---

### #0057: Neighbors Calculation

**Qué hace**: Retorna tiles adyacentes válidos (4-direccional).

**Serializado**:
```ruby
# #0057
def neighbors(gx, gy)
  [[0, 1], [0, -1], [1, 0], [-1, 0]].map do |dx, dy|
    nx, ny = gx + dx, gy + dy
    next nil if nx < 0 || ny < 0 || nx >= @layout[:width] || ny >= @layout[:height]
    { x: nx, y: ny, tag: tag_at(nx, ny) }
  end.compact
end
```

**Direcciones**: Arriba, Abajo, Derecha, Izquierda (sin diagonales).

</details>

---

<details>
<summary>## 4. Módulo: Render (#0101 - #0106)</summary>

### #0101: WorldRenderer.draw - Entry Point

**Qué hace**: Dibuja el `World` en pantalla usando primitivas de DragonRuby.

**Input**: `args` (DragonRuby args), `world` (World object), `camera` (opcional)  
**Output**: Primitivas gráficas en `args.outputs`

**Serializado**:
```ruby
# #0101
class WorldRenderer
  def self.draw(args, world, camera = nil)
    return unless world
    # ...
  end
end
```

**Principio**: Renderer es **pasivo**. Solo observa `World`, nunca lo modifica.

---

### #0102: Clear Screen

**Qué hace**: Limpia la pantalla dibujando un rectángulo negro.

**Por qué necesario**: Elimina residuos del frame anterior (ghosting).

**Serializado**:
```ruby
# #0102
args.outputs.primitives << { 
  x: 0, y: 0, w: 1280, h: 720, 
  r: 0, g: 0, b: 0, 
  primitive_marker: :solid 
}
```

**Dimensiones**: 1280x720 (resolución estándar DragonRuby).

---

### #0103: Camera Parameters

**Qué hace**: Extrae parámetros de cámara (posición y zoom).

**Por qué necesario**: Convierte coordenadas mundo → coordenadas pantalla.

**Serializado**:
```ruby
# #0103
cam_x = camera ? camera[:x] : 0
cam_y = camera ? camera[:y] : 0
zoom  = camera ? camera[:zoom] : 1.0
```

**Defaults**: Si no hay cámara, usa (0, 0) con zoom 1.0.

---

### #0104: Render Loop

**Qué hace**: Dibuja grids primero, luego entities.

**Por qué este orden**: Grids son fondo, entities son foreground. Orden = Z-depth.

**Serializado**:
```ruby
# #0104
world.grids.each { |grid| draw_debug_grid(args, grid, zoom, cam_x, cam_y) }
world.entities.each { |entity| draw_entity(args, entity, zoom, cam_x, cam_y) }
```

**Z-Order**: Grids → Entities (asegura que entities se vean encima).

---

### #0105: Entity Projection

**Qué hace**: Convierte posición de entity en coordenadas de pantalla.

**Fórmula**:
- `sx = (entity.pos[:x] - cam_x) * zoom + 640`
- `sy = 360 - (entity.pos[:y] - cam_y) * zoom`

**Serializado**:
```ruby
# #0105
def self.draw_entity(args, entity, zoom, cam_x, cam_y)
  sx = (entity.pos[:x] - cam_x) * zoom + 640
  sy = 360 - (entity.pos[:y] - cam_y) * zoom
  
  # Draw entity box
  args.outputs.primitives << { 
    x: sx, y: sy, w: 16 * zoom, h: 16 * zoom, 
    r: 200, g: 200, b: 255, 
    primitive_marker: :solid 
  }
  
  # Draw entity label
  args.outputs.primitives << { 
    x: sx, y: sy + (20 * zoom), 
    text: entity.type, 
    size_enum: -2, 
    r: 255, g: 255, b: 255, 
    primitive_marker: :label 
  }
end
```

**Pivot**: Centro de pantalla (640, 360).  
**Y-flip**: DragonRuby usa Y-up, por eso `360 - ...`.

---

### #0106: Grid Rendering

**Qué hace**: Renderiza tiles del grid (placeholder actual).

**Serializado**:
```ruby
# #0106
def self.draw_debug_grid(args, grid, zoom, cam_x, cam_y)
  # Placeholder for tile rendering
end
```

**Estado actual**: Vacío (debug mode). Implementación completa requiere iterar `grid.visual_data`.

---

## Arquitectura de Render

**Separación estricta**:
- Render NO conoce lógica de juego
- Render NO modifica `World`
- Render solo lee y dibuja

**Performance**:
- Stateless (sin cache interno)
- Redibuja todo cada frame
- Suficiente para mapas pequeños (<1000 tiles)

</details>


---

<details>
<summary>## 5. Módulo: Tactics (#0151 - #0250)</summary>

### #0151: Clase Intention (El Deseo Inmutable)
**Clase Intention**: Representa el "qué" quiere hacer un agente. Es un objeto de datos inmutable que encapsula un tipo de deseo (ej. alcanzar un punto, evitar un peligro) y los parámetros necesarios para evaluarlo. Al ser inmutable, permite que el sistema táctico compare múltiples intenciones sin riesgo de efectos secundarios cruzados.

```ruby
# intention.rb
# #0151
class Intention
  attr_reader :type, :payload
  # ...
end
```

### #0152: Clase Decision (La Salida Auditable)
**Clase Decision**: El resultado final del razonamiento. No es solo una instrucción de movimiento; es un paquete de datos que incluye la justificación técnica (`reason`). Esta trazabilidad es lo que permite a los desarrolladores entender *por qué* una IA decidió moverse o quedarse quieta, transformando la caja negra del comportamiento en una serie de pasos lógicos auditables.

```ruby
# decision.rb
# #0152
class Decision
  def initialize(type:, payload: {}, reason: {})
    @type = type
    @payload = payload
    @reason = reason # #0152
  end
end
```

### #0155: Constructor move_to (Factory de Decisiones)
**Constructor move_to**: El método formal para generar intenciones de movimiento. Encapsula la creación de un objeto `Decision` con tipo `:move`, asegurando que el destino y la justificación técnica se empaqueten correctamente. Al centralizar la creación de decisiones de movimiento, garantiza un contrato consistente entre el cerebro (Íntérprete) y el cuerpo (Ejecutor).

```ruby
# decision.rb
# #0155
def self.move_to(gx, gy, reason)
  Decision.new(type: :move, payload: { x: gx, y: gy }, reason: reason)
end
```

### #0153 & #0157: Evaluador Temporal (Simulación de Futuros)
**Evaluador Temporal**: El motor de "instinto" del sistema. Antes de comprometerse con un movimiento, el evaluador simula un árbol de consecuencias futuras (Horizonte `H`). Calcula si un paso aparentemente seguro hoy no llevará a un callejón sin salida mañana. Es el componente que otorga a los agentes una apariencia de inteligencia preventiva.

```ruby
# temporal.rb
# #0153
module Temporal
  # #0157
  def self.evaluate(map, composite, cand_node, context, horizon: 2, gamma: 0.5)
    # ... BFS simulation logic ...
  end
end
```

### #0154: Intérprete de Tácticas (El Árbitro Central)
**Intérprete de Tácticas**: El núcleo del cerebro. Su función es recibir un `LogicalMap` y un conjunto de intenciones, y arbitrar entre ellas para producir la mejor decisión posible. Utiliza una tubería de evaluación que combina restricciones binarias (vetos) y heurísticas ponderadas, asegurando que la acción resultante sea siempre la más óptima bajo el contrato actual.

```ruby
# interpreter.rb
# #0154
class Interpreter
  def self.decide(map, intention, context = {})
    # ...
  end
end
```

### #0158: Análisis de Seguridad Futura (Escaneo de Nodos)
**Análisis de Seguridad Futura**: Durante la simulación temporal, este nodo examina cada celda proyectada. Comprueba las etiquetas lógicas del mapa (`tag_at`) en cuadros futuros para identificar peligros estáticos o zonas restringidas que el agente debe evitar en su trayectoria de planificación.

```ruby
# temporal.rb
# #0158
visit_queue = frontier
visited = { [cand_node[:x], cand_node[:y]] => true }
# ...
node = { x: cx, y: cy, tag: map.tag_at(cx, cy) }
```

### #0159: Veto por Supervivencia (Prevención de Atrapamiento)
**Veto por Supervivencia**: El filtro de seguridad más crítico. Aunque una celda parezca segura en el presente (`T+0`), este nodo la descarta si la simulación futura demuestra que no hay "salidas seguras" posibles desde ella en el horizonte `H`. Evita que la IA entre en celdas de las que no podrá escapar, actuando como un instinto de autopreservación que prioriza la libertad de movimiento a largo plazo.

```ruby
# temporal.rb
# #0159
if has_safe_out?(map, composite, node)
  can_survive = true
  # ...
end
```

### #0160: Expansión BFS Temporal (Exploración de Ramas)
**Expansión BFS Temporal**: El método de búsqueda para la predicción. Explora recursivamente los vecinos válidos de cada nodo proyectado para construir una red de consecuencias posibles. A diferencia de un A* tradicional, aquí no buscamos el camino más corto, sino que escaneamos densamente el entorno cercano para evaluar la "seguridad media" de una dirección elegida.

```ruby
# temporal.rb
# #0160
map.neighbors(cx, cy).each do |n|
  # ... logic to check future constraints ...
  visit_queue << [n[:x], n[:y], d + 1]
end
```

### #0161: Confirmación de Salida Segura (Seguro Anti-Veto)
**Confirmación de Salida Segura**: Un sub-proceso binario que valida la viabilidad de un estado proyectado. Verifica si el agente tiene al menos una opción de movimiento legal (o la opción de esperar) que no viole ninguna restricción dura al final de la trayectoria. Es lo que garantiza que el agente nunca "se rinda" en su simulación interna.

```ruby
# temporal.rb
# #0161
def self.has_safe_out?(map, composite, node)
  # ... any? neighbor is NOT vetoed by constraint ...
end
```

### #0162: Puntuación de Estado Futuro (Cálculo de Potencial)
**Puntuación de Estado Futuro**: Agrega el beneficio acumulado de las heurísticas en el nodo final de la simulación. Permite que la IA compare dos direcciones seguras y elija aquella que, estadísticamente, la deja en una posición más ventajosa (ej. más cerca del objetivo o más lejos del peligro) al final del horizonte temporal.

```ruby
# temporal.rb
# #0162
def self.score_state(map, composite, node, context)
  # ... aggregates scores from heuristics ...
end
```

### #0163: Métrica de Proximidad (Vector de Intento)
**Métrica de Proximidad**: El corazón de la persecución. Mide la delta entre la distancia actual al objetivo y la distancia proyectada. Premia con puntuación positiva los movimientos que reducen esta distancia, creando un gradiente de atracción hacia el objetivo que guía el comportamiento del agente de forma determinista.

```ruby
# temporal.rb
# #0163
dist = map.distance(node[:x], node[:y], target[:x], target[:y])
current_dist = map.distance(context[:x], context[:y], ...)
```

### #0164: Integración Causal (Puente Presente-Futuro)
**Integración Causal**: El punto de unión en el intérprete donde los datos del simulador temporal se inyectan en la evaluación de cada candidato actual. Transforma la validación binaria de supervivencia y la puntuación de potencial futuro en variables utilizables por la sumatoria de arbitraje, permitiendo una toma de decisiones informada y coherente.

```ruby
# interpreter.rb
# #0164
is_valid, future_score, veto_reason = Temporal.evaluate(...)
```

### #0165: Arbitraje Ponderado (La Ecuación de Decisión)
**Arbitraje Ponderado**: La lógica matemática final. Suma las heurísticas del presente (acción inmediata) con el beneficio esperado del futuro (potencial proyectado), aplicando un factor de descuento `gamma`. Los `weights` (pesos) permiten que el diseñador dé más importancia a ciertas intenciones sobre otras, definiendo la personalidad táctica del agente.

```ruby
# interpreter.rb
# #0165
scores[cand] = present_score + (temporal_scores[cand] || 0.0)
```

### #0166: Resolución de Empates (Arbitraje de Prioridad)
**Resolución de Empates**: El mecanismo de desempate determinista. Cuando dos o más movimientos tienen exactamente la misma puntuación máxima, esta lógica analiza cuál de ellos favorece más a la intención de mayor prioridad jerárquica. Esto elimina la aleatoriedad en el comportamiento, asegurando que la IA siempre sea predecible ante las mismas condiciones.

```ruby
# interpreter.rb
# #0166
final_winner = winners.size > 1 ? resolve_ties(winners, composite) : winners.first
```

### #0167: Validador de Restricciones (El Filtro de Acero)
**Validador de Restricciones**: Un motor de lógica booleana que aplica las reglas innegociables del comportamiento. Evalúa si un candidato viola una prohibición explícita (ej. no pisar lava). Si se detecta una violación, el candidato se veta de inmediato, sin importar cuán prometedor sea en otros aspectos, estableciendo los límites éticos/físicos de la IA.

```ruby
# interpreter.rb
# #0167
def self.violates_constraint?(map, intent, candidate, context)
  case intent.type
  when :avoid
    map.has_tag?(candidate[:x], candidate[:y], intent.payload[:tag])
  # ...
end
```

### #0168: Calculador de Heurísticas (Evaluación de Beneficio)
**Calculador de Heurísticas**: El motor de puntuación continua. A diferencia de las restricciones binarias, las heurísticas devuelven un valor en el rango de `-1.0` a `1.0`, indicando cuán "deseable" es un movimiento. Permite que la IA compare matices sutiles entre varias opciones seguras, como elegir el camino que la acerca más al objetivo aunque ambos sean transitables.

```ruby
# interpreter.rb
# #0168
def self.score_heuristic(map, config, candidate, context)
  # ... returns score between -1.0 and 1.0 ...
end
```

### #0169: Algoritmo de Desempate (Arbitraje Jerárquico)
**Algoritmo de Desempate**: La "última instancia" del juicio. Si tras evaluar heurísticas y futuros aún existen candidatos con la misma puntuación máxima, este algoritmo selecciona al ganador basándose en la prioridad estricta definida por el diseñador. Garantiza que el comportamiento del agente sea siempre resolutivo y nunca vacilante ante opciones equivalentes.

```ruby
# interpreter.rb
# #0169
def self.resolve_ties(winners, composite)
  highest_prio_intent = composite.intentions.select...
  # ...
end
```

### #0170: Solver Monotarea (Optimización de Flujo)
**Solver Monotarea**: Un pipeline de ejecución rápida para agentes con deseos simples. Si una IA solo tiene una intención (ej. caminar hacia un punto), este solver bypassa el arbitraje complejo y las simulaciones temporales para ahorrar ciclos de CPU. Es el camino de optimización para NPCs de bajo costo o comportamientos lineales.

```ruby
# interpreter.rb
# #0170
def self.solve_single(map, intention, context)
  case intention.type
  when :reach
    solve_reach(map, intention.payload, context)
  # ...
end
```

### #0171: Lógica de Alcance (Persecución Determinista)
**Lógica de Alcance (Reach)**: El algoritmo de navegación básica. Implementa una búsqueda Manhattan hacia el objetivo con validación de seguridad inmediata. Aunque es menos sofisticada que el arbitraje compuesto, garantiza que el agente siempre se mueva de forma productiva hacia su destino si el camino está despejado.

```ruby
# interpreter.rb
# #0171
def self.solve_reach(map, payload, context)
  # ... Manhattan-based step selection ...
end
```

### #0172: Generación de Candidatos (El Espacio de Posibilidades)
**Generación de Candidatos**: Identifica todas las opciones físicas del agente en el cuadro actual. Incluye los vecinos transitables y la opción de no moverse (`hold`). Al definir este conjunto al inicio del proceso táctico, se asegura que el intérprete solo evalúe acciones que son geográficamente posibles, ahorrando cálculos innecesarios en áreas bloqueadas.

```ruby
# interpreter.rb
# #0172
candidates = map.neighbors(context[:x], context[:y]) + [{...}]
```

### #0173: Filtrado por Restricción (Poda del Grafo)
**Filtrado por Restricción**: El proceso de eliminación de opciones ilegales. Aplica los vetos binarios de la `CompositeIntention` sobre los candidatos potenciales. Si un movimiento viola una restricción (ej. pisar una trampa), se elimina del conjunto de opciones antes de que llegue a la fase de puntuación, garantizando que el agente nunca considere acciones prohibidas.

```ruby
# interpreter.rb
# #0173
veted_by = {}
valid_candidates = candidates.reject do |cand|
  # ... check violates_constraint? ...
end
```

### #0178: Selector de Pipeline (Decisión de Arquitectura)
**Selector de Pipeline**: Una bifurcación lógica que elige el motor de razonamiento adecuado. Determina si el agente requiere la maquinaria pesada de arbitraje (Composite) o si puede resolverse de forma atómica (Single). Esta división técnica es clave para mantener un rendimiento alto en escenas con múltiples tipos de NPCs.

```ruby
# interpreter.rb
# #0178
if intention.is_a?(CompositeIntention)
  arbitrate(map, intention, context)
else
  solve_single(map, intention, context)
end
```

### #0179: Privacidad de Implementación (Encapsulamiento Táctico)
**Privacidad de Implementación**: Define el límite de lo que el programador de juego puede ver y tocar. Al marcar el arbitraje como `private`, el sistema asegura que la lógica de "cómo" se toma la decisión sea interna y protegida, exponiendo solo el método público `decide`. Es el "no tocar" en el plano arquitectónico.

```ruby
# interpreter.rb
# #0179
private
def self.arbitrate(map, composite, context)
  # ...
end
```

### #0180: Decisión de Espera Forzada (Seguridad por Omisión)
**Decisión de Espera Forzada**: Se emite cuando todas las opciones de movimiento han sido vetadas, ya sea por restricciones presentes o por riesgos futuros. En lugar de fallar o realizar un movimiento suicida, el sistema opta por el `hold`. Es la respuesta defensiva del arquitecto para evitar que la IA se rompa ante situaciones de atrapamiento.

```ruby
# interpreter.rb
# #0180
if valid_candidates.empty?
  return Decision.hold({ rule: :all_candidates_vetoed_future ... })
end
```

### #0183: Clase CompositeIntention (Contenedor de Voluntad)
**Clase CompositeIntention**: La estructura que permite comportamientos multidimensionales. Permite al desarrollador agrupar deseos competitivos (ej. "quiero ir a la salida PERO evitando el fuego"). Almacena pesos y prioridades, permitiendo que un agente tenga objetivos complejos sin perder la simplicidad de la interfaz inmutable de `Intention`.

```ruby
# intention.rb
# #0183
class CompositeIntention
  attr_reader :intentions
  def initialize(intentions = [])
    @intentions = intentions
  end
  # ...
end
```

### #0177: Sincronización de Versión (Protocolo de Verdad)
**Sincronización de Versión**: Un chequeo de seguridad de última milla. Garantiza que la IA no tome decisiones basadas en una versión obsoleta del mapa (lo cual ocurre durante un Hot-Reload). Si detecta un desajuste de versión, la decisión falla inmediatamente para evitar cálculos sobre un terreno que técnicamente ya no existe.

```ruby
# interpreter.rb
# #0177
if context[:required_version] && map.world_version != context[:required_version]
  # ... Decision.fail ...
end
```

### #0181: Decisión de Movimiento Validado (Salida de Éxito)
**Decisión de Movimiento Validado**: Se emite cuando un candidato supera todos los filtros y maximiza la puntuación. Esta decisión es el "plano de acción" que se entrega al motor de ejecución. Incluye metadatos sobre por qué fue elegida, permitiendo visualizaciones de debug que muestran el "hilo de pensamiento" de la IA.

```ruby
# interpreter.rb
# #0181
Decision.move_to(next_step[:x], next_step[:y], { 
  rule: :pathfinding_step,
  # ... metadata: avoided, distance ...
})
```
</details>

---

<details>
<summary>## 6. Módulo: Adapters & Utils (#0251 - #0350)</summary>

### #0251: Clase LDtkToDragonRuby (El Adaptador de Mundos)
**Clase LDtkToDragonRuby**: El puente de traducción entre los sistemas de coordenadas. LDtk usa una geometría orientada a archivos (Y-Down), mientras que DragonRuby usa una geometría orientada a cartesianos (Y-Up). Esta clase abstrae esa complejidad, permitiendo que el desarrollador piense en coordenadas lógicas sin preocuparse por la matemática de inversión de ejes.

```ruby
# ldtk_to_dr.rb
# #0251
class LDtkToDragonRuby
  # ...
end
```

### #0252: Inversión de Pantalla (Mapeo de Canvas)
**Inversión de Pantalla**: Aplica la matemática de conversión para posicionar elementos en el canvas de juego. Traduce la posición vertical de LDtk restándola de la altura total del mundo, resolviendo la discrepancia de origen (Top-Left vs Bottom-Left). Es el plano técnico para la correcta ubicación de sprites.

```ruby
# ldtk_to_dr.rb
# #0252
def screen_y(ldtk_py, tile_height)
  world_px_height - (ldtk_py) - tile_height
end
```

### #0253: Inversión de Textura (Lectura de Atlas)
**Inversión de Textura**: Matemática para mapear los puntos de origen dentro de un spritesheet. Debido a que DragonRuby lee las texturas desde la base hacia arriba, este nodo asegura que el recortado (cropping) de los tiles de LDtk sea exacto, evitando que se dibujen los tiles invertidos o desplazados.

```ruby
# ldtk_to_dr.rb
# #0253
def source_y(atlas_height, ldtk_src_y, tile_size)
  atlas_height - ldtk_src_y - tile_size
end
```

### #0201: HotReloadService (Vigilancia de Integridad)
**HotReloadService**: El centinela de la persistencia. Monitorea el archivo fuente de LDtk utilizando una estrategia híbrida de `mtime` (fecha de modificación) y `hash` de contenido. Esto asegura que el sistema detecte cambios incluso en sistemas de archivos que no actualizan metadatos con precisión. Cuando se detecta un cambio, dispara la invalidación del mundo, permitiendo una iteración de diseño en tiempo real sin reiniciar la aplicación.

```ruby
# main.rb (Sample)
# #0201
class HotReloadService
  def changed?(args)
    # ... mtime and hash comparison logic ...
  end
end
```

</details>

---

<details>
<summary>## [ En Desarrollo ]</summary>

### Próximamente: La Siguiente Capa
Este rango está reservado para la expansión futura de la librería. Se vislumbra como una capa de orquestación global y sistemas avanzados que potenciarán las capacidades actuales de Stargateldtk.

*Más detalles en futuras actualizaciones.*
</details>

---

## 🧭 Sistema de Marcadores Arquitectónicos

### Qué es un Marcador #NNNN

Los marcadores #NNNN NO son comentarios decorativos. Son **anclas de intención arquitectónica**.

Cada marcador representa:
- Una **decisión consciente**
- Un **límite estructural**  
- Un **punto de riesgo**

**NO explica** cómo funciona el código.  
**SÍ explica** por qué existe así y qué no debe cambiarse sin romper el sistema.

---

### Catálogo de Funciones Arquitectónicas

| Rango | Función Arquitectónica |
|-------|------------------------|
| #0001 | Punto de entrada / frontera |
| #0002 | Validación / zona de desconfianza |
| #0003 | Núcleo inmutable |
| #0004 | Decisión de formato |
| #0005 | Dependencia externa |
| #0006 | Transformación peligrosa |
| #0007 | Interpretación semántica |
| #0008 | Visual / no-canónico |
| #0009 | Ensamblado final |

---

### Reglas de Uso

**✅ CUÁNDO usar un #NNNN**:
- Antes de una clase importante
- Antes de un método peligroso
- En fronteras de responsabilidad
- En puntos que NO deben expandirse

**❌ CUÁNDO NO usarlo**:
- Para documentar lógica trivial
- En getters / setters
- En código obvio
- Como comentario decorativo

**Regla de oro**: Si todo tiene #0000, nada lo tiene.

---

### Contrato Arquitectónico

**Si mueves código con #0003 o #0002** y no actualizas este documento, has creado **deuda arquitectónica**.

**El número manda, no el código.**

Los marcadores definen:
- Qué puede cambiar
- Qué NO puede cambiar  
- Qué requiere decisión arquitectónica consciente

---

**Versión**: 0.8.0-alpha  
**Última actualización**: 2026-02-02  
**Estado**: Sellado y archivado
```
