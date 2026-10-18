# Mantener Color Chaos: Ciudad Prisma

Las correcciones se publican en **la misma experiencia y su mismo lugar inicial**. No hay que crear otro juego ni borrar el progreso. GitHub conserva el código, Roblox conserva las versiones del lugar y DataStore guarda los perfiles por separado.

## Actualizar conservando tu configuración

Usa [ACTUALIZAR_LOBBY.md](ACTUALIZAR_LOBBY.md): importa ColorChaosUpdate y ejecuta su instalador con Studio detenido. Conserva Config completo y respalda los objetos anteriores en ServerStorage. El instalador no publica ni escribe datos de jugadores.

Si sincronizas directamente con Rojo, conserva primero los tres ProductId, el PassId y `Config.DataStoreName` en las fuentes. Los nuevos ajustes de rondas están en **GameSettings**; no necesitas borrar ni reemplazar Config para recibir la dinámica de Ciudad Prisma.

Si abres un archivo completo `.rbxl`, su Config es el de plantilla. Antes de usar **Publicar en Roblox como** sobre tu experiencia existente, copia tu configuración real. Mantén el mismo almacén `ColorChaos_Player_v1`, salvo que tu experiencia ya usara otro nombre personalizado, que debes conservar literalmente.

## Servidores y respaldo

Los servidores abiertos pueden seguir utilizando la versión anterior después de publicar. Los nuevos usan el contenido actualizado. Reinicia los servidores de la experiencia desde el Dashboard si necesitas que todos reciban el cambio; el reinicio interrumpe sus partidas.

Antes de actualizar, guarda un `.rbxl` local. La carpeta ColorChaosBackup en ServerStorage contiene los objetos anteriores con sus scripts desactivados. Es una copia del lugar, no de DataStore. No actives simultáneamente el servidor antiguo y el nuevo. Para volver al contenido anterior utiliza el archivo local o una versión anterior del lugar; conserva siempre la configuración y los datos compatibles.

## Comportamiento esperado

| Situación | Resultado |
| --- | --- |
| Entra una persona sola | Espera la cuenta atrás y comienza práctica; obtiene progreso gratuito, pero no victorias. |
| Entran dos o más antes de comenzar | Se inicia una partida competitiva, hasta veinte participantes. |
| Un competidor elige mal | Regresa al lobby y pierde la racha actual. Puede observar o entrar como fantasma. |
| Alguien entra con la partida empezada | Queda en el lobby y puede activar el modo fantasma para recorrerla. |
| Un fantasma acierta | Puede continuar explorando, pero no suma aciertos, monedas por respuesta, rachas, regalos de racha ni victorias. |
| Un jugador encadena cinco aciertos | Gana un regalo gratuito; también ocurre al llegar a diez, quince y sucesivos múltiplos. |
| Termina una partida ganando | Conserva su racha. Salir de una partida activa la reinicia. |
| Espera en lobby o juega como fantasma | Sigue acumulando tiempo para los regalos diarios. |
| DataStore no está disponible | El mundo permanece visible; el juego no confirma entregas pagadas sin guardado fiable. |
| La clasificación global está vacía | Aún no hay registros confirmados o el servicio no está disponible. No implica que el lobby deba fallar. |

Los regalos por tiempo se reclaman una vez al día por escalón y usan tiempo conectado acumulado, no tiempo con el juego cerrado. El día cambia a las **00:00 UTC, 19:00 de Ecuador continental**. La tabla global se actualiza periódicamente, después de guardar los perfiles; no es un contador instantáneo.

## Recoger un error útil

Si algo falla, conserva el lugar y abre **Vista → Salida / Output** de Studio. Copia el primer error rojo completo, incluido el nombre del script y la línea. Indica qué hiciste, el dispositivo y si ocurrió en Studio o en la aplicación Roblox. Para problemas visuales sirve una captura con el personaje, la interfaz y el Explorador visibles.

| Síntoma | Comprobación |
| --- | --- |
| El editor está vacío | Confirma que abriste ColorChaos2.rbxl o instalaste el actualizador completo. Workspace debe contener ColorChaosWorld. |
| La ciudad está visible, pero no comienza la ronda | Revisa el primer error en Salida. Un Config editado con una coma ausente también puede impedir el arranque. |
| Aparece el mundo antiguo | Comprueba el archivo y abre un servidor nuevo tras publicar. |
| No aparece la compra | Comprueba ID real, tipo ProductId/PassId, pertenencia a la experiencia, venta activa y estado del guardado. |
| El progreso desaparece al detener Studio | Studio usa progreso temporal; no escribe perfiles de producción. |
| La tabla global no muestra la prueba de Studio | La clasificación se alimenta de perfiles persistidos en servidores publicados. |
| “Error al guardar” al publicar | Conserva el archivo y recoge el error de Salida. No presupongas que es un carácter del nombre o un límite de un juego por cuenta. |

## Proteger compras y perfiles

Conserva el nombre del almacén y las claves `Player_<UserId>`. No borres recibos ni cambies las cantidades de productos antiguos con compras pendientes. Los recibos numéricos anteriores siguen siendo compatibles. Monedas y recibo se guardan juntos, y un recibo duplicado no debe volver a premiarse.

Los nuevos campos de diamantes, regalos, cosméticos y racha se inicializan al cargar perfiles existentes. Los regalos aleatorios solo se obtienen jugando: no se compran con Robux, monedas ni diamantes. Los precios de cosméticos indican exactamente el artículo que recibe el jugador.

## Verificación de desarrollo

```sh
COLOR_CHAOS_TOOLS_DIR=/workspace/.tools/color-chaos bash tools/validate.sh
COLOR_CHAOS_TOOLS_DIR=/workspace/.tools/color-chaos python3 tools/package-release.py
```

Ejecuta estos comandos desde la raíz del repositorio en el entorno Linux. Windows no necesita estos pasos para abrir la entrega. Los resultados de simulación y sus límites están en [ESTADO.md](ESTADO.md); no equivalen a ejecutar física, renderizado o facturación real de Roblox.
