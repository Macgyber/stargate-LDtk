# StargateLDtk 🌉 Bridge

**"No es para programar juegos. Es para ver mundos cobrar vida."**

El módulo Bridge es la frontera entre tu creatividad en LDtk y el poder de DragonRuby. Está diseñado para ser invisible, eliminando toda la fricción técnica para que el creador solo se preocupe de su mapa.

---

## 🎨 Flujo Creativo

1.  **Diseña**: Crea tu nivel en LDtk (tiles, capas, entidades).
2.  **Exporta**: Guarda tu archivo `.ldtk` en tu proyecto.
3.  **Conecta**: Escribe **una línea** de código.
4.  **Disfruta**: Tu mundo cobra vida instantáneamente.

---

## 🚀 Uso Rápido (main.rb)

```ruby
require "lib/stargate-LDtk/bootstrap.rb"

# El Puente materializa tu mundo inmediatamente
StargateLDtk::Bridge.run(map: "app/worlds/world.ldtk")
```

Eso es todo. No necesitas escribir `tick`, ni configurar cámaras, ni manejar loaders.

---

## 🔒 El Contrato del Bridge

El Bridge es una fachada de alta fidelidad. Para mantener su simplicidad, opera bajo estas reglas:

*   **Autónomo**: Si no defines un `tick` en tu juego, el Bridge tomará el control del ciclo de vida para asegurar que el mapa se renderice.
*   **Silencioso**: Maneja el hot-reload y la cámara sin pedirte permiso. Si guardas en LDtk, el Bridge actualiza la pantalla.
*   **Humano**: Si algo falla (archivo faltante, JSON roto), te lo dirá en lenguaje claro, no con errores de código.

> [!IMPORTANT]
> **¿Cuándo NO usar el Bridge?**
> Si necesitas control absoluto sobre el pipeline de renderizado, quieres programar una cámara compleja con comportamientos específicos, o necesitas optimizar el rendimiento al milisegundo, entonces el Bridge no es para ti. En esos casos, utiliza los módulos `Core`, `Analysis` y `Adapters` directamente.

---

## 🌉 Por debajo del puente
Aunque tú solo ves una línea de código, el Bridge está orquestando silenciosamente:
*   Carga y validación de JSON.
*   Traducción de coordenadas LDtk -> DragonRuby.
*   Renderizado automático de todas las capas visuales.
*   Vigilancia de archivos (Hot-Reload).
*   Configuración de cámara centrada.
