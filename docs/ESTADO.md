# Estado de Color Chaos 2: Ciudad Prisma

Reconstrucción solicitada el 15 de octubre de 2026. La dinámica actual consiste en recordar personajes 3D y elegir entre cinco puertas, avanzando por ocho sectores. Sustituye las rondas cooperativas anteriores de Color Chaos. La experiencia independiente Color Rush conserva su propia carpeta y entrega.

## Entrega

- Mundo permanente incluido en el archivo: plaza, spawn seguro, jardines, tienda, regalos, galería, podio, paneles y recorrido de ocho sectores con cuarenta puertas.
- Referencia de dos segundos, personaje con color alterado y cinco alternativas 3D con una respuesta correcta.
- Práctica desde una persona y competición de hasta veinte, con final de velocidad.
- Eliminados y jugadores tardíos esperan en lobby; pueden observar o recorrer como fantasmas sin premios por respuestas ni victorias.
- Regalo gratuito por cada cinco aciertos seguidos y regalos diarios por tiempo conectado.
- Diamantes gratuitos, monedas, XP, nivel, inventario de trajes, emotes, reacciones y estelas.
- Clasificaciones de sala y globales de victorias, mejor racha y nivel.
- Tres paquetes de monedas y VIP existentes conservados, sin vender resultados aleatorios.
- Actualizador manual que conserva Config íntegro, respalda objetos anteriores y mantiene inactivo el paquete importado.

## Comprobaciones de esta entrega

La validación integral pasó con **31 fuentes Luau compiladas y 5134 comprobaciones satisfactorias**. Estas cifras corresponden a Ciudad Prisma y no reutilizan los resultados de la versión anterior.

| Área | Comprobaciones |
| --- | ---: |
| Reglas, comercio, perfiles, economía y clasificaciones | 678 |
| Servidor y seis escenarios de integración | 131 |
| Interfaz y espectador | 77 |
| Bienvenida independiente y arranque | 17 |
| Personajes y retratos 3D | 3784 |
| Cosméticos y emotes | 383 |
| Instalador y restauración ante fallos | 64 |
| **Total** | **5134** |

Las pruebas ejecutan los módulos y scripts reales con servicios simulados. Cubren preguntas, elegibilidad, práctica, fantasmas, rachas, regalos gratuitos, compras, recibos, migración de perfiles, clasificaciones, interfaz e inicio. El instalador se verifica con geometría leída del escenario actual; conserva Config literalmente, respalda objetos, mantiene inactivo el paquete importado, restaura ante fallos y rechaza módulos, puertas o puntos de aparición incompletos.

El empaquetador genera `ColorChaos2.rbxl`, `ColorChaos2.rbxlx`, `ColorChaosUpdate.rbxm`, `ColorChaosUpdate.rbxmx` y `ColorChaos2-completo.zip`. Inspecciona el XML del lugar para verificar las 954 piezas permanentes ancladas con transformaciones CFrame explícitas, el spawn sobre el piso, ocho sectores, cuarenta puertas y fuentes no vacías. Comprueba referencias únicas, los scripts desactivados del modelo importado y la integridad CRC del ZIP. La carpeta incluye las dos ilustraciones promocionales nuevas y las guías de publicación.

## Qué se conserva al actualizar

El actualizador sustituye las cuatro carpetas administradas del juego y copia el Config completo del lugar existente. Mantiene el nombre de DataStore —por defecto `ColorChaos_Player_v1`—, las claves `Player_<UserId>` y los recibos numéricos anteriores. Los nuevos ajustes de juego usan GameSettings para no depender de valores antiguos de lava o rondas que pueda conservar Config.

La copia en ServerStorage respalda objetos locales, no datos de jugadores. El instalador no escribe DataStore, no procesa compras y no publica. Los archivos completos llevan los cuatro IDs en cero; para una experiencia ya configurada utiliza [el actualizador](ACTUALIZAR_LOBBY.md).

## Límite de verificación

Este entorno no ejecuta Roblox Studio ni la aplicación Roblox. No se han comprobado aquí física, renderizado, controles reales, publicación, consultas de DataStore de tu cuenta ni cobros reales. Las simulaciones ejecutan módulos y scripts con sustitutos de servicios y no acreditan esas operaciones.

El archivo inicial dependía del arranque del servidor para crear su piso y spawn. En el escenario posterior se encontraron posiciones guardadas mediante la propiedad derivada Position; esta entrega serializa las transformaciones CFrame nativas de todas las piezas para evitar esa ambigüedad al cargar. La reconstrucción incluye el mundo y el spawn antes de ejecutar scripts. El reporte anterior de pantalla vacía no incluía el mensaje concreto de Salida; no se puede atribuir con certeza a una excepción única sin ese registro.

El juego conserva un lobby visible ante un fallo de un sistema secundario. Si una ronda no inicia, recoge el primer error de **Salida / Output**. La descripción “no carga nada” por sí sola no distingue una importación incompleta, una versión antigua, un Config inválido o un error del servidor.
