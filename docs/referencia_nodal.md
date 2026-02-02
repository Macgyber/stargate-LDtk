# Referencia Nodal: Stargateldtk 🌐

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

## 1. Módulo: Bootstrap & Engine (#0001 - #0019)

````carousel
### #0010: Bootloader de Infraestructura
**Bootloader de Infraestructura**: Primer paso del ciclo de vida. Carga la definición de la clase `World`, estableciendo la estructura de datos sobre la cual operarán todos los demás módulos.
<!-- slide -->
```ruby
# bootstrap.rb
# #0010
require "lib/stargateldtk/core/world.rb"
```
````

````carousel
### #0011: Bootloader del Cargador
**Bootloader del Cargador**: Segundo paso del ciclo de vida. Carga la lógica de ingesta (`Loader`), permitiendo que el sistema comience a procesar archivos JSON de LDtk.
<!-- slide -->
```ruby
# bootstrap.rb
# #0011
require "lib/stargateldtk/core/loader.rb"
```
````

````carousel
### #0013: Carga de Analítica
**Carga de Analítica**: Integra el módulo `Analysis`, permitiendo que el `World` sea consultable topológicamente.
<!-- slide -->
```ruby
# bootstrap.rb
# #0013
require "lib/stargateldtk/analysis/spatial.rb"
```
````

````carousel
### #0014: Carga de Renderizado
**Carga de Renderizado**: Integra el módulo `Render`, desacoplando la lógica de la visualización.
<!-- slide -->
```ruby
# bootstrap.rb
# #0014
require "lib/stargateldtk/render/world_renderer.rb"
```
````

````carousel
### #0015: Carga de Tácticas
**Carga de Tácticas**: Integra el cerebro del sistema para el razonamiento de actores.
<!-- slide -->
```ruby
# bootstrap.rb
# #0015
require "lib/stargateldtk/tactics/intention.rb"
require "lib/stargateldtk/tactics/decision.rb"
require "lib/stargateldtk/tactics/temporal.rb"
require "lib/stargateldtk/tactics/interpreter.rb"
```
````

````carousel
### #0016: Carga de Adaptadores
**Carga de Adaptadores**: Carga las utilidades de conversión de coordenadas específicas para DragonRuby.
<!-- slide -->
```ruby
# bootstrap.rb
# #0016
require "lib/stargateldtk/adapters/ldtk_to_dr.rb"
```
````

````carousel
### #0012: Sello de Disponibilidad
**Sello de Disponibilidad**: Mensaje técnico en consola que confirma la versión del SDK y compatibilidad del entorno.
<!-- slide -->
```ruby
# bootstrap.rb
# #0012
puts "🌌 Stargateldtk v1.2: Inicializado."
```
````

---

## 2. Módulo: Core (#0020 - #0050)

````carousel
### #0002: Clase Loader (Motor de Ingesta)
**Clase Loader**: El punto de entrada transaccional del sistema. Traduce el JSON jerárquico y verboso de LDtk a un objeto `World` plano y optimizado. Su responsabilidad es filtrar el ruido del editor (metadatos de interfaz, capas ocultas) para entregar una estructura de datos pura que la IA pueda consumir sin overhead de parseo repetitivo. En esta fase (Fénix MVP) se enfoca en el procesamiento determinista del primer nivel (`levels[0]`).
<!-- slide -->
```ruby
# loader.rb
# #0002
class Loader
  def self.load(args, ldtk_json, version: 0)
    levels = ldtk_json["levels"] || []
    # ...
```
````

````carousel
### #0003: Estructura World (El Átomo de Datos)
**Estructura World**: La "Única Fuente de Verdad" (SSOT) del sistema. Es un objeto de datos estrictamente inmutable. Emplea un campo `version` (entero atómico) que funciona como un "Sello de Honestidad": cualquier cambio en el diseño del nivel resulta en un nuevo objeto con versión incrementada. Esto permite que los sistemas de análisis y renderizado detecten cambios en tiempo constante O(1) e invaliden sus cachés solo cuando es estrictamente necesario.
<!-- slide -->
```ruby
# world.rb
# #0003
class World
  attr_reader :id, :layout, :grids, :entities, :metadata, :version
  # ...
end
```
````

````carousel
### #0004: Extracción de gridSize (Resolución Espacial)
**Extracción de gridSize**: Define la granularidad del espacio lógico. El sistema busca primero el `__gridSize` específico de la capa superior para respetar la intención del diseñador, cayendo en el `defaultGridSize` del proyecto solo en su ausencia. Esta resolución es crítica porque determina la escala de todas las coordenadas de rejilla posteriores.
<!-- slide -->
```ruby
# loader.rb
# #0004
first_layer = (level["layerInstances"] || []).first
gsize = (first_layer ? first_layer["__gridSize"] : (ldtk_json["defaultGridSize"] || 16)).to_i
```
````

