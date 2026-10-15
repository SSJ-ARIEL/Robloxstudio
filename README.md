# Color Chaos — entrega 1.1.0

Este repositorio contiene dos experiencias independientes. El segundo juego, **Color Rush: Corre y Recuerda**, está en [games/color-rush](https://github.com/SSJ-ARIEL/Robloxstudio/tree/main/games/color-rush), con su propio proyecto Rojo, archivo de Studio, personajes, compras y guías. La configuración de la raíz sigue correspondiendo a Color Chaos.

Experiencia cooperativa para 1–12 jugadores. El equipo reconstruye puentes, repara estaciones y rescata chispas mientras sube la lava. Cada avance eleva las plataformas compartidas. El lobby, la tienda, el mirador y el punto de aparición están guardados dentro del archivo y aparecen incluso antes de arrancar los scripts. Código, escenarios y gráficos creados para este proyecto; el nombre es provisional.

## Descargar y publicar

- **[Descargar Color Chaos con lobby en ZIP](https://github.com/SSJ-ARIEL/Robloxstudio/raw/refs/heads/main/downloads/ColorChaos-lobby-completo.zip)**.
- **[Actualizar tu juego publicado conservando tus cuatro IDs](docs/ACTUALIZAR_LOBBY.md)**.
- [Descargar archivo binario para Studio](https://github.com/SSJ-ARIEL/Robloxstudio/raw/refs/heads/main/downloads/ColorChaos.rbxl).
- [Descargar juego para Studio](https://github.com/SSJ-ARIEL/Robloxstudio/raw/refs/heads/main/downloads/ColorChaos.rbxlx).
- **[Pasos concretos para publicar y activar compras](docs/PUBLICAR.md)**.
- [Productos, beneficios e identificadores](docs/PRODUCTOS.md).
- [Cómo actualizar sin rehacer el juego](docs/OPERACION.md).

Si ya publicaste Color Chaos, importa `downloads/ColorChaosUpdate.rbxmx` sobre esa misma experiencia y sigue [la guía de actualización](docs/ACTUALIZAR_LOBBY.md): el instalador conserva tu Config completo y crea una copia local de los objetos anteriores. Para una copia nueva, abre `downloads/ColorChaos.rbxl` desde **Archivo → Abrir un archivo**; esta plantilla tiene los IDs en cero. Ninguno de estos métodos requiere instalar Rojo.

## Funciones incluidas

| Sistema | Función |
| --- | --- |
| Lobby | Piso y spawn permanentes, tienda, instrucciones, escaleras y mirador seguro. |
| Rondas | Inicio desde una persona, cronómetro, rotación automática y resultados compartidos. |
| Lava | Sube durante el juego; cada nuevo avance eleva al equipo. Los errores de memoria no permiten acumular altura repitiendo pasos. |
| Caídas | Retorno al lobby, sin perderse en el vacío ni reingresar a la ronda en curso. |
| Espectadores | Cámara opcional para observar jugadores y volver a tu avatar. |
| Puentes de memoria | Observar cinco letras, activar su secuencia y llegar al reactor. |
| Reparación en equipo | Activar ocho estaciones del color solicitado. |
| Rescate cromático | Activar un puente, recuperar una chispa y entregarla. |
| Progreso | Monedas, victorias, XP, niveles y tres misiones diarias gratuitas. |
| Personalización | Siete auras con monedas, dos con estelas, y aura Prisma para propietarios VIP. |
| Tienda Robux | Paquetes garantizados de 100, 400 y 1000 monedas; pase VIP cosmético. |
| VIP Prisma | Aura de colores y título VIP; no concede victorias ni multiplicadores. |
| Guardado | DataStore con bloqueo de sesión, guardado periódico y salida. |
| Recibos | Crédito e ID guardados juntos; recuperación tras confirmaciones fallidas y rechazo de duplicados. |
| Interfaz | Computadora, móvil, prompts de consola, ayuda y símbolos A/B/C/D junto a los colores. |
| Recursos | Iconos de juego/productos/pase, banner ilustrado y SVG originales editables. |

Los jugadores que entran tarde o caen esperan la siguiente ronda. Las recompensas requieren colaborar. Las monedas también se obtienen jugando; no existen recompensas aleatorias pagadas ni compras que vendan la victoria.

## Activación de ventas

El código de compras está implementado. Roblox debe crear **tres ProductId y un PassId bajo tu experiencia**; esos cuatro números se configuran en `src/shared/Config.luau`, sección `Config.Commerce`. Los ceros indican artículos sin activar. No son IDs ficticios ni compras gratuitas.

El precio se fija en Creator Dashboard, se consulta localmente y se confirma en el diálogo oficial de Roblox. El servidor entrega productos exclusivamente mediante `ProcessReceipt` después de confirmar la persistencia. Los eventos de cierre no entregan monedas. La propiedad VIP se consulta a Roblox.

Las compras de productos se bloquean cuando el guardado no está disponible, hay una transacción pendiente, el saldo no tiene capacidad o el historial alcanza su límite de seguridad. Los recibos existentes se conservan. No borres productos ni registros con compras pendientes.

Studio usa progreso temporal y desactiva compras de productos dependientes de DataStore. La facturación y persistencia reales requieren la experiencia publicada. No se han efectuado compras ni pruebas del motor desde esta nube.

## Rojo para futuras actualizaciones

Rojo tiene un programa en tu computadora y un plugin en Studio. Para Windows, descarga [Rojo 7.6.1](https://github.com/rojo-rbx/rojo/releases/tag/v7.6.1), extrae `rojo.exe` y cópialo junto a `default.project.json`. Abre PowerShell en esa carpeta:

```powershell
.\rojo.exe --version
.\rojo.exe plugin install
.\rojo.exe serve default.project.json
```

Instala el plugin con Studio cerrado. Después abre tu experiencia existente, entra en **Plugins → Rojo** y conecta a **localhost:34872**. Mantén abierta la terminal y publica desde Studio después de sincronizar. Conserva primero los cuatro IDs en el archivo fuente; Rojo no debe reemplazarlos por ceros.

En macOS puedes instalar el binario oficial apropiado para tu arquitectura y usar `rojo plugin install` y `rojo serve default.project.json` desde la carpeta del proyecto. La documentación oficial detalla la [instalación](https://rojo.space/docs/v7/getting-started/installation/).

Una corrección actualiza la misma experiencia. Conservando su identidad y `Config.DataStoreName`, no necesitas rehacer el juego ni borrar el progreso. El actualizador incluido conserva automáticamente Config; una sincronización directa de Rojo requiere conservar primero los IDs en el código fuente. GitHub guarda versiones del código; Roblox publica el contenido y administra servidores/pagos.

## Validación para desarrollo

Usa el checkout existente; cada tarea de nube ya está aislada y no requiere un worktree adicional. Desde el proyecto, en Linux x86_64 con bash, curl, unzip, sha256sum y Python 3:

```sh
COLOR_CHAOS_TOOLS_DIR=/workspace/.tools/color-chaos bash tools/setup.sh
COLOR_CHAOS_TOOLS_DIR=/workspace/.tools/color-chaos bash tools/validate.sh
```

La instalación utiliza publicaciones oficiales HTTPS y SHA-256 fijado. Ejecuta instalación y validación en ese orden. La validación compila Luau, comprueba reglas y compras, y ejecuta el servidor, cliente, bienvenida e instalador con servicios simulados. Rojo genera `build/ColorChaos.rbxlx`. Los resultados de esta entrega están en [ESTADO.md](docs/ESTADO.md).

Para generar archivos completos, modelos de actualización inactivos y ZIP:

```sh
COLOR_CHAOS_TOOLS_DIR=/workspace/.tools/color-chaos python3 tools/package-release.py
```

Las simulaciones no ejecutan física, renderizado, red, DataStore ni facturación real de Roblox. Consulta [el estado de la entrega](docs/ESTADO.md) para distinguir código entregado, configuración pendiente y operaciones no verificadas. El generador opcional de gráficos `tools/make-icons.py` requiere Pillow; no hace falta ejecutarlo para publicar porque los PNG ya están incluidos.

## Archivos

- `src/server/Main.server.luau`: mapas, rondas, persistencia y validación.
- `src/server/Commerce.luau`: compras oficiales y verificación VIP.
- `src/shared/`: configuración, reglas, misiones y registro de recibos.
- `src/client/Main.client.luau`: interfaz y precios locales.
- `src/client/Bootstrap.client.luau`: bienvenida independiente del inicio del servidor.
- `scene/`: lobby y escenario incluidos antes de ejecutar scripts.
- `release/Installer.luau`: actualización conservando Config y copia local reversible.
- `assets/`: PNG y SVG originales para el Dashboard.
- `downloads/ColorChaos.rbxlx`: juego generado entregado.
- `docs/`: publicación, catálogo, mantenimiento y estado.

Las mecánicas de género pueden coincidir con otras experiencias. No se acredita exclusividad del nombre ni de esas mecánicas, y no se garantizan jugadores o ingresos.
