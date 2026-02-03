# 🌉 Bridge: Experiencia de Error Humano

El Bridge no muestra errores técnicos; muestra diagnósticos para creadores. Aquí definimos qué ve el usuario cuando algo sale mal.

---

## 🎭 El Escenario: "El Mapa Roto"

**Situación:** El usuario movió su archivo `.ldtk` a otra carpeta pero no actualizó la ruta en el código.

**❌ Lo que vería con una librería normal:**
`NoMethodError: undefined method 'grids' for nil:NilClass` en `render_world.rb:45`

**✅ Lo que vería con el Bridge:**
Una pantalla limpia con fondo rojo oscuro:
> **"No se encontró el mapa en: app/worlds/mapa.ldtk"**
> *Revisa si el nombre del archivo es correcto o si lo moviste de carpeta.*

---

## 📖 Diccionario de Diagnósticos Humanos

| Situación Técnica | Mensaje del Bridge (Lo que lee el usuario) | Ayuda Sugerida |
| :--- | :--- | :--- |
| Archivo no existe | "No se encontró el archivo del mapa." | Revisa la ruta en `StargateLDtk::Bridge.run`. |
| JSON corrupto | "El archivo del mapa parece estar dañado." | Asegúrate de haber guardado el mapa correctamente en LDtk. |
| Sin niveles | "Este mapa está vacío." | Crea al menos un nivel en el editor de LDtk. |
| Tileset faltante | "No encuentro las imágenes (tileset) del mapa." | Revisa que la carpeta de imágenes esté donde LDtk la espera. |
| Inyección fallida | "El ciclo de DragonRuby ya está ocupado." | Parece que ya definiste un `tick`. Si es así, no necesitas usar `Bridge.run`. |

---

## 🎨 Estética de la Pantalla de Diagnóstico
*   **Fondo**: Rojo profundo (#220000) - Transmite alerta sin ser agresivo.
*   **Texto Principal**: Blanco hueso, centrado, tipografía clara.
*   **Subtexto**: Gris claro, con pasos de acción concretos.
*   **Sin Stack Traces**: No se muestra ninguna ruta de archivos de Ruby ni números de línea internos.