````carousel
### #0005: Normalización de Layout (Marco de Referencia)
**Normalización de Layout**: Establece las dimensiones absolutas del mundo tanto en píxeles como en unidades de rejilla. Al pre-calcular el `width` y `height` en celdas durante la carga, se eliminan divisiones costosas en tiempo de ejecución durante las fases de análisis espacial y tácticas. Es el contrato de límites para el resto de la tubería.
<!-- slide -->
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
````

````carousel
### #0006: Filtro de Capas (Separación de Preocupaciones)
**Filtro de Capas**: Proceso de clasificación selectiva. Discrimina entre capas de entidades (lógica pura) y capas de rejilla (visual/topológica). Esto permite que el sistema de IA ignore el ruido de tiles puramente decorativos mientras que el renderizador ignora metadatos de comportamiento, optimizando el consumo de memoria y la velocidad de iteración.
<!-- slide -->
```ruby
# loader.rb
# #0006
grids = []
entities = []
(level["layerInstances"] || []).each do |layer|
  if layer["__type"] == "Entities"
    # ...
```
````

````carousel
### #0007: Diccionario de Entidades (Persistencia y Semántica)
**Diccionario de Entidades**: Captura la identidad y el estado de los actores. Utiliza el `iid` (Global Unique ID de LDtk) para asegurar que una entidad pueda mantener su estado (ej. vida, inventario) incluso si el mundo se recarga por Hot-Reload. Los `fields` permiten inyectar parámetros de comportamiento personalizados directamente desde el editor de niveles sin tocar una línea de código.
<!-- slide -->
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
````

````carousel
### #0008: Traducción de Rejillas (Compresión de Atlas)
**Traducción de Rejillas**: Transforma los datos verbosos de tiles de LDtk en objetos `Grid` ligeros. Extrae solo los punteros necesarios: posición en pantalla (`px`) y posición en el atlas fuente (`src`). Al ignorar flags de flipping o rotación complejos no esenciales para la lógica, reduce el footprint de datos del mapa en memoria.
<!-- slide -->
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
````

````carousel
### #0009: Consolidación y Sellado (Freeze Final)
**Consolidación y Sellado**: El acto final del cargador. Ensambla todas las partes analizadas en una instancia de `World`. Al pasar la `version` actual, se sella el estado del universo para ese cuadro de ejecución. Este patrón garantiza que ninguna parte del código pueda mutar accidentalmente el mapa a mitad de un ciclo táctico, manteniendo la integridad referencial absoluta.
<!-- slide -->
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
````

---

## 3. Módulo: Analysis (#0051 - #0100)

````carousel
### #0051: Clase Spatial (Motor de Síntesis Topológica)
**Clase Spatial**: El orquestador de la interpretación espacial. Su función es "mirar" la estructura inmutable del `World` y derivar de ella un `LogicalMap`. Este proceso es puramente funcional y carece de efectos secundarios; no altera el mundo, sino que genera una capa cognitiva que permite a otros sistemas razonar sobre la geometría del nivel sin conocer los detalles técnicos de LDtk.
<!-- slide -->
```ruby
# spatial.rb
# #0051
class Spatial
  def self.analyze(world, config = {})
    # ...
```
````

````carousel
### #0052: Especificación Semántica (El Diccionario de la Verdad)
**Especificación Semántica**: Define el contrato de significado entre el arte y la lógica. Mapea los IDs numéricos crudos del IntGrid de LDtk a símbolos semánticos legibles por humanos (ej. `:empty`, `:solid`, `:hazard`). Esta abstracción es fundamental para que el intérprete táctico pueda tomar decisiones basadas en "conceptos" en lugar de "números mágicos", permitiendo que el diseño del juego evolucione sin romper la IA.
<!-- slide -->
```ruby
# spatial.rb
# #0052
class SemanticSpecification
  attr_reader :mapping
  def initialize(mapping)
    @mapping = mapping
  end
  # ...
end
```
````

````carousel
### #0053: Verificación Causal (Defensa del Runtime)
**Verificación Causal**: Un mecanismo de "Falla Rápida" (Fail-Fast). Si el sistema no encuentra la capa de colisión solicitada, lanza una excepción inmediata. Esto previene que la IA opere en un "vacío lógico" donde todo parece transitable, lo cual resultaría en comportamientos erráticos difíciles de depurar. Es el guardián de la integridad del razonamiento espacial.
<!-- slide -->
```ruby
# spatial.rb
# #0053
raise "Spatial Analysis Error: Grid '#{grid_id}' not found..." unless collision_grid
```
````

