# Productos, cosméticos y regalos de Ciudad Prisma

Color Chaos vende artículos cosméticos y cantidades fijas de moneda interna mediante Robux. **Los diamantes y los regalos aleatorios se consiguen jugando.** Las compras no dan respuestas, victorias ni reentrada a una partida de la que el jugador quedó eliminado.

Si ya creaste los productos de Color Chaos, conserva esos mismos productos y sus IDs. La reconstrucción mantiene las entregas de 100, 400 y 1000 monedas. VIP conserva los beneficios anteriores de aura Prisma y título VIP y añade los cosméticos indicados aquí.

## Nombres y descripciones para Creator Dashboard

| Nombre | Tipo | Descripción para copiar | Precio inicial sugerido | Imagen |
| --- | --- | --- | ---: | --- |
| 100 monedas | Producto del desarrollador | Recibe 100 monedas de Color Chaos para desbloquear cosméticos de tu elección. También puedes ganar monedas jugando. No entrega Robux ni respuestas. | 9 Robux | `assets/coins100.png` |
| 400 monedas | Producto del desarrollador | Recibe 400 monedas de Color Chaos para elegir trajes, emotes, reacciones y estelas del catálogo. La compra entrega una cantidad fija de monedas internas. | 29 Robux | `assets/coins400.png` |
| 1000 monedas | Producto del desarrollador | Recibe 1000 monedas de Color Chaos para personalizar tu personaje con artículos del catálogo. No incluye regalos aleatorios ni ventajas para ganar. | 59 Robux | `assets/coins1000.png` |
| VIP Prisma | Pase | Desbloquea el aura Prisma, un título VIP, el traje Centinela Prisma y la Estela Prisma. Beneficios cosméticos permanentes en esta experiencia. No cambia las respuestas, las probabilidades de regalos ni las condiciones para ganar. | 79 Robux | `assets/vip-prisma.png` |

Los paquetes de monedas se pueden comprar varias veces. VIP se adquiere una sola vez y su propiedad se consulta a Roblox. Estos precios son una propuesta de entrada accesible para tu público, incluido Ecuador, no una obligación ni una predicción de ventas. Si ya fijaste otros precios, puedes conservarlos.

En Ecuador se utiliza el dólar, pero no hay una conversión universal fija entre estos importes en Robux y dólares: cambian los paquetes de Robux, la plataforma y los precios regionales. El importe válido es el de la ventana oficial de compra de Roblox. Los ingresos del creador y DevEx tienen condiciones propias; no equivalen al precio que pagó el jugador por comprar Robux.

## Identificadores: no son los precios

En **ReplicatedStorage → ColorChaos → Config**, dentro de `Config.Commerce`:

| Artículo | Clave | Campo | Tu ID real |
| --- | --- | --- | --- |
| 100 monedas | `coins100` | `ProductId` | Pendiente de registrar |
| 400 monedas | `coins400` | `ProductId` | Pendiente de registrar |
| 1000 monedas | `coins1000` | `ProductId` | Pendiente de registrar |
| VIP Prisma | `vip` | `PassId` | Pendiente de registrar |

Escribe el ID de cada producto, no 9, 29, 59 o 79 por ser sus precios. El cero de la plantilla significa artículo sin configurar. Los IDs deben pertenecer a la misma experiencia. Guarda aparte el enlace y el propietario de tu experiencia; no compartas contraseñas, cookies ni códigos de acceso.

## Qué obtiene gratis cada jugador

| Acción | Recompensa |
| --- | --- |
| Acertar como participante | 8 monedas, 10 XP y un acierto de racha. |
| Ganar una partida competitiva | 60 monedas, 10 diamantes y 35 XP adicionales. |
| Llegar a 5, 10, 15… aciertos consecutivos | Un regalo aleatorio gratuito por cada múltiplo de cinco. |
| Completar práctica individual | Progreso por aciertos y regalos de racha; no suma victorias. |
| Jugar como fantasma | Puede recorrer y observar; sigue acumulando tiempo para regalos diarios. Sus respuestas no dan premios. |

Cada 100 XP aumenta el nivel, hasta el límite del sistema. La mejor racha se conserva como récord. Fallar reinicia la racha actual; ganar la mantiene para la siguiente partida. Abandonar una partida activa la reinicia para evitar conservarla escapando de una pregunta.

## Regalos por tiempo conectado

Son gratuitos, se reclaman desde el panel de regalos y se desbloquean por tiempo acumulado durante el día, incluso esperando o jugando como fantasma.

| Tiempo acumulado | Regalo |
| --- | --- |
| 2 minutos | 20 diamantes. |
| 5 minutos | Traje **Explorador Menta**. |
| 10 minutos | Emote **Vuelta Estelar**. |
| 15 minutos | Reacción **Corazón**. |
| 20 minutos | Un regalo aleatorio gratuito. |

Cada escalón se reclama una vez al día. El día cambia a las **00:00 UTC, 19:00 en Ecuador continental**. El progreso de tiempo se conserva al salir cuando el guardado está disponible. No se cuenta el tiempo con el juego cerrado. Si ya posees el cosmético regalado, recibes **15 diamantes**.

## Contenido de los regalos aleatorios gratuitos

