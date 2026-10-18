# Color Chaos 2: Ciudad Prisma

Una carrera de memoria y colores por ocho sectores de una ciudad de islas flotantes. Observa durante dos segundos un personaje 3D original; después aparece con un color alterado. Elige entre cinco caminos con versiones de ese personaje. La respuesta correcta abre la puerta y permite avanzar. El recorrido, el lobby y el punto de aparición están incluidos en el archivo y se ven antes de ejecutar scripts.

Esta reconstrucción corresponde a **Color Chaos**, la experiencia de la raíz del repositorio. Conserva sus tres productos de monedas, su pase VIP y su almacén de progreso. La entrega anterior independiente de Color Rush permanece en `games/color-rush`; no necesitas abrirla para instalar Ciudad Prisma.

## Descargar e instalar

**[Descargar ColorChaos2-completo.zip](https://github.com/SSJ-ARIEL/Robloxstudio/raw/refs/heads/main/downloads/ColorChaos2-completo.zip)**.

Descomprime el ZIP y abre la carpeta **ColorChaos2**. Elige el procedimiento según tu caso:

| Tu caso | Archivo | Pasos |
| --- | --- | --- |
| Ya publicaste Color Chaos y configuraste las compras | `downloads/ColorChaosUpdate.rbxmx` | [Instalar conservando Config e IDs](docs/ACTUALIZAR_LOBBY.md) |
| Quieres abrir el juego completo en Studio | `downloads/ColorChaos2.rbxl` | [Abrir, configurar y publicar](docs/PUBLICAR.md) |
| Necesitas el mismo juego en formato XML | `downloads/ColorChaos2.rbxlx` | Se abre igual que el archivo binario |

El modelo de actualización deja una copia local de los objetos anteriores en ServerStorage. Los archivos completos tienen los cuatro IDs de plantilla en cero; el actualizador conserva automáticamente los de tu experiencia. Estos métodos no requieren instalar Rojo. No uses `ColorChaos-lobby-completo.zip` para Ciudad Prisma: ese ZIP corresponde a la versión anterior.

## Qué incluye

| Sistema | Comportamiento |
| --- | --- |
| Mundo permanente | Plaza, jardines, galería, tienda, regalos, podio, paneles y ocho sectores con cuarenta puertas. |
| Memoria y carrera | Referencia de dos segundos, cinco alternativas, elección física y avance entre sectores. |
| Personajes | 250 personajes 3D originales, mostrados en retratos interactivos dentro del juego. |
| Final | Cuando quedan dos competidores a partir de la tercera etapa, o en la última etapa, gana quien llegue primero a la respuesta correcta. |
| Práctica individual | Puede comenzar una persona, con progreso gratuito; la práctica no suma victorias. |
| Eliminados y entrada tardía | Esperan en el lobby, observan o entran voluntariamente como fantasmas. |
| Fantasmas | Recorren el reto sin bloquear jugadores ni conseguir aciertos, rachas, regalos de racha o victorias. |
| Regalo de racha | Cada cinco aciertos consecutivos se gana un regalo aleatorio gratuito. |
| Regalos por tiempo | Diamantes, traje, emote, reacción y regalo gratuito al acumular 2, 5, 10, 15 y 20 minutos diarios. |
| Personalización | Trajes, emotes, reacciones y estelas con monedas, diamantes o beneficios VIP identificados. |
| Clasificación | Tabla de sala y tablas globales de victorias, mejor racha y nivel. |
| Monetización | Tres paquetes garantizados de monedas y VIP cosmético. Los regalos aleatorios no se venden. |
| Compatibilidad | Config y recibos existentes conservados; ajustes de la nueva dinámica en GameSettings. |

Las gemas se obtienen gratuitamente. Los cosméticos ganados quedan disponibles en el inventario. Un cosmético repetido obtenido de regalo se convierte en 15 diamantes. La racha continúa al ganar y se reinicia al fallar o abandonar una partida activa. Los regalos por tiempo también funcionan mientras esperas o juegas como fantasma.

## Compras y progreso

Los cuatro identificadores siguen en `src/shared/Config.luau`, dentro de `Config.Commerce`: tres `ProductId` y un `PassId`. Los precios se configuran en Creator Dashboard y se confirman en la ventana oficial de Roblox. Un cero deja el artículo sin activar; no se sustituye por el precio.

Los productos entregan exactamente **100, 400 o 1000 monedas** mediante el recibo oficial del servidor. VIP conserva su aura Prisma y título y añade cosméticos identificados. Las compras no dan respuestas, victorias, reentradas ni regalos aleatorios. Consulta [PRODUCTOS.md](docs/PRODUCTOS.md) para nombres, descripciones, precios sugeridos y recompensas gratuitas.

El almacén predeterminado permanece en `ColorChaos_Player_v1` y las claves de perfil en `Player_<UserId>`. El guardado y los cobros están desactivados en las simulaciones de Studio. Las tablas globales requieren servidores publicados y guardados confirmados; no se llenan con datos de ejemplo.

## Desarrollo y futuras actualizaciones

Usa el checkout existente. En Linux, instala y verifica las herramientas oficiales fijadas por versión y SHA-256:

```sh
COLOR_CHAOS_TOOLS_DIR=/workspace/.tools/color-chaos bash tools/setup.sh
COLOR_CHAOS_TOOLS_DIR=/workspace/.tools/color-chaos bash tools/validate.sh
```

Para generar los archivos completos, el modelo de actualización inactivo y el ZIP:

```sh
COLOR_CHAOS_TOOLS_DIR=/workspace/.tools/color-chaos python3 tools/package-release.py
```

Rojo es opcional para editar y sincronizar las fuentes. Sus pasos están en [PUBLICAR.md](docs/PUBLICAR.md). Antes de sincronizar, copia a las fuentes tus IDs reales y conserva el nombre del almacén; una plantilla con ceros no debe reemplazar tu Config configurado.

La validación automática comprueba código, reglas, persistencia simulada, instalador y estructura del escenario. **Este entorno no ejecuta Roblox Studio, física, renderizado ni cobros reales.** El alcance de verificación de esta entrega está en [ESTADO.md](docs/ESTADO.md). [OPERACION.md](docs/OPERACION.md) explica cómo actualizar la misma experiencia y recoger un error útil si aparece un problema.

## Organización

- `src/server/`: rondas, perfiles, compras, cosméticos y clasificaciones.
- `src/shared/`: Config preservable, GameSettings, catálogo, economía, reglas y personajes.
- `src/client/`: interfaz, retratos, espectador y bienvenida independiente del servidor.
- `scene/`: mundo permanente serializado y sus instrucciones.
- `release/Installer.luau`: instalación manual con respaldo y restauración ante fallos.
- `downloads/`: juego completo y modelo de actualización.
- `assets/`: imágenes promocionales e iconos para Creator Dashboard.
- `docs/`: diseño acordado, publicación, actualización, productos y estado.

El código, la geometría y los personajes son propios. El nombre es provisional: no se acredita exclusividad comercial del nombre ni de las mecánicas generales del género.