````carousel
### #0058: Validación Estructural (Sanidad de Memoria)
**Validación Estructural**: Un protocolo de seguridad que garantiza que la cantidad de datos en el buffer coincida exactamente con el área declarada (`cols * rows`). Esta verificación previene errores de "fuera de límites" (Out-of-Bounds) durante consultas tácticas de alta frecuencia, asegurando que el índice lineal de la topología sea siempre consistente con el layout del mundo.
<!-- slide -->
```ruby
# spatial.rb
# #0058
def self.validate_world!(world)
  world.grids.each do |grid|
    expected_size = grid.size[:cols] * grid.size[:rows]
    if grid.data.size != expected_size
      raise "Error: Grid size mismatch..."
    end
  end
end
```
````

````carousel
### #0059: Instanciación de Especificación (Carga de Reglas)
**Instanciación de Especificación**: Carga el mapeo semántico derivado de la configuración. Si no se provee ninguno, asume un entorno vacío por defecto para pruebas de estrés. Es el momento en que el sistema decide "cómo se siente" cada celda del mapa, estableciendo las leyes físicas (transitabilidad) del entorno.
<!-- slide -->
```ruby
# spatial.rb
# #0059
contract = SemanticSpecification.new(config[:mapping] || { 0 => :empty })
```
````

````carousel
### #0060: Resolución de Capa Lógica (Identificación de Colisión)
**Resolución de Capa Lógica**: Busca dinámicamente la capa que servirá como base para el grafo de movimiento. Por convención, busca una capa llamada "Collision". Este punto conecta el diseño visual del artista en LDtk con el motor de IA, permitiendo que cambios en el editor se reflejen instantáneamente en el comportamiento sin recompilar lógica.
<!-- slide -->
```ruby
# spatial.rb
# #0060
grid_id = config[:collision_grid] || "Collision"
collision_grid = world.grids.find { |g| g.identifier == grid_id }
```
````

````carousel
### #0061: Extracción de Topología (Síntesis de Significado)
**Extracción de Topología**: El proceso de "cocción" de datos. Itera sobre el grid numérico y consulta la especificación semántica para cada tile. El resultado es un array de símbolos de alto nivel optimizado para consultas rápidas. Esta síntesis es lo que permite que el `LogicalMap` responda a preguntas como "¿puedo caminar aquí?" en microsegundos.
<!-- slide -->
```ruby
# spatial.rb
# #0061
topology = extract_topology(collision_grid, contract)
```
````

````carousel
### #0054: LogicalMap (El Marco Cognitivo Estático)
**LogicalMap**: El producto final del análisis. Es un objeto "Read-Only" que representa la memoria espacial del sistema. Almacena la topología ya procesada y la versión del mundo correspondiente. Esto garantiza que cualquier decisión tomada por una IA esté basada en una "fotografía" coherente y válida del entorno, evitando inconsistencias durante el Hot-Reload.
<!-- slide -->
```ruby
# spatial.rb
# #0054
LogicalMap.new(
  world: world,
  topology: topology,
  contract: contract
)
```
````

````carousel
### #0055: Indexación Espacial (Localidad O(1))
**Indexación Espacial**: Una estructura de datos de aceleración. Organiza todas las entidades del mundo en un mapa de calor posicional (Hash). Esto permite que preguntas como "¿qué enemigos están en esta celda específica?" se respondan instantáneamente sin tener que recorrer toda la lista de entidades, permitiendo escalar a cientos de agentes sin degradar el rendimiento.
<!-- slide -->
```ruby
# spatial.rb
# #0055
def build_spatial_index!
  @spatial_index = {}
  @entities.each do |e|
    gx, gy = e.pos[:grid_x], e.pos[:grid_y]
    @spatial_index[[gx, gy]] ||= []
    @spatial_index[[gx, gy]] << e
  end
end
```
````

````carousel
### #0056: Cálculo de Distancia (Camino de Mínima Resistencia)
**Cálculo de Distancia**: Implementación de un algoritmo de búsqueda de rutas (BFS) deterministicos. A diferencia de una distancia euclidiana simple, este cálculo respeta las paredes y obstáculos del `LogicalMap`. Es la métrica central que usa la IA para evaluar cuán "cerca" está realmente de un objetivo, considerando la topología real del terreno.
<!-- slide -->
```ruby
# spatial.rb
# #0056
def distance(x1, y1, x2, y2)
  queue = [[x1, y1, 0]]
  # ... BFS algorithm implementation ...
end
```
````

````carousel
### #0057: Cálculo de Vecindad (Discernimiento de Adyacencia)
**Cálculo de Vecindad**: Determina los movimientos legales inmediatos desde una celda. Aplica de forma atómica tres filtros: límites del mapa, existencia de la celda y transitabilidad lógica. Es el componente que define las "opciones" de un agente en cada paso de su simulación táctica.
<!-- slide -->
```ruby
# spatial.rb
# #0057
def neighbors(gx, gy)
  [[0, 1], [0, -1], [1, 0], [-1, 0]].map do |dx, dy|
    nx, ny = gx + dx, gy + dy
    # ... boundary checks ...
  end.compact
end
```
````

---

