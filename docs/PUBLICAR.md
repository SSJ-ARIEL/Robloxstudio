# Abrir y publicar Color Chaos 2: Ciudad Prisma

**Si ya publicaste Color Chaos y configuraste sus compras, usa primero [la actualización que conserva tus IDs](ACTUALIZAR_LOBBY.md).** Esta guía explica cómo abrir el archivo completo y configurar una experiencia. No necesitas instalar Rojo para hacerlo.

## 1. Abrir el archivo correcto

1. Descarga [ColorChaos2-completo.zip](https://github.com/SSJ-ARIEL/Robloxstudio/raw/refs/heads/main/downloads/ColorChaos2-completo.zip).
2. En Windows, haz clic derecho sobre el ZIP y selecciona **Extraer todo**. Abre la carpeta extraída **ColorChaos2**.
3. Inicia Roblox Studio y selecciona **Archivo → Abrir un archivo**.
4. Entra en **ColorChaos2 → downloads** y selecciona **ColorChaos2.rbxl**. Se abre un archivo, no toda la carpeta. `ColorChaos2.rbxlx` contiene el mismo juego en formato XML.
5. Al abrirlo debe verse la ciudad, la plaza y el recorrido, aunque todavía no hayas pulsado Jugar. En **Explorador → Workspace → ColorChaosWorld** están el mapa y LobbySpawn.

Los 250 personajes se representan mediante modelos propios en los retratos del juego. No necesitas buscar fotos ni subir 250 imágenes a Roblox. Para que aparezcan los retratos y la interfaz, inicia la simulación; el mundo permanente ya está incluido en el archivo.

## 2. Nombre, descripción y publicación

Si los botones de publicar aparecen desactivados, pulsa **Detener** y comprueba que abriste el archivo completo `.rbxl`, no el modelo `.rbxm` de actualización.

1. Selecciona **Archivo → Publicar en Roblox** para crear una experiencia nueva. Si vas a sustituir tu Color Chaos existente desde este archivo completo, copia primero sus cuatro IDs y su configuración de guardado; después usa **Publicar en Roblox como**, seleccionando **esa experiencia y su mismo lugar inicial**. El actualizador es la opción más sencilla para conservarlos automáticamente.
2. Nombre sugerido: **Color Chaos: Ciudad Prisma**.
3. Descripción para copiar:

   > Observa al personaje, recuerda su color y corre hacia la puerta correcta. Recorre ocho sectores de Ciudad Prisma y descubre 250 personajes originales. Consigue monedas y diamantes jugando, recibe regalos por tiempo y desbloquea trajes, emotes, reacciones y estelas. Cada cinco aciertos seguidos ganas un regalo gratis. Si quedas fuera, observa o explora como fantasma mientras esperas. Compite en las clasificaciones de sala y globales. Las compras son opcionales.

4. En **Creador**, selecciona la cuenta o grupo propietario. Marca computadora, teléfono y tablet; habilita otros dispositivos cuando hayas comprobado sus controles.
5. Guarda/publica. Conserva el enlace de la experiencia.
6. Configura **Máximo de jugadores: 20** en los ajustes del lugar/experiencia. El código admite hasta veinte participantes por partida.

Una persona puede practicar. Con dos o más participantes al comienzo se activa la competición. Quienes llegan después esperan en el lobby o juegan voluntariamente como fantasmas hasta la siguiente partida.

## 3. Conservar o crear los productos

Si ya tienes los tres paquetes y el pase de Color Chaos, **conserva sus IDs**. No hace falta volver a crearlos. Para una experiencia nueva, abre [Creator Dashboard → Creaciones](https://create.roblox.com/dashboard/creations), selecciona la experiencia y entra en **Monetización → Productos del desarrollador**.

Crea estos tres productos repetibles. Los precios son sugerencias iniciales; cambia los precios desde el panel, no los identificadores del código.

| Nombre | Descripción para copiar | Precio sugerido | Imagen |
| --- | --- | ---: | --- |
| 100 monedas | Recibe 100 monedas de Color Chaos para desbloquear cosméticos de tu elección. También puedes ganar monedas jugando. No entrega Robux ni respuestas. | 9 Robux | `assets/coins100.png` |
| 400 monedas | Recibe 400 monedas de Color Chaos para elegir trajes, emotes, reacciones y estelas del catálogo. La compra entrega una cantidad fija de monedas internas. | 29 Robux | `assets/coins400.png` |
| 1000 monedas | Recibe 1000 monedas de Color Chaos para personalizar tu personaje con artículos del catálogo. No incluye regalos aleatorios ni ventajas para ganar. | 59 Robux | `assets/coins1000.png` |

Guarda cada producto y copia su **ID de producto**, no el ID de la imagen ni el precio. Los productos deben pertenecer a esta experiencia.

Después entra en **Monetización → Pases**, crea **VIP Prisma** con `assets/vip-prisma.png` y esta descripción:

> Desbloquea el aura Prisma, un título VIP, el traje Centinela Prisma y la Estela Prisma. Beneficios cosméticos permanentes en esta experiencia. No cambia las respuestas, las probabilidades de regalos ni las condiciones para ganar.

Activa su venta y fija el precio que elijas; la sugerencia inicial es **79 Robux**. Copia su **PassId**. Los importes definitivos, incluidos ajustes regionales, son los que confirma la ventana oficial de Roblox.

## 4. Colocar los IDs en Studio

1. En Studio pulsa **Detener** y abre **Explorador**.
2. Abre **ReplicatedStorage → ColorChaos → Config** haciendo doble clic en Config.
3. Busca **Config.Commerce**. Cambia únicamente los cuatro ceros correspondientes:

   | Código que identifica el artículo | Campo que cambias |
   | --- | --- |
   | `Key = "coins100"` | Su `ProductId = 0` por el ID de 100 monedas |
   | `Key = "coins400"` | Su `ProductId = 0` por el ID de 400 monedas |
   | `Key = "coins1000"` | Su `ProductId = 0` por el ID de 1000 monedas |
   | `VIP` | Su `PassId = 0` por el ID del pase VIP |

4. Escribe números sin comillas, conservando las comas. **No sustituyas esos ceros por los precios.** No cambies `Coins`, `Key`, `DataStoreName` ni los registros de recibos.
5. Selecciona **Archivo → Publicar en Roblox** para guardar los cambios en la misma experiencia.

Un artículo con ID cero queda inactivo. El precio se consulta a Roblox; el servidor entrega monedas únicamente mediante el recibo oficial confirmado. En Studio el progreso es temporal y no se procesan compras de productos que dependan de guardado real.

## 5. Imágenes y acceso público

En la configuración de contenido de Creator Dashboard, selecciona **Icono** y sube **ColorChaos2 → assets → ciudad-prisma-icono.png**. En **Miniaturas**, sube **ciudad-prisma-banner.png** de esa misma carpeta. Son imágenes nuevas de Ciudad Prisma; los archivos antiguos `logo.png` y `banner.png` pertenecen al diseño anterior. También puedes capturar el escenario real desde Studio. Las imágenes nuevas son ilustraciones promocionales, no capturas del motor; [su documentación](../assets/CIUDAD_PRISMA_ART.md) está incluida.

Completa el cuestionario de madurez y cumplimiento describiendo el contenido real. En **Público / Audiencia / Acceso**, selecciona la audiencia deseada cuando Roblox habilite esa opción para tu cuenta. Los nombres exactos de estas secciones pueden cambiar. Cumple los requisitos que te muestre el panel; no crees otra experiencia para intentar evitar una restricción de cuenta.

Publicar una versión y hacer pública la experiencia son acciones diferentes. Después de publicar, abre el enlace desde la aplicación Roblox en un servidor nuevo. Las tablas globales necesitan registros guardados de jugadores reales y pueden tardar en actualizarse; no aparecen rellenas con nombres inventados.

## 6. Si Roblox muestra “Error al guardar”

Ese aviso no identifica la causa por sí solo y no significa que Roblox solo admita un juego por cuenta. Conserva el archivo local. Comprueba que Studio está actualizado, que iniciaste sesión con el propietario y que tienes conexión. Abre **Vista → Salida** y copia el primer mensaje rojo completo al volver a publicar. Revisa [el estado de Roblox](https://status.roblox.com/) si hay una incidencia.

Cambiar repetidamente nombres o borrar la experiencia no es necesario para diagnosticarlo. El archivo binario `.rbxl` y el XML `.rbxlx` incluidos representan el mismo proyecto; la estructura de ambos se genera con Rojo, pero la nube no confirma que tu cuenta haya completado una publicación.

## 7. Rojo, opcional para editar las fuentes

Rojo tiene dos partes: **un programa en tu PC** que lee el proyecto y **un plugin en Studio** que recibe los cambios. GitHub guarda versiones de código; no sincroniza directamente con Studio.

1. Descarga [Rojo 7.6.1 para Windows](https://github.com/rojo-rbx/rojo/releases/tag/v7.6.1), extrae `rojo.exe` y colócalo junto a `default.project.json`, en la carpeta ColorChaos2.
2. Cierra Studio. En esa carpeta, escribe `powershell` en la barra de direcciones del Explorador de Windows y pulsa Enter.
3. Ejecuta:

   ```powershell
   .\rojo.exe --version
   .\rojo.exe plugin install
   ```

4. Conserva primero tus cuatro IDs y el nombre de DataStore en `src/shared/Config.luau`.
5. Abre tu experiencia existente en Studio y ejecuta en PowerShell:

   ```powershell
   .\rojo.exe serve default.project.json
   ```

6. Mantén abierta la terminal. En **Plugins → Rojo**, conecta a **localhost:34872**, o al puerto que indique la terminal. Revisa y aplica la sincronización.
7. Publica desde **Archivo → Publicar en Roblox**. No ejecutes `rojo init`; la configuración ya está incluida.

## Fuentes oficiales

- [Publicar experiencias y lugares](https://create.roblox.com/docs/production/publishing/publish-games-and-places).
- [Productos de desarrollador](https://create.roblox.com/docs/production/monetization/developer-products).
- [Pases](https://create.roblox.com/docs/production/monetization/passes).
- [Precios regionales](https://create.roblox.com/docs/production/monetization/regional-pricing).
- [Instalación de Rojo](https://rojo.space/docs/v7/getting-started/installation/).
