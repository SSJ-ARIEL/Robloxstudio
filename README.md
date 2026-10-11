# Color Chaos

Juego cooperativo para Roblox escrito en Luau y organizado para Rojo. Una máquina ha perdido su energía cromática: los jugadores recuperan colores, activan mecanismos y rescatan chispas para repararla. Cada color tiene un nombre y un símbolo; las indicaciones no dependen únicamente del color.

Esta primera versión incluye un vestíbulo, partidas por rondas, tres desafíos, interfaz adaptable, monedas y victorias obtenidas jugando, y auras cosméticas que se consiguen con esas monedas. El escenario se construye mediante código cuando inicia el servidor. Se puede jugar solo y probar con varios jugadores.

El nombre es provisional. El código y los escenarios de esta versión se crean para este proyecto; eso no acredita que el nombre esté disponible ni que ninguna otra experiencia comparta mecánicas generales.

## La primera prueba más rápida

La entrega incluye `build/ColorChaos.rbxlx`. Si la interfaz de esta conversación permite descargar el archivo, descárgalo, ábrelo en Roblox Studio con **File → Open from File** y pulsa **Play**. Para esta primera prueba no necesitas instalar Rojo. El mapa aparece al iniciar la simulación.

Para desarrollar y sincronizar cambios después, descarga también todos los archivos fuente y sigue los pasos siguientes.

## Cómo se juega

1. Espera en el vestíbulo a que empiece la siguiente partida.
2. Observa las indicaciones de color y letra. Acércate a la estación correspondiente y usa su botón de interacción: **E** en computadora o el botón en pantalla en celular.
3. Sigue las instrucciones del desafío y ayuda a tu equipo antes de que termine el tiempo.
4. Contribuye a los objetivos para ganar monedas. Las victorias se obtienen al contribuir y sobrevivir a un desafío superado.

Los desafíos son:

| Desafío | Objetivo |
| --- | --- |
| Puentes de memoria | Recuerda la secuencia, activa sus letras en orden para crear los puentes, cruza y repara el reactor de llegada. |
| Reparación por relevos | Activa los nodos del mecanismo con el color que pide cada uno. |
| Rescate de chispas | Crea el puente del color indicado, recoge la chispa de su isla y entrégala en el reactor. |

Quien entra durante una ronda espera en el vestíbulo hasta el siguiente inicio. Al caer, el personaje vuelve al vestíbulo. Los resultados y las recompensas se calculan en el servidor.

## Qué necesitas en tu computadora