## 4. Módulo: Render (#0101 - #0150)

````carousel
### #0101: Clase WorldRenderer (Observador Pasivo)
**Clase WorldRenderer**: El componente de salida visual. Sigue el patrón de "Observación Pura": no posee estado propio ni conoce las leyes de colisión o IA. Su única función es iterar sobre la "Fuente de Verdad" (`World`) y generar una cola de primitivas gráficas. Este desacoplamiento garantiza que los errores en la visualización nunca corrompan la lógica del juego.
<!-- slide -->
```ruby
# world_renderer.rb
# #0101
class WorldRenderer
  def self.draw(args, world, camera = nil)
    # ...
```
````

````carousel
### #0102: Purga de Buffer (Línea Base Determinista)
**Purga de Buffer**: El primer paso de cada cuadro de renderizado. Dibuja un rectángulo sólido que cubre todo el canvas (1280x720). Esto elimina cualquier rastro del cuadro anterior (efecto ghosting) y establece un fondo neutro, garantizando que la representación visual sea siempre una traducción fresca y exacta del estado actual del mundo.
<!-- slide -->
```ruby
# world_renderer.rb
# #0102
args.outputs.primitives << { 
  x: 0, y: 0, w: 1280, h: 720, 
  r: 0, g: 0, b: 0, 
  primitive_marker: :solid 
}
```
````

````carousel
### #0103: Normalización de Cámara (Transformación de Proyección)
**Normalización de Cámara**: Calcula los parámetros de visualización. Extrae las coordenadas de desplazamiento (`cam_x/y`) y el factor de `zoom`. Estos valores son fundamentales para convertir las coordenadas absolutas del mundo en coordenadas relativas de pantalla, permitiendo efectos de scroll y escalado sin afectar la lógica de rejilla subyacente.
<!-- slide -->
```ruby
# world_renderer.rb
# #0103
cam_x = camera ? camera[:x] : 0
# ...
zoom  = camera ? camera[:zoom] : 1.0
```
````

````carousel
### #0104: Bucle de Renderizado (Secuenciación Z-Order)
**Bucle de Renderizado**: Gestiona la jerarquía visual de profundidad. Primero dibuja las rejillas (el entorno estático) y luego las entidades (objetos dinámicos). Esta secuenciación manual de DragonRuby asegura que los personajes siempre se vean por encima del terreno, eliminando la necesidad de un sistema de profundidad complejo para escenarios 2D simples.
<!-- slide -->
```ruby
# world_renderer.rb
# #0104
world.grids.each { |grid| draw_debug_grid(args, grid, zoom, cam_x, cam_y) }
world.entities.each { |entity| draw_entity(args, entity, zoom, cam_x, cam_y) }
```
````

````carousel
### #0105: Proyección de Entidades (Matemática de Pantalla)
**Proyección de Entidades**: La fórmula de transformación final. Mapea la posición de una entidad en el mundo a píxeles de pantalla. Utiliza el punto central `640/360` para pivotar la cámara y aplica el `zoom` de forma multiplicativa. Es el "plano" técnico que dicta exactamente dónde debe aparecer un actor en la ventana del jugador.
<!-- slide -->
```ruby
# world_renderer.rb
# #0105
def self.draw_entity(args, entity, zoom, cam_x, cam_y)
  sx = (entity.pos[:x] - cam_x) * zoom + 640
  sy = 360 - (entity.pos[:y] - cam_y) * zoom
  # ...
end
```
````

---

## 5. Módulo: Tactics (#0151 - #0250)

````carousel
### #0151: Clase Intention (El Deseo Inmutable)
**Clase Intention**: Representa el "qué" quiere hacer un agente. Es un objeto de datos inmutable que encapsula un tipo de deseo (ej. alcanzar un punto, evitar un peligro) y los parámetros necesarios para evaluarlo. Al ser inmutable, permite que el sistema táctico compare múltiples intenciones sin riesgo de efectos secundarios cruzados.
<!-- slide -->
```ruby
# intention.rb
# #0151
class Intention
  attr_reader :type, :payload
  # ...
end
```
````

````carousel
### #0152: Clase Decision (La Salida Auditable)
**Clase Decision**: El resultado final del razonamiento. No es solo una instrucción de movimiento; es un paquete de datos que incluye la justificación técnica (`reason`). Esta trazabilidad es lo que permite a los desarrolladores entender *por qué* una IA decidió moverse o quedarse quieta, transformando la caja negra del comportamiento en una serie de pasos lógicos auditables.
<!-- slide -->
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
````

````carousel
### #0155: Constructor move_to
**Constructor move_to**: Factory method para crear decisiones de movimiento validadas con justificación técnica.
<!-- slide -->
```ruby
# decision.rb
# #0155
def self.move_to(gx, gy, reason)
  Decision.new(type: :move, payload: { x: gx, y: gy }, reason: reason)
end
```
````

