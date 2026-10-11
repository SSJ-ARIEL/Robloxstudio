# Publicar Color Chaos y activar las compras

Esta guía es para Windows. Puedes abrir y publicar el juego **sin instalar Rojo**. Rojo se utiliza después para sincronizar actualizaciones del código.

Hay tres cosas diferentes: GitHub guarda los archivos, Roblox Studio abre y publica el juego, y Roblox administra los servidores y los pagos. No necesitas alquilar un servidor.

## 1. Descargar el juego

1. Abre [Descargar proyecto completo](https://github.com/SSJ-ARIEL/Robloxstudio/archive/refs/heads/main.zip). Si el repositorio es privado, inicia sesión con la cuenta que tiene acceso.
2. En Descargas, haz clic derecho sobre el ZIP y selecciona **Extraer todo**. No trabajes dentro del ZIP.
3. Abre la carpeta extraída y entra en **downloads**.
4. El archivo del juego es **ColorChaos.rbxlx**. El código fuente está en la carpeta **src**, fuera de downloads.

## 2. Abrirlo en Roblox Studio

1. Instala [Roblox Studio desde Roblox](https://create.roblox.com/) e inicia sesión con la cuenta que será dueña de la experiencia.
2. En Studio, selecciona **File → Open from File / Archivo → Abrir desde archivo**.
3. Elige `downloads/ColorChaos.rbxlx`.

El mapa se construye al iniciar el servidor. Que el editor no muestre todo el escenario antes de ejecutar el juego es normal. No pegues scripts sueltos ni añadas modelos gratuitos para que aparezca.

## 3. Crear la experiencia en tu cuenta

1. Con el archivo abierto, selecciona **File → Publish to Roblox / Archivo → Publicar en Roblox**.
2. Si es la primera publicación, crea una experiencia nueva y selecciona su propietario. Los productos se crearán bajo ese mismo propietario.
3. Usa **Color Chaos: Reactor Cromático** como nombre de trabajo. El nombre sigue pendiente de comprobar; cámbialo si entra en conflicto con otra marca o experiencia.
4. Puedes usar esta descripción:

   > Recupera la energía de una ciudad que perdió sus colores. Recuerda secuencias, repara mecanismos y rescata chispas con tu equipo. Completa misiones y personaliza tu aura. Los colores incluyen letras para ayudarte a reconocerlos.

5. Guarda/publica. Anota el enlace de la experiencia.
6. En **Game Settings / Configuración del juego**, o en la configuración del lugar del Creator Dashboard, establece **Max Players / Máximo de jugadores: 12**.
7. Conserva inicialmente la audiencia **Private / Privada** mientras completas los productos y la configuración. Esto no requiere crear una segunda experiencia.

**En las actualizaciones conservarás esta misma experiencia y este mismo lugar inicial.** No crearás el juego de nuevo.

## 4. Crear los tres paquetes de monedas

Estas compras usan los Robux que el jugador ya tiene. La compra de Robux como moneda de Roblox corresponde a Roblox; nuestro juego vende artículos mediante sus ventanas oficiales.

1. Abre [Creator Dashboard → Creations](https://create.roblox.com/dashboard/creations).
2. Selecciona **la experiencia que acabas de publicar**.
3. Entra en **Monetization → Developer Products / Monetización → Productos de desarrollador**.
4. Pulsa **Create developer product / Crear producto**.
5. Crea los tres productos de la tabla. Introduce un precio en Robux en el panel de Roblox; ese precio no se escribe en el código.

| Nombre | Descripción para copiar | Entrega exacta | Imagen incluida |
| --- | --- | --- | --- |
| 100 monedas | Recibe 100 monedas de Color Chaos para desbloquear auras cosméticas. No entrega Robux. | 100 monedas | `assets/coins100.png` |
| 400 monedas | Recibe 400 monedas de Color Chaos para desbloquear auras cosméticas. No entrega Robux. | 400 monedas | `assets/coins400.png` |
| 1000 monedas | Recibe 1000 monedas de Color Chaos para desbloquear auras cosméticas. No entrega Robux. | 1000 monedas | `assets/coins1000.png` |

6. En el campo de imagen de cada producto, selecciona su PNG de la tabla. La carpeta **assets** está dentro del proyecto extraído; los tres iconos son originales y miden 512 × 512 píxeles. No selecciones los archivos SVG: son las fuentes editables.
7. Guarda cada producto. En su menú **⋯**, elige **Copy Asset ID / Copiar ID del recurso** y anota el número junto a su nombre.

Esos números son los **ProductId** que necesita el juego. No uses el ID de la experiencia, el del lugar ni el de la imagen. Los tres productos deben pertenecer a esta experiencia.

## 5. Crear el pase VIP Prisma

1. En la misma experiencia del Dashboard, entra en **Monetization → Passes / Monetización → Pases**.
2. Selecciona **Create pass / Crear pase**.
3. Nombre: **VIP Prisma**.
4. Descripción:

   > Desbloquea el aura cosmética Prisma y un título VIP sobre tu personaje. Compra permanente para esta experiencia. No aumenta las recompensas ni permite ganar automáticamente.

5. Selecciona **assets/vip-prisma.png** como imagen del pase y créalo. Es un icono original de 512 × 512 píxeles incluido en la entrega.
6. En su configuración de venta, **Sales / Ventas** cuando aparezca con ese nombre, activa la venta, fija el precio en Robux y guarda.
7. Desde la lista de pases, abre **⋯ → Copy Asset ID / Copiar ID del recurso**. Anota ese número como **PassId VIP**.

El pase se compra una vez. Los paquetes de monedas son compras repetibles. El pase debe ser de esta misma experiencia.

## 6. Colocar los cuatro identificadores sin instalar Rojo

Necesitas tres ProductId y un PassId. Son identificadores de productos, no contraseñas ni tokens.

1. Vuelve a Studio, al juego que acabas de publicar. Si lo cerraste, ábrelo desde **tus experiencias** con **Edit in Studio / Editar en Studio**.
2. Detén cualquier simulación con **Stop / Detener**.
3. Activa **Explorer / Explorador** desde las herramientas de ventanas de Studio si no está visible.
4. En Explorer, abre **ReplicatedStorage → ColorChaos → Config**. Haz doble clic en **Config** para abrir el código.
5. Busca la sección **Config.Commerce**. Cada producto tiene una línea `Key` que identifica qué entrega. Cambia **solo su número `ProductId = 0`**:

| Línea que buscas | Número que sustituyes |
| --- | --- |
| `Key = "coins100"` | Su `ProductId = 0`, por el ID del producto de 100 monedas |
| `Key = "coins400"` | Su `ProductId = 0`, por el ID del producto de 400 monedas |
| `Key = "coins1000"` | Su `ProductId = 0`, por el ID del producto de 1000 monedas |
| `VIP` | Su `PassId = 0`, por el ID del pase VIP Prisma |

6. Escribe los números sin comillas. Conserva las comas y el resto del código. No cambies las cantidades `Coins`, los `Key` ni los datos del guardado.
7. Selecciona **File → Publish to Roblox** para actualizar **la misma experiencia**.

Los identificadores empiezan en `0` porque no pueden crearse desde este repositorio en tu cuenta. Un artículo sin ID real queda sin activar; no se simulan compras exitosas.

**Conserva los cuatro números en tu copia de [PRODUCTOS.md](PRODUCTOS.md).** Si editas Config únicamente dentro de Studio, GitHub no recibe el cambio. Antes de conectar Rojo o abrir una futura descarga, coloca también esos números en `src/shared/Config.luau`, o compártelos para que se incorporen al repositorio. Una sincronización con el archivo que todavía tiene ceros podría reemplazar tu configuración.

## 7. Abrir el acceso al público

1. En Creator Dashboard, selecciona la experiencia.
2. Completa el cuestionario **Content Maturity & Compliance / Madurez del contenido y cumplimiento** describiendo lo que realmente contiene el juego. Revisa las preguntas de nuevo si añades contenido.
3. Cumple los requisitos de publicación y audiencia que muestre Roblox para tu cuenta. Pueden variar según la audiencia y las políticas vigentes. No hagas compras de suscripciones suponiendo que son obligatorias: revisa primero las opciones oficiales que te ofrece el panel.
4. En **Configure → Settings / Configurar → Ajustes**, busca **Audience / Audiencia** y selecciona **Public / Pública** cuando estés listo para lanzarlo. Guarda los cambios. Algunos diseños del panel agrupan estas opciones en **Access / Acceso**.
5. En la sección de iconos y miniaturas de la experiencia, sube **assets/logo.png** como icono y **assets/banner.png** como miniatura. El banner es una ilustración promocional del reactor; no lo describas como captura del juego. Ambos recursos son originales y están incluidos en el ZIP. No anuncies Robux gratis ni resultados garantizados.
6. Usa el enlace de la experiencia para abrirla en la aplicación de Roblox. Los servidores se crean automáticamente cuando entran jugadores.

El guardado permanente y las compras dependen de los servicios reales de Roblox. La validación automatizada del código no ejecuta el motor de Studio ni cobra compras reales. No se afirma que esas operaciones hayan sido verificadas en tu cuenta desde la nube.

## 8. Rojo: instalación opcional para futuras actualizaciones

Para ofrecer servidores privados, usa la sección **Monetization → Private Servers** de tu experiencia cuando Roblox la muestre. Puedes habilitarlos gratis o establecer un precio mensual en Robux. El juego utiliza las mismas rondas en esos servidores; Roblox gestiona el acceso y la suscripción. Describe el precio y el periodo claramente. Esta opción se configura en Roblox, sin inventar un ProductId adicional.

Rojo tiene **dos partes**: un programa en la computadora que lee los archivos, y un plugin dentro de Studio que los recibe. Deben estar en la misma computadora. GitHub no sincroniza directamente con Studio.

1. Abre [la descarga oficial de Rojo 7.6.1](https://github.com/rojo-rbx/rojo/releases/tag/v7.6.1).
2. Para un Windows habitual de 64 bits, descarga `rojo-7.6.1-windows-x86_64.zip` y extráelo.
3. Copia **rojo.exe** a la carpeta del proyecto, **junto a default.project.json**, fuera de downloads.
4. En el Explorador de Windows, abre esa carpeta. Haz clic en la barra de dirección, escribe `powershell` y pulsa Enter.
5. Comprueba el programa:

   ```powershell
   .\rojo.exe --version
   ```

6. Cierra Studio e instala el plugin:

   ```powershell
   .\rojo.exe plugin install
   ```

7. Confirma que `src/shared/Config.luau` ya contiene tus cuatro IDs. Abre Studio y abre **la experiencia existente** que vas a actualizar.
8. En PowerShell, inicia la sincronización:

   ```powershell
   .\rojo.exe serve default.project.json
   ```

9. Deja esa ventana abierta. En Studio, abre **Plugins → Rojo**, usa **localhost**, puerto **34872**, y pulsa **Connect**. Si la terminal indica otro puerto, utiliza ese.
10. Revisa y acepta los cambios para este lugar. Después usa **File → Publish to Roblox** para publicarlos.

No ejecutes `rojo init`: el proyecto ya tiene su configuración. No necesitas configurar el PATH de Windows si usas estos comandos con `rojo.exe` dentro de la carpeta. Para actualizar el juego sin instalar Rojo, consulta [OPERACION.md](OPERACION.md).

## Fuentes oficiales

- [Roblox: publicar experiencias y lugares](https://create.roblox.com/docs/production/publishing/publish-games-and-places).
- [Roblox: productos de desarrollador](https://create.roblox.com/docs/production/monetization/developer-products).
- [Roblox: pases](https://create.roblox.com/docs/production/monetization/passes).
- [Roblox: precios regionales](https://create.roblox.com/docs/production/monetization/regional-pricing).
- [Rojo: instalación](https://rojo.space/docs/v7/getting-started/installation/).
