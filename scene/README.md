# Escena de Color Chaos

`color-chaos-world.project.json` contiene una escena original hecha con piezas de Roblox. Rojo la incluye en `Workspace.ColorChaosWorld` al construir o sincronizar el proyecto. El piso, el punto de aparición, los carteles y el mirador existen antes de ejecutar los scripts; no dependen de DataStore, compras ni recursos externos.

Los objetos que reutiliza el servidor tienen nombres estables:

| Objeto | Centro en studs | Tamaño | Uso |
| --- | --- | --- | --- |
| `Plaza del reactor` | `(0, 5, 145)` | `110 × 3 × 80` | Piso del lobby, anclado y con colisión. |
| `LobbySpawn` | `(0, 7, 153)` | `10 × 1 × 10` | Spawn neutral habilitado, sin cambio de equipo. |
| `Título` | `(0, 17, 168)` | `1 × 1 × 1` | Ancla invisible del cartel principal. |
| `Instrucciones` | `(-27, 9, 144)` | `1 × 1 × 1` | Ancla invisible del instructivo. |
| `Tienda de auras` | `(27, 8, 144)` | `8 × 4 × 8` | Mostrador al que el servidor añade un ProximityPrompt. |
| `LavaSurface` | `(0, 8, -22)` | `160 × 0.8 × 176` | Superficie decorativa móvil; el servidor calcula el peligro. |
| `Mirador` / `Plataforma del mirador` | `(0, 22, 78.5)` | `68 × 3 × 19` | Mirador accesible mediante diecisiete escalones desde el lobby. |
| `ArenaPreview` | Varios | Varios | Reactor y plataformas decorativos para mostrar la arena entre rondas. |

Todos los objetos están anclados. `LavaSurface` y las piezas de `ArenaPreview` carecen de colisión, contacto y consulta de rayos. Los detalles luminosos y los carteles invisibles tampoco bloquean el paso. La arena de las rondas queda libre dentro de `x = -50…50, z = -85…50`; la escalera y el mirador están al sur de ella. La lava termina en `z = 66`, el mirador empieza en `z = 69` y el piso del lobby empieza en `z = 105`.

Cada cartel persistente usa un BillboardGui llamado `StaticSign`. El servidor debe conservar estos carteles y evitar añadir otro encima. Debe ocultar `ArenaPreview` durante una ronda para que el reactor decorativo no distraiga del objetivo real.

Para modificar la distribución, edita `tools/generate-scene.py` y ejecuta:

```sh
python3 tools/generate-scene.py
COLOR_CHAOS_TOOLS_DIR=/workspace/.tools/color-chaos bash tools/validate.sh
```

El generador solo ayuda a editar. No hace falta Python para abrir el archivo entregado o construir la escena con Rojo. La serialización se comprueba automáticamente; movimiento, cámara y apariencia requieren el motor de Roblox Studio para verificarse.
