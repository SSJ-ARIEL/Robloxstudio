# Abrir, publicar y activar Color Rush en Windows

Puedes hacer toda la primera publicación **sin instalar Rojo**. Necesitas Roblox Studio y tu navegador. Roblox administra los servidores; no necesitas contratar alojamiento.

Color Rush es el segundo juego del repositorio. **Publica una experiencia nueva para este juego; conserva Color Chaos.** Cuando esa experiencia de Color Rush ya exista, todas sus actualizaciones irán al mismo lugar.

## 1. Descarga y encuentra el archivo correcto

1. [Descarga el ZIP actualizado](https://github.com/SSJ-ARIEL/Robloxstudio/archive/refs/heads/main.zip). Si GitHub pide acceso, inicia sesión con la cuenta que tiene acceso al repositorio.
2. En **Descargas**, haz clic derecho en `Robloxstudio-main.zip` → **Extraer todo** → **Extraer**.
3. Abre la carpeta extraída. Dentro deben aparecer `games`, `src` y `README.md`. Si ves otra carpeta `Robloxstudio-main`, entra en ella.
4. Entra en **games → color-rush → downloads**.
5. Allí está **ColorRush.rbxlx**. Si Windows oculta las extensiones, puede aparecer solamente como **ColorRush**.

La ruta esperada es:

```text
Descargas\Robloxstudio-main\games\color-rush\downloads\ColorRush.rbxlx
```

No elijas `downloads/ColorChaos.rbxlx`, que corresponde al primer juego. No selecciones una carpeta completa ni trabajes dentro del ZIP.

## 2. Abre el juego en Studio

1. Abre Roblox Studio e inicia sesión en tu cuenta.
2. Selecciona **Archivo → Abrir desde archivo**. En algunas versiones dice **Abrir un archivo**. También sirve **Ctrl + O**.
3. Selecciona el archivo **ColorRush.rbxlx** de la ruta anterior y pulsa **Abrir**.

El escenario se construye al iniciar el servidor. Que el editor parezca vacío antes de ejecutar el juego no significa que falte el mapa. No hay que pegar scripts ni importar modelos gratuitos.

## 3. Publica una nueva experiencia

1. Si hay una simulación ejecutándose, pulsa **Detener**.
2. Pulsa **Archivo → Publicar en Roblox**. La primera publicación abre el formulario para crear la experiencia.
3. Completa:

   **Nombre**

   ```text
   Color Rush: Corre y Recuerda
   ```

   **Descripción**

   ```text
   Observa un personaje durante dos segundos y corre al camino que conserva sus colores. Supera etapas de memoria con tus amigos. En la final gana el primero en llegar a la opción correcta. Descubre 250 personajes originales, gana monedas y personaliza tus estelas. Puedes esperar gratis a la próxima partida o usar un crédito de reentrada: máximo uno por partida, incluida la final. VIP Prisma incluye título y estela exclusivos.
   ```

4. En **Creador**, selecciona **Yo**, o el grupo que realmente administrará el juego. Los productos y el pase deben crearse para esa misma experiencia y propietario.
5. Habilita **Computadora, Teléfono y Tablet**. Deja **Consola** y **RV** sin marcar: no se presentan como plataformas verificadas de esta entrega.
6. **Creación en equipo** es opcional. **Intercambio de datos** es una preferencia sobre compartir contenido con Roblox; no activa el guardado de los jugadores ni las compras.
7. Pulsa **Crear**. Conserva la experiencia privada mientras configuras sus productos.
8. Anota el enlace y el nombre de esta nueva experiencia. No uses el lugar de Color Chaos.

El nombre es una propuesta de trabajo y su disponibilidad no está comprobada. Si Roblox rechaza la descripción, conserva el mensaje exacto antes de modificarla; puede ser un filtro o un problema distinto del límite de caracteres.

## 4. Configura la capacidad y encuentra el Dashboard

1. Abre [Creator Dashboard → Creaciones](https://create.roblox.com/dashboard/creations).
2. Selecciona **Color Rush: Corre y Recuerda**, la experiencia que acabas de publicar.
3. Abre la configuración del **lugar inicial**. En algunos diseños está bajo **Configurar → Lugares**.
4. Establece **Máximo de jugadores: 20** y guarda.

Veinte es la capacidad del servidor, no el mínimo para comenzar. El código permite iniciar con dos jugadores.

## 5. Sube el icono y la miniatura

Las imágenes están dentro de la carpeta del segundo juego:

```text
Descargas\Robloxstudio-main\games\color-rush\assets
```

| Archivo | Uso |
| --- | --- |
| `icon.png` | Icono de la experiencia |
| `banner.png` | Miniatura o portada |
| `revive.png` | Icono de ambos productos de reentrada |
| `coins.png` | Icono de los tres productos de monedas |
| `vip.png` | Icono del pase VIP |
| `trail.png` | Ilustración promocional de estelas; no requiere subir un producto extra |

1. En el Dashboard, busca **Icono** e **Imágenes en miniatura** en la configuración del lugar inicial.
2. Sube **icon.png** como icono y **banner.png** como miniatura.
3. Guarda. Roblox puede revisar las imágenes antes de mostrarlas públicamente.

Si la pantalla dice que se heredan del lugar inicial, abre ese lugar para cambiarlas. Los nombres de menús pueden variar. Selecciona los PNG reales de la carpeta, no una URL ni un archivo de código.

Son ilustraciones promocionales originales. No las describas como capturas reales de una partida. Los 250 personajes del juego se generan en sus paneles; no hay que subir 250 imágenes al Dashboard.

## 6. Crea los cinco productos de desarrollador

1. En el menú de tu experiencia, abre **Monetización → Productos del desarrollador**.
2. Pulsa **Crear producto**.
3. Crea **cada fila de esta tabla como un producto diferente**:

| Nombre | Descripción para copiar | Precio base recomendado | Imagen |
| --- | --- | ---: | --- |
| 1 reentrada | Recibe 1 crédito de reentrada. Máximo una reentrada por partida, incluida la final. Si la partida termina, conserva el crédito para otra. | 9 Robux | `revive.png` |
| 3 reentradas | Recibe 3 créditos guardados. Máximo una reentrada por partida, incluida la final. Los créditos no usados quedan para otras partidas. | 25 Robux | `revive.png` |
| 200 monedas | Recibe 200 monedas de Color Rush para cosméticos de entrega conocida. No entrega Robux ni una victoria. | 19 Robux | `coins.png` |
| 800 monedas | Recibe 800 monedas de Color Rush para cosméticos de entrega conocida. No entrega Robux ni una victoria. | 59 Robux | `coins.png` |
| 2000 monedas | Recibe 2000 monedas de Color Rush para cosméticos de entrega conocida. No entrega Robux ni una victoria. | 99 Robux | `coins.png` |

4. Elige el precio en el campo del Dashboard y guarda cada producto. Puedes cambiar las recomendaciones; la entrega debe seguir coincidiendo con la tabla.
5. En la lista, abre el menú **⋯** del producto → **Copiar ID del recurso**. Si Roblox muestra directamente **ID de producto**, copia ese número.
6. Anota cada ID junto a su producto en la tabla del paso 8.

La misma imagen puede usarse en varios paquetes: los nombres y descripciones indican la cantidad exacta. Un crédito no entrega Robux y el paquete de tres no permite volver tres veces a la misma partida.

El **ProductId** es el identificador del producto. No copies el precio, el ID de la imagen, el de la experiencia ni el del lugar.

## 7. Crea el pase VIP Prisma

1. En la misma experiencia, abre **Monetización → Pases**.
2. Pulsa **Crear pase**.
3. Nombre: **VIP Prisma**.
4. Imagen: **vip.png**, de la carpeta del segundo juego.
5. Descripción:

   ```text
   Obtén el título VIP y una estela Prisma exclusiva en Color Rush. Compra permanente para esta experiencia. No cambia la velocidad, no muestra respuestas y no garantiza victorias. No incluye Roblox Premium ni Roblox Plus.
   ```

6. Crea el pase. En su configuración de **Ventas**, activa la venta y establece **79 Robux** como precio base recomendado, o el precio que elijas.
7. Guarda y copia el **ID del pase** desde la lista o sus opciones. Ese es el **PassId**.

Los pases se compran una vez. Las monedas y los créditos son productos repetibles. No conviertas VIP en producto de desarrollador ni las reentradas en pases.

## 8. Registra tus seis IDs

Guarda una copia de esta tabla con tus números:

| Entrada en Config | Producto de Roblox | ID de tu cuenta |
| --- | --- | --- |
| `revive1` | 1 reentrada | __________ |
| `revive3` | 3 reentradas | __________ |
| `coins200` | 200 monedas | __________ |
| `coins800` | 800 monedas | __________ |
| `coins2000` | 2000 monedas | __________ |
| `VIP` | Pase VIP Prisma | __________ |

Los IDs no son contraseñas: sirven para identificar los productos públicos. No se necesitan tu contraseña, cookies ni tokens en el chat.

## 9. Coloca los IDs en Studio

1. Regresa a Studio con **la experiencia de Color Rush** abierta.
2. Detén cualquier simulación.
3. Abre **Explorador**. Si su buscador tiene texto, pulsa su **X** para mostrar todos los elementos.
4. Despliega **ReplicatedStorage → ColorRush**.
5. Haz doble clic en **Config**. No edites el módulo `Commerce` de ServerScriptService.
6. En el código, pulsa **Ctrl + F** y busca **Config.Commerce**.
7. Busca cada `Key` de la tabla y sustituye únicamente su **ProductId = 0**. En `VIP`, cambia **PassId = 0**.

Ejemplo: si el producto cuesta **9 Robux** y su ID es **123456789**, la línea correcta es:

```lua
ProductId = 123456789,
```

**No escribas `ProductId = 9`.** El precio vive en Roblox; el ID conecta el producto con su entrega.

8. Escribe los IDs sin comillas y conserva las comas. No cambies `Key`, las cantidades que entrega el producto ni el nombre de DataStore.
9. Pulsa **Archivo → Publicar en Roblox**, o **Alt + P**. Ahora actualiza **la misma experiencia de Color Rush**; no debes crear otra.
10. Si no pide confirmación, puede haber publicado directamente. Revisa la notificación o **Salida** para comprobar si informa de un error.
11. Guarda también una copia local con **Archivo → Guardar en un archivo**.

Los seis IDs empiezan en `0` para dejar las ofertas sin activar hasta que existan en tu cuenta. La nube no puede inventarlos ni efectuar cobros reales.

**Guarda los seis IDs también en `games/color-rush/src/shared/Config.luau`, o compártelos para incorporarlos a GitHub.** Editar Config en Studio no actualiza GitHub. Una descarga futura o una sincronización de Rojo con ceros podría reemplazar tu configuración.

## 10. Servidores privados, opcionales

Si quieres vender acceso a un servidor para jugar con amigos:

1. Busca la sección de **Servidores privados** en el Dashboard de esta experiencia.
2. Habilítalos si Roblox permite la opción para tu experiencia.
3. Puedes ofrecerlos gratis o elegir **29 Robux al mes** como precio base inicial.
4. Guarda y explica que es un pago mensual administrado por Roblox.

No crees un sexto producto de desarrollador para ello. No hay un ProductId adicional en Config. El servidor privado mantiene las mismas reglas y el mínimo de participantes.

## 11. Abre el acceso público

1. En el Dashboard de Color Rush, completa **Madurez del contenido y cumplimiento** según el contenido real del juego.
2. Revisa los requisitos de cuenta y audiencia que Roblox muestre. Haber verificado documentos no elimina un plazo de antigüedad que siga apareciendo pendiente.
3. Busca **Público → Alcance**, **Audiencia** o **Acceso**, según el diseño actual del panel.
4. Elige **Pública** cuando Roblox lo permita y guarda.
5. Usa el enlace de la experiencia para abrirla en la aplicación de Roblox. Roblox crea sus servidores al entrar jugadores.

Si el botón está bloqueado, el mensaje del Dashboard identifica el requisito pendiente. No borres el juego ni crees otro para superar ese bloqueo. Esta guía no afirma que tu cuenta ya cumpla requisitos que no podemos observar.

La activación de productos y publicación se hacen en tu cuenta. La validación técnica realizada en la nube no ejecuta física, renderizado, redes ni cobros reales de Roblox; consulta [ESTADO.md](ESTADO.md).

## 12. Rojo, opcional para futuras actualizaciones

Rojo tiene dos partes: **rojo.exe en tu computadora** y **el plugin de Rojo dentro de Studio**. El programa lee los archivos; el plugin los sincroniza. GitHub guarda versiones, pero no envía el juego a Studio por sí solo.

1. Abre [la descarga oficial de Rojo 7.6.1](https://github.com/rojo-rbx/rojo/releases/tag/v7.6.1).
2. En un Windows habitual de 64 bits, descarga **rojo-7.6.1-windows-x86_64.zip** y extráelo.
3. Copia **rojo.exe** dentro de **games/color-rush**, junto a su **default.project.json**. No lo pongas en la raíz del primer juego para este procedimiento.
4. Abre esa carpeta en el Explorador de Windows. En la barra de dirección escribe **powershell** y pulsa Enter.
5. Ejecuta:

   ```powershell
   .\rojo.exe --version
   ```

6. Cierra Studio e instala el plugin:

   ```powershell
   .\rojo.exe plugin install
   ```

7. Confirma que **src/shared/Config.luau de esta carpeta** contiene los seis IDs reales de Color Rush.
8. Abre Studio y la experiencia existente de Color Rush.
9. Desde la misma PowerShell, ejecuta:

   ```powershell
   .\rojo.exe serve default.project.json
   ```

10. Deja abierta esa ventana. En Studio, abre **Plugins → Rojo**, usa **localhost**, puerto **34872**, y pulsa **Connect**. Si la terminal muestra otro puerto, usa ese.
11. Revisa los cambios y confirma que sincronizas **Color Rush**, no Color Chaos.
12. Publica con **Archivo → Publicar en Roblox**.

No ejecutes `rojo init`: este juego ya tiene su proyecto. No necesitas configurar el PATH si sigues estos comandos. Una sincronización no publica por sí sola: publicar en Roblox y subir código a GitHub son acciones distintas.

Para actualizar sin Rojo, consulta [OPERACION.md](OPERACION.md). Para entender los precios y las ventajas con detalle, consulta [MONETIZACION.md](MONETIZACION.md).

## Fuentes oficiales

- [Publicar experiencias y lugares](https://create.roblox.com/docs/production/publishing/publish-games-and-places).
- [Productos de desarrollador](https://create.roblox.com/docs/production/monetization/developer-products).
- [Pases](https://create.roblox.com/docs/production/monetization/passes).
- [Precios regionales](https://create.roblox.com/docs/production/monetization/regional-pricing).
- [Instalación de Rojo](https://rojo.space/docs/v7/getting-started/installation/).