````carousel
### #0153 & #0157: Evaluador Temporal (Simulación de Futuros)
**Evaluador Temporal**: El motor de "instinto" del sistema. Antes de comprometerse con un movimiento, el evaluador simula un árbol de consecuencias futuras (Horizonte `H`). Calcula si un paso aparentemente seguro hoy no llevará a un callejón sin salida mañana. Es el componente que otorga a los agentes una apariencia de inteligencia preventiva.
<!-- slide -->
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
````

````carousel
### #0154: Intérprete de Tácticas (El Árbitro Central)
**Intérprete de Tácticas**: El núcleo del cerebro. Su función es recibir un `LogicalMap` y un conjunto de intenciones, y arbitrar entre ellas para producir la mejor decisión posible. Utiliza una tubería de evaluación que combina restricciones binarias (vetos) y heurísticas ponderadas, asegurando que la acción resultante sea siempre la más óptima bajo el contrato actual.
<!-- slide -->
```ruby
# interpreter.rb
# #0154
class Interpreter
  def self.decide(map, intention, context = {})
    # ...
  end
end
```
````

````carousel
### #0158: Análisis de Seguridad Futura (Escaneo de Nodos)
**Análisis de Seguridad Futura**: Durante la simulación temporal, este nodo examina cada celda proyectada. Comprueba las etiquetas lógicas del mapa (`tag_at`) en cuadros futuros para identificar peligros estáticos o zonas restringidas que el agente debe evitar en su trayectoria de planificación.
<!-- slide -->
```ruby
# temporal.rb
# #0158
visit_queue = frontier
visited = { [cand_node[:x], cand_node[:y]] => true }
# ...
node = { x: cx, y: cy, tag: map.tag_at(cx, cy) }
```
````

````carousel
### #0159: Veto por Supervivencia (Prevención de Atrapamiento)
**Veto por Supervivencia**: El filtro de seguridad más crítico. Aunque una celda parezca segura en el presente (`T+0`), este nodo la descarta si la simulación futura demuestra que no hay "salidas seguras" posibles desde ella en el horizonte `H`. Evita que la IA entre en celdas de las que no podrá escapar, actuando como un instinto de autopreservación que prioriza la libertad de movimiento a largo plazo.
<!-- slide -->
```ruby
# temporal.rb
# #0159
if has_safe_out?(map, composite, node)
  can_survive = true
  # ...
end
```
````

````carousel
### #0160: Expansión BFS Temporal (Exploración de Ramas)
**Expansión BFS Temporal**: El método de búsqueda para la predicción. Explora recursivamente los vecinos válidos de cada nodo proyectado para construir una red de consecuencias posibles. A diferencia de un A* tradicional, aquí no buscamos el camino más corto, sino que escaneamos densamente el entorno cercano para evaluar la "seguridad media" de una dirección elegida.
<!-- slide -->
```ruby
# temporal.rb
# #0160
map.neighbors(cx, cy).each do |n|
  # ... logic to check future constraints ...
  visit_queue << [n[:x], n[:y], d + 1]
end
```
````

````carousel
### #0161: Confirmación de Salida Segura (Seguro Anti-Veto)
**Confirmación de Salida Segura**: Un sub-proceso binario que valida la viabilidad de un estado proyectado. Verifica si el agente tiene al menos una opción de movimiento legal (o la opción de esperar) que no viole ninguna restricción dura al final de la trayectoria. Es lo que garantiza que el agente nunca "se rinda" en su simulación interna.
<!-- slide -->
```ruby
# temporal.rb
# #0161
def self.has_safe_out?(map, composite, node)
  # ... any? neighbor is NOT vetoed by constraint ...
end
```
````

````carousel
### #0162: Puntuación de Estado Futuro (Cálculo de Potencial)
**Puntuación de Estado Futuro**: Agrega el beneficio acumulado de las heurísticas en el nodo final de la simulación. Permite que la IA compare dos direcciones seguras y elija aquella que, estadísticamente, la deja en una posición más ventajosa (ej. más cerca del objetivo o más lejos del peligro) al final del horizonte temporal.
<!-- slide -->
```ruby
# temporal.rb
# #0162
def self.score_state(map, composite, node, context)
  # ... aggregates scores from heuristics ...
end
```
````

````carousel
### #0163: Métrica de Proximidad (Vector de Intento)
**Métrica de Proximidad**: El corazón de la persecución. Mide la delta entre la distancia actual al objetivo y la distancia proyectada. Premia con puntuación positiva los movimientos que reducen esta distancia, creando un gradiente de atracción hacia el objetivo que guía el comportamiento del agente de forma determinista.
<!-- slide -->
```ruby
# temporal.rb
# #0163
dist = map.distance(node[:x], node[:y], target[:x], target[:y])
current_dist = map.distance(context[:x], context[:y], ...)
```
````

