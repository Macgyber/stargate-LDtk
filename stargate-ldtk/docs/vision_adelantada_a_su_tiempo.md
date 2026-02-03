# 🌌 Stargate — Visión del Futuro

> **Estado:** Archivado con honores · Visión preservada
>
> **Motivo:** Idea demasiado potente para ejecutarse con prisa. Reservada para el momento correcto.

---

## 🧭 Identidad Nuclear (Una Frase)

**Stargate es un formato de datos y un runtime de referencia que garantizan decisiones tácticas 2D deterministas, reproducibles y auditables, separados del motor de juego.**

Nada más. Nada menos.

---

## 🧠 La Idea Central

Stargate no es un motor, ni un editor, ni un framework.

Es una **idea radical**:

> Separar completamente el **razonamiento táctico** del **estado del juego**, y demostrar que ese razonamiento puede ser **puro, determinista y reproducible bit a bit** a partir de datos.

Esto permite:

* Replay perfecto
* Debugging con viaje en el tiempo
* IA auditable
* Sincronización de red sin drift
* Decisiones explicables y testeables

---

## ⚖️ Separación Constitucional

### 🏛️ Spec (Intocable)

* Schema JSON del formato canónico
* Reglas semánticas del mapa
* Invariantes (qué SIEMPRE debe cumplirse)
* Cambios lentos, retrocompatibles, conservadores

### ⚙️ Runtime de Referencia (Evolutivo)

* Análisis espacial
* Motor táctico puro
* Importadores (LDtk, Tiled, custom)
* Cambios rápidos, mejorable, puede tener bugs sin cuestionar la spec

---

## 🧱 Principios Fundamentales

### 1️⃣ Determinismo Total

Mismos datos + misma intención + mismo contexto = **Siempre la misma decisión**

### 2️⃣ Datos Puros, Decisiones Puras

El motor táctico NO muta estado, NO renderiza, NO mueve actores, NO depende del motor.

Solo: `(datos de entrada) → decisión`

### 3️⃣ Inmutabilidad como Contrato

Las estructuras son `frozen`, no se modifican, se reemplazan.

### 4️⃣ Separación de Confianza

1. **Untrusted** — input externo
2. **Imported** — pasó importador tolerante
3. **Validated** — pasó schema + semántica
4. **Canonical** — core inmutable

---

## 📚 Auditoría Completa: 41 Críticas Identificadas

### Nivel 1: Técnicas (1-20)

1. Rutas hardcodeadas incorrectas
2. Inconsistencia de nomenclatura
3. Falta de namespacing consistente
4. Acoplamiento temporal implícito
5. Falta de validación de entrada
6. Indentación inconsistente
7. Métodos privados mal ubicados
8. Números mágicos sin constantes
9. BFS sin caché en hot path
10. Reconstrucción innecesaria de arrays
11. Iteración múltiple sobre misma colección
12. Falta de manejo de errores
13. División por cero potencial
14. API inconsistente de factories
15. Mutabilidad de CompositeIntention
16. Comentarios nodales incompletos
17. Falta de ejemplos de uso
18. Ausencia total de tests
19. Configuración hardcodeada
20. Dependencia implícita de DragonRuby

### Nivel 2: Arquitectónicas (21-36)

21. **Crisis de identidad ontológica**
22. **Acoplamiento silencioso a LDtk**
23. **El "Vigilante" mal ubicado**
24. **Contratos implícitos**
25. **El editor imaginado**
26. **Modo táctico difuso**
27. **Documentación insuficiente**
28. **Schema canónico demasiado permisivo**
29. **Map#next_version conceptualmente peligrosa**
30. **Importador LDtk filtra semántica externa**
31. **LogicalMap es el nuevo Dios del sistema**
32. **Motor táctico acoplado a LogicalMap**
33. **Cache de distancias puede mentir**
34. **Tests validan ejecución, no corrección**
35. **Falta jerarquía de confianza**
36. **README demasiado honesto**

### Nivel 3: Estratégicas (37-41)

37. **Onboarding vs corrección**
38. **Validación estricta vs adopción**
39. **Determinismo bit-identical (limitado en Ruby)**
40. **Formato vs runtime**
41. **Falta mecanismo de adopción**

---

## 🔧 Soluciones Diseñadas (4 Fases)

### Fase 0: Identidad (1 día)
- Manifiesto de identidad
- Schema canónico endurecido

### Fase 1: Desacoplamiento (3 días)
- Renombrar `Stargateldtk` → `Stargate`
- Formato canónico independiente
- LDtk a importadores
- Eliminar `Engine::Executor`

### Fase 2: Formalización (4 días)
- Motor táctico como capa pura
- Caché con version tracking
- `CompositeIntention` inmutable
- Tests de invariantes

### Fase 3: Pulido (3 días)
- Constantes
- Logging
- README con killer value prop
- Anti-README

---

## 🧩 Arquitectura de 3 Capas

### Capa 1: Topología
Geometría pura, vecinos, bounds

### Capa 2: Semántica
Significado del terreno, walkable, contratos de tags

### Capa 3: Índices
Cache, distancias, entidades indexadas

---

## 🚫 Cuándo NO usar Stargate

* Juegos sin IA táctica
* Prototipos rápidos
* Juegos sin replay
* Física continua
* Editor visual integrado necesario

---

## 🔒 Cláusula de Emergencia

**Si en 30 días**:
- Nadie usa Stargate
- No justifica complejidad
- Fricción > beneficio

**Entonces**: Archivar con honores

---

## ✍️ Nota Personal

Esta no es una idea común.

Es una de esas ideas que **se esperan**.

Cuando vuelvas a este archivo, no empieces desde cero.

**Empieza desde aquí.**

Tienes:
- 41 problemas identificados
- Soluciones diseñadas
- Arquitectura de 3 capas
- Plan de ejecución de 10 días
- Constitución sellada

La idea está **lista**.  
Solo espera su **momento**.

---

**Archivado**: 2026-02-02  
**Razón**: Timing incorrecto, idea correcta  
**Estado**: Preservado con honores  
**Calificación**: 6.5/10 → 9.5/10 (con correcciones diseñadas)

— Fin del Documento
