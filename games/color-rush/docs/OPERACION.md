# Actualizaciones y soporte de Color Rush

Si aparece un problema, se corrige el archivo afectado y se publica una actualización de **la misma experiencia**. No tienes que reconstruir todo ni volver a crear el juego.

Color Rush y Color Chaos comparten repositorio, pero tienen proyectos Rojo, carpetas, configuración y experiencias diferentes. No conectes el proyecto de un juego al lugar del otro.

## Antes de actualizar

Conserva los cinco ProductId y el PassId VIP de Color Rush. También conserva el nombre de DataStore y la experiencia donde juegan tus usuarios: cambiar de experiencia o de almacén separa el juego del progreso existente.

Si modificaste scripts, objetos o los IDs únicamente dentro de Studio, incorpora esos cambios al código antes de sincronizar o reemplazar el lugar. Una descarga de GitHub no contiene automáticamente las ediciones que hiciste en Studio.

## Con Rojo

1. Obtén la nueva versión de este repositorio.
2. Revisa que **games/color-rush/src/shared/Config.luau** conserva tus seis IDs.
3. Abre en Studio la experiencia existente de Color Rush.
4. Desde **games/color-rush**, ejecuta `rojo serve default.project.json` y conecta el plugin al puerto que indique la terminal.
5. Revisa la sincronización y publica con **Archivo → Publicar en Roblox**.

La raíz del repositorio tiene otro `default.project.json`: corresponde a Color Chaos. No lo uses para actualizar Color Rush.

## Sin Rojo

1. Descarga y extrae la nueva entrega.
2. Abre **games/color-rush/downloads/ColorRush.rbxlx** en Studio.
3. Coloca tus seis IDs en **ReplicatedStorage → ColorRush → Config**. Conserva el mismo nombre de DataStore que tenía tu entrega publicada.
4. Usa **Archivo → Publicar en Roblox como**.
5. Selecciona **tu experiencia existente de Color Rush y su mismo lugar inicial**. Confirma el reemplazo de ese lugar. No elijas crear una experiencia nueva ni el lugar de Color Chaos.
6. Conserva una copia local del archivo configurado y de la tabla de IDs.

Reemplazar el lugar actualiza código y mapa, no requiere borrar el progreso. Si habías añadido contenido propio en Studio, hay que incorporarlo al proyecto antes de reemplazarlo.

## Servidores que ya están abiertos

Los servidores existentes pueden continuar ejecutando la versión anterior. Los nuevos usan la publicada. Si necesitas aplicar una corrección urgente a todos, Roblox ofrece opciones para reiniciar los servidores de la experiencia.

Un reinicio interrumpe las partidas en curso. No cambies el nombre de DataStore ni recrees la experiencia para forzar una actualización.

## Mantener las compras

- Conserva los productos y el pase de la experiencia correcta.
- Guarda el registro de recibos: permite reconocer un pago ya entregado sin duplicarlo.
- Si cambias un precio, hazlo en el Dashboard. El ID no cambia por cambiar el precio.
- Si retiras una oferta, conserva la posibilidad de resolver recibos de compras anteriores. No reutilices su ID para entregar otra cosa.
- No concedas créditos o monedas porque alguien envíe una captura. La entrega depende del recibo oficial y de su registro en el servidor.
- Los créditos que se compran cuando termina una partida siguen siendo saldo del jugador. No borres ese saldo ni lo cambies por vidas ilimitadas.
- Un pase VIP comprado en Color Chaos no activa VIP en Color Rush: son beneficios y pases de experiencias diferentes.

## Información útil para corregir problemas

Indica qué ocurrió, en qué dispositivo y qué hizo la persona inmediatamente antes. Si hay un error en **Salida**, comparte su texto. Una captura o video ayuda para errores visuales. No compartas contraseñas, cookies, tokens ni datos personales.

| Síntoma | Qué revisar |
| --- | --- |
| El editor parece vacío | El escenario se genera cuando inicia el servidor. |
| No comienza la partida | Debe haber al menos dos participantes; veinte es la capacidad máxima. |
| No aparece una oferta | Confirma su ID real, su tipo y su estado en Roblox. Publica Config después de editarlo. |
| El diálogo cobra un precio distinto del anunciado | Revisa precio actual y configuración regional. El diálogo oficial indica el importe final. |
| No permite revivir otra vez | El límite es una reentrada total por partida, incluida la final. |
| La compra se confirmó tras declarar ganador | El crédito queda para otra partida; no revoca la victoria. |
| VIP no aparece | Revisa PassId, propietario del pase y conexión al servicio de Roblox. |
| La sesión no conserva el saldo | Revisa disponibilidad de guardado y que no cambiaste experiencia o DataStore. Las simulaciones de Studio no equivalen a un guardado real. |
| Los productos de Color Chaos aparecen en Color Rush | Se copiaron IDs de la otra experiencia o se sincronizó el proyecto equivocado. |
| Algunos jugadores ven una versión anterior | Su servidor puede seguir abierto con la versión anterior. |

## Integridad del progreso

No borres perfiles ni recibos como parte de una actualización. Si el formato de datos cambia, usa una migración compatible. Conserva el nombre de DataStore y los identificadores de jugadores.

Las comprobaciones técnicas del código y del paquete se registran en [ESTADO.md](ESTADO.md). No demuestran por sí solas que se haya cobrado una compra real, ejecutado el motor o aprobado la audiencia pública de tu cuenta.