````carousel
### #0164: Integración Causal (Puente Presente-Futuro)
**Integración Causal**: El punto de unión en el intérprete donde los datos del simulador temporal se inyectan en la evaluación de cada candidato actual. Transforma la validación binaria de supervivencia y la puntuación de potencial futuro en variables utilizables por la sumatoria de arbitraje, permitiendo una toma de decisiones informada y coherente.
<!-- slide -->
```ruby
# interpreter.rb
# #0164
is_valid, future_score, veto_reason = Temporal.evaluate(...)
```
````

````carousel
### #0165: Arbitraje Ponderado (La Ecuación de Decisión)
**Arbitraje Ponderado**: La lógica matemática final. Suma las heurísticas del presente (acción inmediata) con el beneficio esperado del futuro (potencial proyectado), aplicando un factor de descuento `gamma`. Los `weights` (pesos) permiten que el diseñador dé más importancia a ciertas intenciones sobre otras, definiendo la personalidad táctica del agente.
<!-- slide -->
```ruby
# interpreter.rb
# #0165
scores[cand] = present_score + (temporal_scores[cand] || 0.0)
```
````

````carousel
### #0166: Resolución de Empates (Arbitraje de Prioridad)
**Resolución de Empates**: El mecanismo de desempate determinista. Cuando dos o más movimientos tienen exactamente la misma puntuación máxima, esta lógica analiza cuál de ellos favorece más a la intención de mayor prioridad jerárquica. Esto elimina la aleatoriedad en el comportamiento, asegurando que la IA siempre sea predecible ante las mismas condiciones.
<!-- slide -->
```ruby
# interpreter.rb
# #0166
final_winner = winners.size > 1 ? resolve_ties(winners, composite) : winners.first
```
````

````carousel
### #0167: Validador de Restricciones (El Filtro de Acero)
**Validador de Restricciones**: Un motor de lógica booleana que aplica las reglas innegociables del comportamiento. Evalúa si un candidato viola una prohibición explícita (ej. no pisar lava). Si se detecta una violación, el candidato se veta de inmediato, sin importar cuán prometedor sea en otros aspectos, estableciendo los límites éticos/físicos de la IA.
<!-- slide -->
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
````

````carousel
### #0168: Calculador de Heurísticas (Evaluación de Beneficio)
**Calculador de Heurísticas**: El motor de puntuación continua. A diferencia de las restricciones binarias, las heurísticas devuelven un valor en el rango de `-1.0` a `1.0`, indicando cuán "deseable" es un movimiento. Permite que la IA compare matices sutiles entre varias opciones seguras, como elegir el camino que la acerca más al objetivo aunque ambos sean transitables.
<!-- slide -->
```ruby
# interpreter.rb
# #0168
def self.score_heuristic(map, config, candidate, context)
  # ... returns score between -1.0 and 1.0 ...
end
```
````

````carousel
### #0169: Algoritmo de Desempate (Arbitraje Jerárquico)
**Algoritmo de Desempate**: La "última instancia" del juicio. Si tras evaluar heurísticas y futuros aún existen candidatos con la misma puntuación máxima, este algoritmo selecciona al ganador basándose en la prioridad estricta definida por el diseñador. Garantiza que el comportamiento del agente sea siempre resolutivo y nunca vacilante ante opciones equivalentes.
<!-- slide -->
```ruby
# interpreter.rb
# #0169
def self.resolve_ties(winners, composite)
  highest_prio_intent = composite.intentions.select...
  # ...
end
```
````

````carousel
### #0170: Solver Monotarea (Optimización de Flujo)
**Solver Monotarea**: Un pipeline de ejecución rápida para agentes con deseos simples. Si una IA solo tiene una intención (ej. caminar hacia un punto), este solver bypassa el arbitraje complejo y las simulaciones temporales para ahorrar ciclos de CPU. Es el camino de optimización para NPCs de bajo costo o comportamientos lineales.
<!-- slide -->
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
````

````carousel
### #0171: Lógica de Alcance (Persecución Determinista)
**Lógica de Alcance (Reach)**: El algoritmo de navegación básica. Implementa una búsqueda Manhattan hacia el objetivo con validación de seguridad inmediata. Aunque es menos sofisticada que el arbitraje compuesto, garantiza que el agente siempre se mueva de forma productiva hacia su destino si el camino está despejado.
<!-- slide -->
```ruby
# interpreter.rb
# #0171
def self.solve_reach(map, payload, context)
  # ... Manhattan-based step selection ...
end
```
````

````carousel
### #0172: Generación de Candidatos (El Espacio de Posibilidades)
**Generación de Candidatos**: Identifica todas las opciones físicas del agente en el cuadro actual. Incluye los vecinos transitables y la opción de no moverse (`hold`). Al definir este conjunto al inicio del proceso táctico, se asegura que el intérprete solo evalúe acciones que son geográficamente posibles, ahorrando cálculos innecesarios en áreas bloqueadas.
<!-- slide -->
```ruby
# interpreter.rb
# #0172
candidates = map.neighbors(context[:x], context[:y]) + [{...}]
```
````

