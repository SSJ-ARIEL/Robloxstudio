# Catálogo y datos de activación

Color Chaos vende **cosméticos y moneda interna mediante Robux**. No vende Robux, no promete convertir monedas del juego en Robux y no ofrece recompensas aleatorias de pago.

## Artículos de pago

| Artículo | Tipo en Roblox | Código del artículo | ID que se configura | Entrega |
| --- | --- | --- | --- | --- |
| 100 monedas | Developer Product | `coins100` | `ProductId` | 100 monedas internas |
| 400 monedas | Developer Product | `coins400` | `ProductId` | 400 monedas internas |
| 1000 monedas | Developer Product | `coins1000` | `ProductId` | 1000 monedas internas |
| VIP Prisma | Pass | `vip` | `PassId` | Aura Prisma y título VIP sobre el personaje |

Los paquetes de monedas se pueden comprar varias veces. VIP es un beneficio permanente asociado a la propiedad del pase en Roblox. Las monedas se utilizan para auras cosméticas y también se obtienen jugando. Ningún artículo vende la victoria.

El catálogo de monedas incluye Clásica (gratis), Menta (80), Solar (150), Rosada (220), Lavanda (350), Océano con estela (500) y Cometa con estela (1000). Cada compra de aura es permanente y volver a equiparla no vuelve a cobrar. Prisma requiere el pase VIP y no se vende por monedas. Así, el paquete de 1000 monedas tiene artículos concretos en los que puede gastarse; los paquetes no contienen premios aleatorios.

Los productos y el pase deben pertenecer a la experiencia publicada que utiliza este código. No reutilices productos de otra experiencia.

## Imágenes incluidas para subir al Dashboard

Todos estos archivos están dentro de **assets** en el ZIP del proyecto. No necesitas instalar herramientas para usarlos.

| Archivo | Uso | Tamaño |
| --- | --- | --- |
| [coins100.png](../assets/coins100.png) | Producto de 100 monedas | 512 × 512 |
| [coins400.png](../assets/coins400.png) | Producto de 400 monedas | 512 × 512 |
| [coins1000.png](../assets/coins1000.png) | Producto de 1000 monedas | 512 × 512 |
| [vip-prisma.png](../assets/vip-prisma.png) | Pase VIP Prisma | 512 × 512 |
| [logo.png](../assets/logo.png) | Icono de la experiencia | 512 × 512 |
| [banner.png](../assets/banner.png) | Miniatura promocional ilustrada del reactor | 1920 × 1080 |

Selecciona los **PNG** en los campos de subida de Roblox. Los SVG son las fuentes editables. Los iconos de monedas representan moneda interna, no Robux; el banner es una ilustración, no una captura. El permiso de uso y los detalles están en [assets/README.md](../assets/README.md).

## Registro para conservar en tu copia

Completa esta tabla cuando crees los artículos en tu cuenta. Estos datos pueden compartirse para configurar el proyecto; **no incluyas contraseñas, cookies, códigos de verificación ni claves de API**.

| Dato | Valor real |
| --- | --- |
| Enlace de la experiencia | Pendiente |
| Propietario de la experiencia: cuenta o grupo | Pendiente |
| ProductId de 100 monedas | Pendiente |
| ProductId de 400 monedas | Pendiente |
| ProductId de 1000 monedas | Pendiente |
| PassId de VIP Prisma | Pendiente |

El valor `0` en Config significa **sin configurar**. No es un producto gratuito ni un ID válido. Los precios se configuran en Creator Dashboard; el código define las entregas, no fija precios ficticios.

## Precio y confirmación

El importe definitivo se muestra en la ventana oficial de compra de Roblox. Si configuras precios regionales o administrados, distintas personas pueden ver precios diferentes según Roblox. No publiques imágenes o textos que prometan un precio universal si esa opción está activa.

El usuario debe iniciar la compra y confirmar en Roblox. El juego no debe prometer una entrega pagada basándose solamente en que se cerró la ventana de compra: los paquetes se entregan desde el servidor al procesar el recibo oficial.

No hay un precio que garantice ventas. Puedes ajustar los precios desde el panel sin cambiar los IDs ni volver a crear productos. Calcula los ingresos con los reportes oficiales de Roblox, que incluyen sus condiciones y comisiones. [DevEx](https://create.roblox.com/docs/production/monetization/developer-exchange) tiene requisitos propios; no equivale a retirar cualquier Robux inmediatamente.

## Configuración y entrega

Los IDs viven en `src/shared/Config.luau`, dentro de `Config.Commerce`. El servidor decide las cantidades, valida el artículo solicitado y procesa recibos. El cliente presenta la tienda y solicita la ventana oficial; no decide cuánto cobra Roblox ni cuántas monedas recibe el jugador.

Si no se puede cargar o guardar el progreso, la entrega pagada no debe confirmarse como completada. Roblox puede volver a presentar un recibo pendiente. Cada recibo tiene un identificador para reconocerlo y evitar volver a entregar la misma compra; no borres su registro al actualizar.

Si deseas añadir un producto nuevo, cambia el catálogo del código y configura el nuevo ID. No cambies de forma silenciosa el beneficio permanente de un pase que otras personas ya compraron.

## Identidad y cumplimiento

El proyecto utiliza código y escenarios creados para esta entrega. Las mecánicas generales de colores, memoria y cooperación no acreditan exclusividad. El nombre es provisional y no se garantiza que esté libre de conflictos.

Usa arte, sonidos y textos propios o con licencia apropiada. No copies mapas, interfaces, personajes o marcas reconocibles de otros juegos. Describe cada producto con precisión y vuelve a revisar las políticas de Roblox cuando amplíes la monetización.

Fuentes: [productos](https://create.roblox.com/docs/production/monetization/developer-products), [pases](https://create.roblox.com/docs/production/monetization/passes), [precios regionales](https://create.roblox.com/docs/production/monetization/regional-pricing) y [estándares de la comunidad](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Community-Standards).
