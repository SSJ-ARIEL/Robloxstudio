# Instalar Color Chaos 2 conservando tus productos

Esta guía actualiza **tu experiencia Color Chaos existente** a Ciudad Prisma: lobby permanente, personajes 3D, ocho sectores con cinco puertas, fantasmas, regalos y clasificaciones. El nombre de este documento se conserva para que sigan funcionando sus enlaces anteriores.

El instalador conserva **todo tu módulo Config**, incluidos los tres ProductId, el PassId VIP y el nombre de DataStore. La nueva dinámica usa GameSettings por separado; los ajustes antiguos de lava que queden en Config no activan el juego anterior.

## Descargar

**[Descarga ColorChaos2-completo.zip](https://github.com/SSJ-ARIEL/Robloxstudio/raw/refs/heads/main/downloads/ColorChaos2-completo.zip)** y descomprímelo. Dentro de **ColorChaos2 → downloads** está **ColorChaosUpdate.rbxmx**. Ese es el archivo que importarás. También se incluye `ColorChaosUpdate.rbxm`, la misma actualización en formato binario.

Los archivos `ColorChaos2.rbxl` y `ColorChaos2.rbxlx` contienen el juego completo con los IDs de plantilla en cero. Para conservar tus IDs automáticamente, sigue estos pasos con el modelo de actualización.

## Pasos en Roblox Studio

1. Abre Roblox Studio con la cuenta propietaria. En tus experiencias, abre **Color Chaos, el juego que ya publicaste**.
2. Pulsa **Detener** si hay una simulación ejecutándose.
3. Selecciona **Archivo → Guardar en un archivo como**. Guarda una copia llamada `ColorChaos-antes-de-Ciudad-Prisma.rbxl` en tu PC.
4. Selecciona **Archivo → Importar modelo Roblox** y abre **ColorChaos2 → downloads → ColorChaosUpdate.rbxmx**. Si el selector solo admite archivos `.rbxm`, usa `ColorChaosUpdate.rbxm`.
5. En **Explorador**, debe aparecer **Workspace → ColorChaosUpdate**. La importación prepara el paquete; todavía no reemplaza los scripts de tu experiencia.
6. Abre **Vista → Barra de comandos / Command Bar**. Pega esta línea y pulsa **Enter**:

   ```lua
   require(workspace.ColorChaosUpdate.Installer).apply()
   ```

7. Abre **Vista → Salida / Output**. Debe aparecer **“Color Chaos 2 actualizado. Config conservado…”**. El lobby y el recorrido deben verse en el editor. Los objetos anteriores quedan en **ServerStorage → ColorChaosBackup_…** y el paquete importado se retira de Workspace.
8. Usa **Archivo → Publicar en Roblox** para actualizar la misma experiencia. No necesitas crear otra.
9. Entra desde Roblox en **un servidor nuevo**. Si necesitas que todos reciban la versión nueva, usa el reinicio de servidores de esa experiencia en Creator Dashboard; esto interrumpe las partidas antiguas.

No necesitas Rojo, reinstalar Studio ni volver a crear tus productos. Puedes iniciar una práctica con una sola persona. Las partidas competitivas requieren al menos dos participantes al comenzar.

## Si aparece un mensaje del instalador

| Mensaje | Qué hacer |
| --- | --- |
| “Pulsa Detener…” | Detén la simulación de Studio y ejecuta la línea de nuevo. |
| “Este lugar no contiene el Config…” | Abre tu experiencia original Color Chaos; no el archivo de Color Rush. |
| “El paquete contiene un script activo…” | Retira únicamente el modelo importado ColorChaosUpdate y vuelve a importar la descarga completa. |
| “Falta la carpeta…”, “El recorrido está incompleto…” o falta un módulo | Vuelve a importar ColorChaosUpdate completo. No copies carpetas sueltas. |
| “Se restauraron los objetos originales…” | La instalación se detuvo y repuso los objetos anteriores. Conserva tu copia local y comparte el texto completo de Salida antes de publicar. |

Si el lobby se ve pero las rondas no arrancan, abre **Salida**, copia el primer error rojo completo y anota si estabas en Studio o en la aplicación Roblox. El instalador conserva Config literalmente; si ese módulo tenía un error de sintaxis previo, también necesita corregirse. El error genérico “Error al guardar” al publicar no permite deducir por sí solo un fallo del archivo.

## Qué conserva y qué sustituye

Sustituye únicamente `ReplicatedStorage.ColorChaos`, `ServerScriptService.ColorChaosServer`, `StarterPlayer.StarterPlayerScripts.ColorChaosClient` y `Workspace.ColorChaosWorld`. Conserva el Config original dentro del nuevo conjunto de módulos. Los modelos y scripts anteriores quedan respaldados y desactivados. El modelo importado también conserva sus scripts inactivos y sale del mundo activo para evitar puntos de aparición duplicados.

Antes de sustituir objetos, comprueba el spawn sobre un piso sólido, los ocho sectores, sus cuarenta puertas y los módulos necesarios. Si una sustitución falla, intenta restaurar las identidades y los estados de los objetos originales. También registra una operación de Deshacer cuando Studio lo permite.

El instalador no consulta DataStore, no procesa compras y no publica por sí mismo. La copia en ServerStorage respalda objetos del lugar, no los datos almacenados de los jugadores. Conserva además tu archivo de respaldo en la PC.