- Windows o macOS compatible con [Roblox Studio](https://create.roblox.com/).
- Una cuenta de Roblox para probar y publicar desde Studio.
- Una copia de esta carpeta, con `default.project.json` y `src/`.
- [Rojo 7.6.1](https://github.com/rojo-rbx/rojo/releases/tag/v7.6.1).
- El plugin de Rojo 7 en Studio, si quieres sincronización durante el desarrollo.

GitHub guarda las versiones del proyecto. Rojo convierte los archivos en objetos de Roblox y los sincroniza con Studio. Studio ejecuta el juego y permite publicarlo en tu cuenta. Para conectarse por `localhost`, Rojo y Studio deben estar en la misma computadora; el servidor de esta nube no se conecta directamente a tu Studio.

## 1. Obtén los archivos

El código ya está disponible en la rama **main** de [SSJ-ARIEL/Robloxstudio](https://github.com/SSJ-ARIEL/Robloxstudio). Abre el repositorio y usa **Code → Download ZIP**, o clónalo mediante GitHub Desktop. Extrae el ZIP si lo descargaste.

También puedes usar el paquete fuente `ColorChaos-source.zip` entregado con el proyecto. Debes tener `default.project.json`, `src/`, `tools/` y `tests/`, no solamente los scripts sueltos. Abre una terminal dentro de la carpeta que contiene `default.project.json`.

No ejecutes `rojo init`: este proyecto ya incluye su configuración.

## 2. Instala Rojo

La [guía oficial de instalación](https://rojo.space/docs/v7/getting-started/installation/) admite binarios publicados en GitHub y el gestor Rokit. Para este proyecto usamos la versión **7.6.1**.

### Windows

1. Descarga `rojo-7.6.1-windows-x86_64.zip` desde la publicación oficial de Rojo 7.6.1 y extráelo. Si Windows usa un procesador ARM, elige `windows-aarch64`.
2. Coloca `rojo.exe` en una carpeta permanente, por ejemplo `C:\Tools\Rojo`.
3. Busca **Editar las variables de entorno de esta cuenta** en Windows. Edita `Path`, agrega esa carpeta y guarda.
4. Cierra y vuelve a abrir PowerShell. Desde la carpeta del proyecto, ejecuta:

```powershell
rojo --version
rojo plugin install
```

El primer comando debe mostrar `Rojo 7.6.1`. El segundo instala el plugin local de esa versión; cierra Studio antes de ejecutarlo y vuelve a abrirlo después.

### macOS

1. Descarga `rojo-7.6.1-macos-aarch64.zip` si tu Mac tiene Apple Silicon, o `rojo-7.6.1-macos-x86_64.zip` si tiene Intel, y extráelo.
2. En Finder, crea la carpeta `Tools/Rojo` dentro de tu carpeta de usuario y coloca allí el ejecutable `rojo`.
3. En Terminal, habilita el ejecutable y agrega esa carpeta a la búsqueda de comandos de la sesión:

```sh
chmod +x "$HOME/Tools/Rojo/rojo"
export PATH="$HOME/Tools/Rojo:$PATH"
```

4. Para conservar el comando en nuevas sesiones, agrega la línea `export PATH="$HOME/Tools/Rojo:$PATH"` una sola vez a tu archivo `~/.zshrc` si utilizas el shell predeterminado de macOS. Puedes continuar en la terminal actual sin cerrar la sesión.
5. Entra en la carpeta del proyecto y ejecuta:

```sh
rojo --version
rojo plugin install
```

El resultado esperado también es `Rojo 7.6.1`. Instala el plugin con Studio cerrado y vuelve a abrirlo después. Si macOS bloquea el ejecutable, revisa su procedencia y las opciones de **Privacidad y seguridad** para ese archivo descargado del proyecto oficial.

La extensión de Rojo para VS Code es opcional; instalarla no agrega automáticamente el comando `rojo` al `PATH`.

## 3. Abre el juego por primera vez

### Windows / PowerShell

```powershell
New-Item -ItemType Directory -Force build | Out-Null
rojo build default.project.json -o build/ColorChaos.rbxlx
```

### macOS / Terminal

```sh
mkdir -p build
rojo build default.project.json -o build/ColorChaos.rbxlx
```

En Studio, usa **File → Open from File** y abre `build/ColorChaos.rbxlx`. Pulsa **Play** para iniciar el juego. El servidor genera el mapa al ejecutarse, por lo que no verás todo el escenario antes de iniciar la simulación.

Si ya tienes un archivo `ColorChaos.rbxlx` entregado con esta versión, puedes abrirlo directamente para la primera prueba. Para conservar cambios de código, trabaja con la carpeta del proyecto y vuelve a compilar o usa la sincronización descrita a continuación.

## 4. Conecta Rojo para trabajar

1. Detén la prueba en Studio.
2. Desde la carpeta del proyecto, ejecuta:

```sh
rojo serve default.project.json
```

3. Mantén abierta esa terminal. Rojo mostrará la dirección y el puerto; el puerto habitual es **34872**.
4. En Studio, abre el plugin desde **Plugins → Rojo**. Conecta a **localhost**, puerto **34872**, o al puerto que indique la terminal.
5. Revisa el cambio propuesto por el plugin y acepta la sincronización para este lugar de prueba.
6. Edita los archivos de `src/` desde tu editor. Para probar los cambios con el mapa regenerado, detén y vuelve a iniciar **Play**.

Los scripts administrados por Rojo deben editarse en los archivos del proyecto para que esos cambios se conserven en GitHub. La sincronización y la publicación son acciones distintas: después de probar una versión, publícala desde Studio.

## 5. Prueba antes de publicar para todos

Estas pruebas requieren Roblox Studio; una compilación satisfactoria en la nube no sustituye las pruebas del motor.

- **Una persona:** completar los tres desafíos, verificar instrucciones, cronómetro, reinicio de rondas y recompensas.
- **De dos a cuatro personas:** en las herramientas de pruebas de Studio, inicia un servidor local con varios clientes. Confirma que ven la misma ronda y que las acciones cooperativas funcionan.
- **Entrada tardía:** agrega un cliente durante una ronda y verifica que espere en el vestíbulo. Debe poder participar cuando comience una ronda posterior.
- **Caídas y reaparición:** cae del mapa; verifica el regreso al vestíbulo y que no se dupliquen las recompensas.
- **Resultados:** verifica que las personas que solo esperaron en el vestíbulo no reciban premios de esa ronda y que no se repita el premio al terminar.
- **Celular:** usa el emulador de dispositivos de Studio y, después, un celular real. Revisa los botones, textos, salto y control del personaje.
- **Errores:** abre **Output / Salida** en Studio. Investiga errores rojos antes de hacer pública la experiencia.

## 6. Publica una prueba privada y valida el guardado

1. Detén la simulación y usa **File → Publish to Roblox**. Crea una experiencia de prueba en tu cuenta.
2. En sus ajustes, conserva el acceso privado o restringido a tus colaboradores mientras haces las pruebas. Configura **Max Players / Máximo de jugadores = 12** para el lugar: el servidor de este juego admite hasta 12 participantes por ronda.
3. Prueba esa experiencia publicada desde la aplicación de Roblox. Studio permite simular partidas; el cliente publicado permite comprobar el comportamiento real de red, dispositivos y guardado.
4. Verifica las monedas, victorias y auras, sal, vuelve a entrar y comprueba su conservación. La interfaz indica si el guardado está activo o si el progreso solo corresponde a esa sesión.
5. Antes de abrir el acceso público, revisa el nombre, la descripción, los iconos, las clasificaciones y los requisitos que Roblox muestre para publicar esa experiencia.

El guardado se realiza desde el servidor y puede fallar por límites o indisponibilidad de Roblox. Esta versión desactiva las escrituras de DataStore cuando se ejecuta dentro de Studio: allí el progreso solo dura la sesión. Para comprobar la persistencia, usa el cliente de Roblox en una experiencia publicada de desarrollo. Mantén esa experiencia separada de producción y utiliza un nombre de DataStore distinto, configurado mediante `Config.DataStoreName` en `src/shared/Config.luau`.

## 7. Guarda tus cambios en GitHub

La opción gráfica es [GitHub Desktop](https://desktop.github.com/):

1. Inicia sesión con la cuenta que tiene acceso a `SSJ-ARIEL/Robloxstudio`.
2. Usa **File → Clone repository**, elige ese repositorio y clónalo a una carpeta local. Esta copia ya incluye el juego; no necesitas volver a subir los archivos de la entrega.
3. Inicia `rojo serve` desde esa carpeta y edita allí los archivos fuente. Conserva la carpeta `.git` creada por GitHub Desktop.
4. Para guardar cambios, revísalos en GitHub Desktop, escribe un resumen de la actualización y elige **Commit to main → Push origin**.
5. Abre el repositorio en GitHub y comprueba que los cambios aparecen en `main`. Para obtener actualizaciones antes de trabajar, usa **Fetch origin / Pull origin** en GitHub Desktop.

Los archivos `.tools/` y `build/` se excluyen mediante `.gitignore`: el proyecto fuente permite volver a generar el lugar. Subir código a GitHub no publica la experiencia en Roblox; eso se hace desde Studio.

## Monetización de esta versión

No hay compras de Robux activas ni identificadores de productos inventados. Las monedas se obtienen jugando y permiten conseguir auras cosméticas. Primero necesitamos validar que el juego funciona y que los jugadores quieren volver.

Para una actualización se pueden diseñar cosméticos, gestos o aspectos de herramientas con precios y beneficios claros. Activar ventas requiere crear los productos en tu cuenta de Roblox, configurar sus identificadores reales y comprobar el procesamiento de recibos en el servidor. Los ingresos y la disponibilidad de DevEx dependen de resultados y requisitos de Roblox; esta versión no promete ganancias.

## Archivos principales

| Archivo | Responsabilidad |
| --- | --- |
| `default.project.json` | Asigna archivos del proyecto a los servicios de Roblox. |
| `src/shared/Config.luau` | Colores, reglas, tiempos y configuración compartida. |
| `src/server/` | Escenarios, rondas, validación de acciones, recompensas y guardado. |
| `src/client/` | Interfaz y controles del jugador. |
| `build/ColorChaos.rbxlx` | Lugar generado para abrir en Studio. |

Para futuras tareas, utiliza esta copia del proyecto: cada tarea en la nube ya tiene un entorno aislado y no necesita un `git worktree` adicional.

## Validación en la nube / Linux

Esta sección es para el entorno de nube. **En Windows y macOS no necesitas ejecutar estos scripts Bash**: utiliza la instalación de Rojo y los comandos de los pasos 2–4.

Los helpers son para **Linux x86_64**, con `bash`, `curl`, `unzip`, `sha256sum` y Python 3. Instalan Rojo 7.6.1 y Luau 0.694 desde sus publicaciones oficiales y verifican las sumas SHA-256. Desde la carpeta del proyecto:

```sh
bash tools/setup.sh
bash tools/validate.sh
```

La instalación local queda en `.tools/`. La validación compila los archivos Luau, ejecuta 20 pruebas de reglas, simula la lógica del servidor con servicios y jugadores ficticios y genera `build/ColorChaos.rbxlx`. La simulación comprueba las tres rondas y las recompensas, incluyendo entrada tardía y recuperación de una chispa. No ejecuta el motor de Roblox ni valida física, red, apariencia o disponibilidad real de DataStore.

En el entorno preparado para este proyecto, las herramientas también pueden estar fuera del repositorio. Usa la misma ruta en ambos comandos:

```sh
COLOR_CHAOS_TOOLS_DIR=/workspace/.tools/color-chaos bash tools/setup.sh
COLOR_CHAOS_TOOLS_DIR=/workspace/.tools/color-chaos bash tools/validate.sh
```

## Si algo falla

| Problema | Qué revisar |
| --- | --- |
| La terminal no encuentra `rojo` | El ejecutable debe estar en el `PATH`; vuelve a abrir la terminal después de cambiarlo. |
| El plugin no conecta | Studio y Rojo deben estar en la misma computadora; confirma que `rojo serve` sigue abierto y usa el puerto que imprime. |
| El editor parece vacío | Pulsa Play: los escenarios se generan durante la ejecución. |
| Cambié código y el mapa sigue igual | Detén Play, confirma la sincronización y vuelve a iniciar la prueba. |
| No se conserva el progreso en Studio | Esta versión desactiva el guardado en Studio; compruébalo desde el cliente de Roblox en una experiencia publicada de desarrollo. |
| Error de guardado en Output | Comprueba la configuración, el estado del servicio y los límites de DataStore; conserva la prueba separada de producción. |

Fuentes: [Rojo: instalación](https://rojo.space/docs/v7/getting-started/installation/), [Rojo: construir y sincronizar](https://rojo.space/docs/v7/getting-started/new-game/), [Roblox: pruebas en Studio](https://create.roblox.com/docs/studio/testing-modes) y [Roblox: DataStore](https://create.roblox.com/docs/cloud-services/data-stores).
