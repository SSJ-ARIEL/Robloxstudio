# Actualizar Color Chaos sin cambiar tus productos

Esta actualización es para **Color Chaos**, tu primer juego. Añade un lobby que ya está dentro del archivo antes de arrancar los scripts. La actualización conserva el módulo **Config completo** de tu experiencia, incluidos tus tres `ProductId`, el `PassId` VIP y el nombre del almacén de progreso. No tienes que copiarlos otra vez.

## Descargar

[Descargar carpeta completa](https://github.com/SSJ-ARIEL/Robloxstudio/raw/refs/heads/main/downloads/ColorChaos-lobby-completo.zip).

1. Descarga y descomprime el ZIP en tu PC.
2. Dentro de la carpeta **ColorChaos → downloads** encontrarás **ColorChaosUpdate.rbxmx**. Es el modelo para actualizar tu juego existente. También se incluye la versión binaria **ColorChaosUpdate.rbxm**.
3. Los archivos **ColorChaos.rbxl** y **ColorChaos.rbxlx** son una experiencia completa con los IDs de la plantilla en cero. Úsalos únicamente para abrir una copia completa; para conservar automáticamente tus ajustes, sigue el método del modelo de actualización.

## Aplicar sobre tu juego publicado

1. Abre **Roblox Studio** e inicia sesión con la cuenta que publicó Color Chaos.
2. En la pantalla inicial, abre **tu experiencia Color Chaos que ya existe**. Comprueba el título del juego. No abras Color Rush ni crees otra experiencia.
3. Si hay una partida en ejecución, pulsa el botón rojo **Detener**.
4. Guarda una copia en tu PC: **Archivo → Guardar en un archivo como**. Ponle `ColorChaos-antes-del-lobby.rbxl`.
5. Selecciona **Archivo → Importar modelo Roblox**. Elige **ColorChaosUpdate.rbxmx** de la descarga. Si el selector muestra solamente `.rbxm`, cambia el tipo de archivo a todos los modelos Roblox o selecciona **ColorChaosUpdate.rbxm**.
6. En **Explorador**, comprueba que apareció **Workspace → ColorChaosUpdate**. Los scripts dentro del modelo están desactivados. Importar añade el paquete; la actualización se aplica en el paso 8.
7. Abre **Vista → Barra de comandos**. Si tu versión usa pestañas diferentes, busca **Barra de comandos / Command Bar** en las opciones de Studio.
8. Pega exactamente esta línea en la barra y pulsa **Enter**:

   ```lua
   require(workspace.ColorChaosUpdate.Installer).apply()
   ```

9. En **Salida** debe aparecer **“Color Chaos actualizado. Config conservado…”**. El lobby también se verá en el editor. En **ServerStorage** quedarán una carpeta **ColorChaosBackup_…** con los objetos anteriores y el modelo importado **ColorChaosUpdate**. Sus scripts están desactivados y su escenario de preparación queda fuera del mundo activo, evitando pisos y puntos de aparición duplicados.
10. Publica los cambios con **Archivo → Publicar en Roblox**. Actualizas la misma experiencia; no selecciones **Publicar en Roblox como** para crear otra.
11. Vuelve a entrar al juego desde Roblox en un servidor nuevo. La publicación no sustituye el mapa de los servidores que ya estaban abiertos; en el Creator Dashboard puedes reiniciar los servidores cuando estés listo.

No necesitas instalar Rojo para este método. El lobby existe desde que se carga el lugar y Color Chaos puede comenzar con una sola persona. Las compras conservan los IDs que ya configuraste y permanecen asociadas a tu experiencia original.

## Si el instalador muestra un error

- **“Pulsa Detener…”**: detén la partida de Studio y ejecuta la línea otra vez.
- **“Este lugar no contiene el Config…”**: abre la experiencia original de Color Chaos. El instalador no aplica la actualización a otro juego.
- **“El paquete contiene un script activo…”** o **“Falta la carpeta…”**: elimina únicamente el modelo importado `ColorChaosUpdate` y vuelve a importar la descarga completa.
- **“Se restauraron los objetos originales…”**: la actualización se detuvo y repuso los objetos anteriores. Conserva la copia local y revisa el mensaje de Salida antes de publicar.

El instalador prepara y valida la nueva estructura antes de sustituir objetos. Reemplaza únicamente `ReplicatedStorage.ColorChaos`, `ServerScriptService.ColorChaosServer`, `StarterPlayer.StarterPlayerScripts.ColorChaosClient` y `Workspace.ColorChaosWorld`. Guarda los objetos anteriores en ServerStorage y, si ocurre un fallo durante la sustitución, intenta restaurarlos. No consulta DataStores ni toca monedas o recibos almacenados. Si Studio admite el registro de cambios, también deja una operación para **Deshacer**.

La descarga y las comprobaciones automáticas no equivalen a ejecutar el motor de Roblox ni a validar cobros reales. El mensaje genérico de un juego que aparece en blanco no identifica por sí solo el error de Studio; consulta **Salida** si persiste después de actualizar.
