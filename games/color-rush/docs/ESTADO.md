# Estado de la entrega de Color Rush

Documento de la entrega del segundo juego. Verificado en la instancia actual: compilación de 18 fuentes Luau, generación del lugar con Rojo 7.6.1 y 3834 comprobaciones satisfactorias. Son comprobaciones de código y valores simulados, no pruebas del motor.

## Alcance

- Catálogo de 250 personajes originales generado desde 25 arquetipos y 10 variantes estructurales.
- Muestra de 2 segundos, cinco opciones y elección física en una carrera.
- Capacidad de 20 jugadores, inicio con 2 y hasta siete etapas normales antes de la carrera final.
- Final y desempate por primera llegada válida a la respuesta correcta.
- Créditos de reentrada guardados, con límite de una reentrada total por partida, incluida la final.
- Monedas, cosméticos y pase VIP de título más estela exclusiva.
- Cinco productos repetibles y un pase, sin IDs inventados.
- Recursos PNG originales y documentos de apertura, activación, precios y actualización.

## Activación en tu cuenta

Roblox genera los cinco ProductId y el PassId. Debes crear esos productos para la nueva experiencia de Color Rush, elegir precios, colocar los seis números en Config y publicar. La guía está en [PUBLICAR.md](PUBLICAR.md).

No se piden contraseñas, cookies ni tokens. Los IDs públicos de productos son suficientes para configurar el código. Los ceros mantienen sin activar los productos que todavía no existen.

## Límites reales

Esta nube no ejecuta Roblox Studio ni el cliente de Roblox. No confirma renderizado, física, controles reales, latencia, servicios de producción, aprobaciones de contenido ni cobros de tu cuenta. Las simulaciones y la generación del `.rbxlx` verifican aspectos del código y del paquete, no sustituyen esas operaciones del motor.

El nombre es provisional y su disponibilidad no está comprobada. Los personajes y recursos se crearon para este juego; no se afirma exclusividad de todas sus mecánicas generales ni se garantizan ingresos.

Color Chaos se conserva. El segundo juego se publica como experiencia propia desde **games/color-rush/downloads/ColorRush.rbxlx**. Si aparece un problema, se corrige y se publica una actualización de ese mismo lugar: [OPERACION.md](OPERACION.md).

## Evidencia automatizada de esta entrega

| Área | Comprobaciones satisfactorias |
| --- | ---: |
| Catálogo de personajes | 11 |
| Opciones, eliminación y reentrada | 22 |
| Historial atómico de recibos | 35 |
| Perfiles, créditos y guardado | 51 |
| Tienda y VIP | 104 |
| Servidor: cinco partidas y casos de cierre | 42 |
| Interfaz y entrenamiento gratuito | 42 |
| Construcción, recoloreado y montaje de 250 retratos | 3527 |
| **Total** | **3834** |

La simulación de retratos ejecuta el constructor original para todos los personajes, oculta y cambia el color objetivo y verifica limpieza de modelos/cámaras. No genera una captura ni comprueba cómo se proyecta en una pantalla real. El servidor verifica un ganador único, los dos segundos de muestra, reentradas normales/finales, crédito después de cierre, cuerpos muertos y repetición gratis. Los recibos simulados verifican recuperación después de una respuesta perdida.

El archivo de Studio contiene únicamente este juego. La nueva instalación de herramientas se ejecutó con verificación SHA-256 y los helpers funcionan desde la carpeta autónoma.
