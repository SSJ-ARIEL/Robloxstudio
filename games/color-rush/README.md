# Color Rush: Corre y Recuerda

Segundo juego independiente de este repositorio. Color Chaos se conserva en la raíz; Color Rush vive entero en `games/color-rush/`. No necesitas otro repositorio, alquilar un servidor ni usar Discord para alojarlo: Roblox administra los servidores de cada experiencia.

## Abrir el juego

1. [Descarga únicamente Color Rush](https://github.com/SSJ-ARIEL/Robloxstudio/raw/refs/heads/main/games/color-rush/downloads/ColorRush-completo.zip). Si el enlace directo requiere acceso, abre [el archivo en GitHub](https://github.com/SSJ-ARIEL/Robloxstudio/blob/main/games/color-rush/downloads/ColorRush-completo.zip) e inicia sesión para descargar. También puedes [descargar todo el repositorio](https://github.com/SSJ-ARIEL/Robloxstudio/archive/refs/heads/main.zip).
2. En Windows, haz clic derecho en el ZIP → **Extraer todo**.
3. En el ZIP de solo este juego, entra en **ColorRush → downloads**. Si descargaste todo el repositorio, entra en **Robloxstudio-main → games → color-rush → downloads**.
4. Abre Roblox Studio → **Archivo → Abrir desde archivo**, o **Ctrl + O**.
5. Selecciona **ColorRush.rbxlx**, no la carpeta completa.

No necesitas Rojo para abrir y publicar este archivo. El mapa y los personajes se generan cuando empieza el servidor; el editor puede parecer vacío antes de ejecutar el juego.

La primera publicación debe crear **una experiencia nueva para Color Rush**. No reemplaces el lugar de Color Chaos. Después actualizarás siempre esa misma experiencia de Color Rush.

## Cómo se juega

- Hasta 20 jugadores. La partida puede comenzar con 2; no necesita esperar a que se llene el servidor.
- Observa un personaje original durante **2 segundos**. Después aparecen cinco versiones con distintos colores.
- Corre hasta el camino de la versión correcta. Puedes cambiar de dirección hasta cruzar una puerta; cruzarla confirma tu elección inmediatamente. Quienes eligen mal quedan eliminados.
- La partida tiene hasta siete etapas normales y luego una carrera final. Si todos fallan una etapa normal, se repite para quienes seguían participando.
- Cuando quedan dos, empieza la final: **el primero que llega a la opción correcta gana**. Estar detrás de la misma imagen no prolonga la partida indefinidamente.
- Si hay varios supervivientes al completar las etapas, se resuelve con una carrera de desempate.
- Los eliminados pueden observar, entrenar gratis con preguntas de dos segundos y esperar la siguiente partida. El entrenamiento no concede monedas ni créditos.

El catálogo tiene **250 personajes originales**, construido con 25 arquetipos y 10 variantes estructurales. Son personajes 3D generados y mostrados en paneles del juego; no son 250 fotografías de series ni 250 imágenes que debas subir. No se usan Rick, Morty ni otros personajes de terceros.

## Tienda y reentradas

Las monedas permiten conseguir cosméticos de resultado conocido. Se ganan jugando y también se pueden comprar. Las estelas y el título VIP no cambian la velocidad ni muestran la respuesta correcta.

Los créditos de reentrada se compran individualmente o en paquetes. Se permite **una reentrada total por persona y partida**, incluida la final. Si ya la usaste, no puedes comprar otra oportunidad para esa misma partida. Un crédito no utilizado queda guardado.

En la final puedes reentrar únicamente antes de que se declare un ganador. Una compra confirmada después del final conserva el crédito para otra partida; no quita la victoria a otro jugador. La opción de reentrada automática consume un crédito disponible: **no realiza cargos automáticos**. No se garantiza completar una compra nueva antes de que otro finalista termine la carrera.

## Lo que falta configurar en tu cuenta

Crear cinco productos de desarrollador y un pase VIP en Roblox, elegir sus precios, colocar sus **seis IDs** en Config y publicar. Los IDs empiezan en cero y no son los precios.

La activación, las imágenes y todos los pasos están en [PUBLICAR.md](docs/PUBLICAR.md). Las recomendaciones de precios y el coste para jugadores de Ecuador están en [MONETIZACION.md](docs/MONETIZACION.md). Las futuras actualizaciones se explican en [OPERACION.md](docs/OPERACION.md).

| Archivo | Uso |
| --- | --- |
| `downloads/ColorRush.rbxlx` | Juego para abrir en Studio |
| `assets/icon.png` | Icono de la experiencia |
| `assets/banner.png` | Miniatura promocional |
| `assets/revive.png` | Productos de reentrada |
| `assets/coins.png` | Productos de monedas |
| `assets/vip.png` | Pase VIP |
| `assets/trail.png` | Recurso promocional de cosméticos |
| `default.project.json` | Proyecto independiente de Rojo |
| `src/shared/Config.luau` | IDs de productos y configuración |

Los PNG son ilustraciones promocionales originales, no capturas de una partida. Los paneles de personajes se generan desde el catálogo del juego, sin subir cada personaje al Dashboard.

## Verificación y mantenimiento

Los resultados técnicos y los límites de la validación se registran en [ESTADO.md](docs/ESTADO.md). Esta nube no ejecuta Roblox Studio ni efectúa cobros reales en tu cuenta.

Si hay un fallo, corregimos la parte afectada y actualizamos el lugar existente. No necesitas rehacer todo ni empezar desde cero.

## Herramientas para desarrollo en Linux

Desde esta carpeta, con bash, curl, unzip, sha256sum y Python 3:

```sh
bash tools/setup.sh
bash tools/validate.sh
```

La instalación usa Rojo 7.6.1 y Luau 0.694 oficiales con TLS y sumas SHA-256. En esta nube se instalaron en `/workspace/.tools/color-rush`; puedes ejecutar la validación con `COLOR_RUSH_TOOLS_DIR=/workspace/.tools/color-rush bash tools/validate.sh`. No ejecutes instalación y pruebas simultáneamente. Estos comandos no son necesarios para publicar desde Windows.