| Resultado | Probabilidad | Entrega |
| --- | ---: | --- |
| Monedas | 45 % | 50 monedas. |
| Diamantes | 30 % | 15 diamantes. |
| Traje | 15 % | Uno de los seis trajes normales del grupo de regalos. |
| Emote | 6 % | Uno de los cinco emotes desbloqueables del grupo. |
| Reacción | 4 % | Una de las siete reacciones desbloqueables del grupo. |

Dentro de cada grupo cosmético, sus artículos tienen la misma probabilidad. Los duplicados se convierten en 15 diamantes. Los objetos VIP y las estelas no forman parte del sorteo. Los regalos no se venden por Robux, monedas ni diamantes; pagar no cambia las probabilidades.

## Catálogo completo de cosméticos

Una compra del catálogo entrega el artículo elegido y lo equipa. Volver a equipar algo que ya posees es gratis. Estos objetos se utilizan dentro de esta experiencia y no conceden propiedad de artículos del catálogo general de avatares de Roblox.

| Categoría | Nombre | Precio o acceso |
| --- | --- | --- |
| Traje | Tu avatar | Gratis, aspecto inicial. |
| Traje | Explorador Menta | 40 diamantes; también regalo a los 5 minutos. |
| Traje | Astronauta Nova | 180 monedas. |
| Traje | Piloto Coral | 240 monedas. |
| Traje | Explorador Glaciar | 75 diamantes. |
| Traje | Guardián Jardín | 400 monedas. |
| Traje | Caballero Meteoro | 120 diamantes. |
| Traje | Centinela Prisma VIP | Pase VIP Prisma. |
| Emote | Saludo | Gratis. |
| Emote | ¡Lo logramos! | 80 monedas. |
| Emote | Baile Prisma | 140 monedas. |
| Emote | Vuelta Estelar | 35 diamantes; también regalo a los 10 minutos. |
| Emote | Reverencia | 200 monedas. |
| Emote | Órbita | 65 diamantes. |
| Reacción | Estrella | Gratis. |
| Reacción | Corazón | 25 diamantes; también regalo a los 15 minutos. |
| Reacción | ¡Wow! | 60 monedas. |
| Reacción | Buena partida | 90 monedas. |
| Reacción | ¡Jajaja! | 110 monedas. |
| Reacción | Destello | 30 diamantes. |
| Reacción | ¡En racha! | 180 monedas. |
| Reacción | Prisma | 45 diamantes. |
| Estela | Sin estela | Gratis. |
| Estela | Brisa Menta | 100 monedas. |
| Estela | Cometa | 300 monedas. |
| Estela | Marea Celeste | 55 diamantes. |
| Estela | Polvo Solar | 80 diamantes. |
| Estela | Estela Prisma VIP | Pase VIP Prisma. |

Las monedas y los diamantes también se obtienen gratuitamente. El servidor verifica propiedad, saldo y artículo; el cliente no decide cantidades ni resultados. Los cosméticos antiguos se conservan en el perfil compatible para no borrar derechos adquiridos.

El armario también conserva las ocho auras de Color Chaos. Estos son sus valores predeterminados; si cambiaste los precios en tu Config, el actualizador conserva tus valores:

| Aura | Precio o acceso |
| --- | --- |
| Clásica | Gratis. |
| Menta | 80 monedas. |
| Solar | 150 monedas. |
| Rosada | 220 monedas. |
| Prisma VIP | Pase VIP Prisma. |
| Lavanda | 350 monedas. |
| Océano con estela | 500 monedas. |
| Cometa con estela | 1000 monedas. |

## Imágenes del Dashboard

Los cuatro PNG de productos de la primera tabla están incluidos en `assets`. Selecciona los PNG al subir una imagen; los SVG antiguos son fuentes editables. Los iconos de monedas representan moneda interna, no Robux.

| Imagen de la experiencia | Archivo | Dimensiones |
| --- | --- | --- |
| Icono de Ciudad Prisma | `assets/ciudad-prisma-icono.png` | 1254 × 1254 |
| Miniatura de Ciudad Prisma | `assets/ciudad-prisma-banner.png` | 1672 × 941 |

Estas dos imágenes nuevas son ilustraciones promocionales originales, no capturas del motor. Su procedencia y uso están en [CIUDAD_PRISMA_ART.md](../assets/CIUDAD_PRISMA_ART.md). Usa estos archivos para la nueva dinámica; los `logo.png` y `banner.png` anteriores corresponden al diseño viejo del reactor.

## Entregas y guardado

Los paquetes solo se conceden mediante `ProcessReceipt`, después de confirmar monedas y recibo en el mismo guardado. Cerrar el diálogo de compra no demuestra que la entrega haya sido confirmada. Si falla el guardado, el recibo puede quedar pendiente y Roblox puede volver a presentarlo. No borres registros ni productos pendientes al actualizar.

El instalador conserva los cuatro IDs y el nombre de DataStore, y mantiene compatibles los recibos de la versión anterior. El código no vende paquetes si el perfil no dispone de guardado fiable. Studio usa progreso temporal; las simulaciones de esta nube no verifican cobros reales.

Fuentes: [productos](https://create.roblox.com/docs/production/monetization/developer-products), [pases](https://create.roblox.com/docs/production/monetization/passes), [precios regionales](https://create.roblox.com/docs/production/monetization/regional-pricing) y [DevEx](https://create.roblox.com/docs/production/monetization/developer-exchange).