````carousel
### #0173: Filtrado por Restricción (Poda del Grafo)
**Filtrado por Restricción**: El proceso de eliminación de opciones ilegales. Aplica los vetos binarios de la `CompositeIntention` sobre los candidatos potenciales. Si un movimiento viola una restricción (ej. pisar una trampa), se elimina del conjunto de opciones antes de que llegue a la fase de puntuación, garantizando que el agente nunca considere acciones prohibidas.
<!-- slide -->
```ruby
# interpreter.rb
# #0173
vetoed_by = {}
valid_candidates = candidates.reject do |cand|
  # ... check violates_constraint? ...
end
```
````

````carousel
### #0178: Selector de Pipeline (Decisión de Arquitectura)
**Selector de Pipeline**: Una bifurcación lógica que elige el motor de razonamiento adecuado. Determina si el agente requiere la maquinaria pesada de arbitraje (Composite) o si puede resolverse de forma atómica (Single). Esta división técnica es clave para mantener un rendimiento alto en escenas con múltiples tipos de NPCs.
<!-- slide -->
```ruby
# interpreter.rb
# #0178
if intention.is_a?(CompositeIntention)
  arbitrate(map, intention, context)
else
  solve_single(map, intention, context)
end
```
````

````carousel
### #0179: Privacidad de Implementación (Encapsulamiento Táctico)
**Privacidad de Implementación**: Define el límite de lo que el programador de juego puede ver y tocar. Al marcar el arbitraje como `private`, el sistema asegura que la lógica de "cómo" se toma la decisión sea interna y protegida, exponiendo solo el método público `decide`. Es el "no tocar" en el plano arquitectónico.
<!-- slide -->
```ruby
# interpreter.rb
# #0179
private
def self.arbitrate(map, composite, context)
  # ...
end
```
````

````carousel
### #0180: Decisión de Espera Forzada (Seguridad por Omisión)
**Decisión de Espera Forzada**: Se emite cuando todas las opciones de movimiento han sido vetadas, ya sea por restricciones presentes o por riesgos futuros. En lugar de fallar o realizar un movimiento suicida, el sistema opta por el `hold`. Es la respuesta defensiva del arquitecto para evitar que la IA se rompa ante situaciones de atrapamiento.
<!-- slide -->
```ruby
# interpreter.rb
# #0180
if valid_candidates.empty?
  return Decision.hold({ rule: :all_candidates_vetoed_future ... })
end
```
````

````carousel
### #0183: Clase CompositeIntention (Contenedor de Voluntad)
**Clase CompositeIntention**: La estructura que permite comportamientos multidimensionales. Permite al desarrollador agrupar deseos competitivos (ej. "quiero ir a la salida PERO evitando el fuego"). Almacena pesos y prioridades, permitiendo que un agente tenga objetivos complejos sin perder la simplicidad de la interfaz inmutable de `Intention`.
<!-- slide -->
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
````

````carousel
### #0177: Sincronización de Versión (Protocolo de Verdad)
**Sincronización de Versión**: Un chequeo de seguridad de última milla. Garantiza que la IA no tome decisiones basadas en una versión obsoleta del mapa (lo cual ocurre durante un Hot-Reload). Si detecta un desajuste de versión, la decisión falla inmediatamente para evitar cálculos sobre un terreno que técnicamente ya no existe.
<!-- slide -->
```ruby
# interpreter.rb
# #0177
if context[:required_version] && map.world_version != context[:required_version]
  # ... Decision.fail ...
end
```
````

````carousel
### #0181: Decisión de Movimiento Validado (Salida de Éxito)
**Decisión de Movimiento Validado**: Se emite cuando un candidato supera todos los filtros y maximiza la puntuación. Esta decisión es el "plano de acción" que se entrega al motor de ejecución. Incluye metadatos sobre por qué fue elegida, permitiendo visualizaciones de debug que muestran el "hilo de pensamiento" de la IA.
<!-- slide -->
```ruby
# interpreter.rb
# #0181
Decision.move_to(next_step[:x], next_step[:y], { 
  rule: :pathfinding_step,
  # ... metadata: avoided, distance ...
})
```
````

---

## 6. Módulo: Adapters & Utils (#0251 - #0350)

````carousel
### #0251: Clase LDtkToDragonRuby (El Adaptador de Mundos)
**Clase LDtkToDragonRuby**: El puente de traducción entre los sistemas de coordenadas. LDtk usa una geometría orientada a archivos (Y-Down), mientras que DragonRuby usa una geometría orientada a cartesianos (Y-Up). Esta clase abstrae esa complejidad, permitiendo que el desarrollador piense en coordenadas lógicas sin preocuparse por la matemática de inversión de ejes.
<!-- slide -->
```ruby
# ldtk_to_dr.rb
# #0251
class LDtkToDragonRuby
  # ...
end
```
````

