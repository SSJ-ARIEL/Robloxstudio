# Actualizar y mantener Color Chaos

**Si aparece un problema, se corrigen los archivos y se publica una nueva versión de la misma experiencia. No hay que rehacer el juego ni pedir a los jugadores que empiecen de cero.**

GitHub conserva el historial de código; Roblox conserva las versiones publicadas del lugar. El progreso de los jugadores vive en DataStore, separado de los scripts y del mapa.

**Para instalar el lobby y la lava de la versión 1.1.0, sigue [ACTUALIZAR_LOBBY.md](ACTUALIZAR_LOBBY.md). El modelo de actualización conserva Config completo y deja los objetos anteriores en ServerStorage con sus scripts desactivados.**

## Actualizar usando Rojo

1. Obtén los archivos de la nueva versión del mismo repositorio.
2. Conserva tus tres ProductId y el PassId VIP en `src/shared/Config.luau`. No los sustituyas por los ceros de una plantilla.
3. Conserva `Config.DataStoreName` y las claves de datos existentes. Cambiar el nombre crea otro almacén; no es un método de actualización.
4. Abre en Studio **la experiencia existente**, con la cuenta o los permisos de su propietario.
5. Inicia `rojo serve default.project.json` en la computadora y conecta el plugin, como explica [PUBLICAR.md](PUBLICAR.md).
6. Acepta la sincronización del lugar y selecciona **File → Publish to Roblox**.
7. Guarda los cambios del código en GitHub. Subir código a GitHub y publicar en Roblox son acciones distintas.

Una conexión de Rojo no modifica por sí sola la versión pública. El juego cambia para los nuevos servidores cuando publicas el lugar.

## Actualizar sin instalar Rojo

1. Descarga la entrega actualizada y abre su `downloads/ColorChaos.rbxlx` en Studio.
2. Coloca tus cuatro IDs reales en **ReplicatedStorage → ColorChaos → Config** antes de publicarlo. Confirma que el nombre de DataStore coincide con el de tu juego existente.
3. Usa **File → Publish to Roblox As / Publicar en Roblox como**.
4. Selecciona **la experiencia que ya existe** y **su mismo lugar inicial**; confirma la actualización. No elijas crear una experiencia nueva.
5. Conserva una copia del archivo y de los IDs configurados.

Este flujo reemplaza el contenido del lugar con la nueva entrega. Si añadiste elementos propios dentro de Studio, comunica esos cambios para incorporarlos al proyecto antes de reemplazarlo.

## Qué pasa con los servidores abiertos

Al publicar, los servidores que ya están ejecutándose pueden continuar con la versión anterior. Los nuevos servidores usan la nueva versión. Si un arreglo urgente necesita llegar a todos, usa la opción de reiniciar los servidores de esa experiencia en el Dashboard.

Un reinicio interrumpe las partidas en curso. Hazlo cuando sea necesario y avisa a tus jugadores. No borres DataStore ni crees otra experiencia para forzar una actualización.

## Qué información sirve para corregir un problema

Envía el texto del error de **Output / Salida** de Studio si existe, qué estaba haciendo la persona y si ocurrió en computadora o celular. Una captura o video ayuda cuando el problema es visual. Con esa información se reproduce el problema y se corrige la parte afectada.

No compartas contraseñas, cookies, códigos de acceso ni datos privados de jugadores. Los enlaces de la experiencia y los IDs de productos sí sirven para revisar la configuración.

| Síntoma | Acción útil |
| --- | --- |
| El editor parece vacío | La versión 1.1.0 incluye piso, spawn y lobby permanentes. Confirma que abriste la entrega correcta. |
| El avatar cae en blanco al entrar | Instala el lobby permanente en la misma experiencia. El mínimo es una persona; no se necesitan cuatro. Si la partida sigue sin iniciar, revisa el error de Salida. |
| Un artículo no está activo | Revisa que tenga el ID real correcto, pertenezca a esta experiencia y esté a la venta. Publica Config después de cambiarlo. |
| El pase se compró pero el efecto no aparece | Confirma el PassId, la propiedad del pase y la conexión al servicio; conserva el mismo pase al corregirlo. |
| El progreso solo dura la sesión | Revisa el estado del guardado. En Studio el guardado permanente está desactivado; una sesión sin acceso a DataStore no debe vender productos como si todo estuviera disponible. |
| La tienda abre la ventana oficial pero no aparece la entrega | El paquete se confirma por recibo y guardado del servidor; puede quedar pendiente si Roblox no está disponible. No otorgues premios basándote en una captura de pago. |
| Todos parecen haber perdido el progreso tras una actualización | Comprueba la experiencia, el propietario, `Config.DataStoreName` y las claves de guardado antes de alterar datos. |
| Algunos jugadores siguen viendo la versión anterior | Sus servidores pueden seguir abiertos con la versión anterior. Decide si conviene reiniciarlos. |

## Reglas para proteger el progreso y las compras

- Conserva el nombre de DataStore y la identidad de la experiencia.
- Conserva los registros de recibos procesados para que una compra no se entregue dos veces.
- No ejecutes herramientas que borren perfiles o recibos como parte de una publicación.
- Si una futura actualización cambia el formato de guardado, prepara una migración compatible y una copia de respaldo antes de modificar los datos.
- Usa una experiencia de desarrollo separada para cambios experimentales que escriban datos. Esta separación no obliga a recrear la experiencia de producción.

## Validación técnica de una entrega

En el entorno Linux de desarrollo, desde la carpeta del proyecto:

```sh
COLOR_CHAOS_TOOLS_DIR=/workspace/.tools/color-chaos bash tools/validate.sh
```

La herramienta verifica compilación, reglas y simulaciones del servidor, y genera el archivo para Studio. Los resultados exactos de cada entrega se deben registrar junto a esa versión.

Estas verificaciones no ejecutan física, controles, renderizado ni servicios reales de Roblox. Una compilación y las pruebas simuladas no demuestran que se haya realizado una compra real en tu cuenta. Conserva esta distinción al presentar una versión como lista para lanzamiento.

En Windows no necesitas ejecutar ese comando Bash para publicar. La activación de productos, la publicación y los requisitos de cuenta se completan en Roblox con los pasos de [PUBLICAR.md](PUBLICAR.md).

Fuentes: [actualizar experiencias](https://create.roblox.com/docs/projects/update-games), [DataStore](https://create.roblox.com/docs/cloud-services/data-stores) y [recibos de compras](https://create.roblox.com/docs/production/monetization/developer-products).
