# Estado de Color Chaos 1.1.0

Fecha: 15 de octubre de 2026. Actualización del primer juego con lobby permanente, lava y elevación cooperativa. Color Rush conserva su entrega independiente.

## Cambios

- Piso, spawn neutral, tienda, carteles, escaleras y mirador guardados dentro del archivo antes de ejecutar scripts.
- Inicio con una persona; los tres desafíos y sus recompensas se conservan.
- Lava ascendente durante el juego; cada avance nuevo eleva plataformas y jugadores. Repetir pasos de memoria no permite ganar altura extra.
- Preparación con el avatar quieto, retorno seguro al caer, espera en lobby y cámara opcional de espectador.
- La lava queda fuera del mirador; detección de pies compatible con R6 y R15.
- Fallar al obtener DataStore no impide comenzar rondas gratuitas; los paquetes de monedas permanecen bloqueados sin guardado fiable.
- Bienvenida independiente del servidor y aviso de espera si la partida no consigue iniciar.
- Modelo de actualización manual que conserva Config completo, los cuatro IDs, el almacén de progreso y una copia local de los objetos anteriores.

## Verificado en esta nube

Compilación de **17 fuentes Luau** y **396 comprobaciones satisfactorias**:

| Comprobaciones | Cantidad |
| --- | ---: |
| Reglas | 20 |
| Misiones | 29 |
| Registro de recibos | 25 |
| Comercio | 91 |
| Servidor y escena, siete escenarios | 106 |
| Interfaz y cámara | 53 |
| Bienvenida e inicio tardío | 16 |
| Instalador y restauración ante fallos | 56 |

Las simulaciones ejecutan los cuerpos reales de los scripts y módulos con servicios limitados. Cubren los tres desafíos, entrada tardía, caídas durante preparación/juego, respawn sin reingreso, elevación y reinicio de lava, guardado inaccesible, compatibilidad con Config antiguo y compras duplicadas. El instalador conserva la configuración, mantiene copias e importaciones inactivas y repone objetos originales ante un fallo simulado. Después de instalar, retira el paquete de Workspace para evitar geometría y puntos de aparición duplicados.

Rojo construye la experiencia en `.rbxl` y `.rbxlx`, el actualizador en `.rbxm` y `.rbxmx`, y una carpeta ZIP de Color Chaos. El XML del actualizador se inspecciona para confirmar que los tres scripts ejecutables están desactivados al importar. El ZIP se comprueba por integridad.

## Aplicación a tu juego

Usa [ACTUALIZAR_LOBBY.md](ACTUALIZAR_LOBBY.md) sobre **la experiencia Color Chaos existente**. El Config de esa experiencia se conserva automáticamente. Los archivos completos llevan IDs de plantilla en cero; para un juego ya configurado, utiliza el modelo de actualización.

Publica desde tu cuenta y entra en un servidor nuevo. Los servidores que ya estaban abiertos pueden seguir con el contenido anterior hasta que finalicen o los reinicies desde el Dashboard. El instalador no modifica DataStore ni publica por ti.

## Límite de verificación

La entrega anterior no incluía piso ni spawn en el archivo: dependía del arranque del servidor. Este riesgo está corregido. Sin el mensaje de Salida del juego publicado no se ha identificado la excepción exacta que causó el reporte del usuario.

Este entorno no ejecuta Roblox Studio ni el cliente de Roblox. No se han verificado aquí física, renderizado, controles reales, publicación, servicios de DataStore ni facturación real. Los checks de simulación no acreditan esas operaciones.