````carousel
### #0252: Inversión de Pantalla (Mapeo de Canvas)
**Inversión de Pantalla**: Aplica la matemática de conversión para posicionar elementos en el canvas de juego. Traduce la posición vertical de LDtk restándola de la altura total del mundo, resolviendo la discrepancia de origen (Top-Left vs Bottom-Left). Es el plano técnico para la correcta ubicación de sprites.
<!-- slide -->
```ruby
# ldtk_to_dr.rb
# #0252
def screen_y(ldtk_py, tile_height)
  world_px_height - (ldtk_py) - tile_height
end
```
````

````carousel
### #0253: Inversión de Textura (Lectura de Atlas)
**Inversión de Textura**: Matemática para mapear los puntos de origen dentro de un spritesheet. Debido a que DragonRuby lee las texturas desde la base hacia arriba, este nodo asegura que el recortado (cropping) de los tiles de LDtk sea exacto, evitando que se dibujen los tiles invertidos o desplazados.
<!-- slide -->
```ruby
# ldtk_to_dr.rb
# #0253
def source_y(atlas_height, ldtk_src_y, tile_size)
  atlas_height - ldtk_src_y - tile_size
end
```
````

````carousel
### #0201: HotReloadService (Vigilancia de Integridad)
**HotReloadService**: El centinela de la persistencia. Monitorea el archivo fuente de LDtk utilizando una estrategia híbrida de `mtime` (fecha de modificación) y `hash` de contenido. Esto asegura que el sistema detecte cambios incluso en sistemas de archivos que no actualizan metadatos con precisión. Cuando se detecta un cambio, dispara la invalidación del mundo, permitiendo una iteración de diseño en tiempo real sin reiniciar la aplicación.
<!-- slide -->
```ruby
# main.rb (Sample)
# #0201
class HotReloadService
  def changed?(args)
    # ... mtime and hash comparison logic ...
  end
end
```
````

````carousel
### #0301: Clase Executor (La Mano del Destino)
**Clase Executor**: El único componente con permiso para mutar el estado. Actúa como el puente final entre el pensamiento (Decisión) y la realidad (Estado). Su responsabilidad es aplicar físicamente los resultados del razonamiento táctico sobre los actores del mundo, garantizando que el estado del juego se mantenga sincronizado con las intenciones validadas por el cerebro.
<!-- slide -->
```ruby
# executor.rb
# #0301
class Executor
  def self.apply(decision, actor, args)
    # ...
  end
end
```
````

````carousel
### #0302: Despachador de Comandos (Dispatch de Acción)
**Despachador de Comandos**: Implementa el patrón "Command" para la ejecución de acciones. Traduce el tipo de decisión (`:move`, `:hold`, `:fail`) en una rama de ejecución atómica. Este desacoplamiento permite que el sistema de ejecución crezca con nuevos tipos de acciones sin afectar la lógica del intérprete táctico, manteniendo los "planos" limpios y modulares.
<!-- slide -->
```ruby
# executor.rb
# #0302
case decision.type
when :move
  execute_move(decision.payload, actor, args)
# ...
end
```
````

````carousel
### #0303: Mutación de Coordenadas (Actualización del Mundo)
**Mutación de Coordenadas**: El acto físico de mover a un actor. Actualiza las coordenadas de rejilla (`grid_x/y`) en el objeto de datos del actor. Este es el punto crítico donde la decisión de la IA se manifiesta en el mundo del juego, permitiendo que el siguiente cuadro de renderizado muestre al personaje en su nueva posición física.
<!-- slide -->
```ruby
# executor.rb
# #0303
actor[:grid_x] = payload[:x]
actor[:grid_y] = payload[:y]
```
````

````carousel
### #0304: Trazabilidad y Diagnóstico (Persistencia de Decisión)
**Trazabilidad y Diagnóstico**: Almacena una copia de la decisión aplicada dentro del propio actor. Esto crea un "Diario de Vuelo" que puede ser consultado por HUDs de debug o procesos de telemetría para entender qué estaba pensando el actor en su última acción. Es la herramienta de diagnóstico definitiva para el arquitecto, permitiendo una auditoría post-mortem de cualquier comportamiento inesperado.
<!-- slide -->
```ruby
# executor.rb
# #0304
actor[:last_decision] = { type: :move, x: payload[:x], y: payload[:y] }
```
````

---

## 7. Módulo: Sistemas Globales & Futuro (#1000+)
*Responsabilidad: Orquestación a macro-escala y diagnóstico.*

### #1000
**Reserva de Arquitectura Global**: Rango destinado a componentes de gestión de estado global, orquestadores de múltiples niveles y motores de diagnóstico proactivo. Define el horizonte de expansión para la v2.0 del SDK.
