# Proyecto Roblox

## Objetivo y forma de trabajo

El usuario quiere crear experiencias de Roblox y monetizarlas. El asistente prepara diseño y código; el usuario inspecciona, prueba en Roblox Studio y publica mediante su cuenta. Se propone GitHub para versionar y Rojo para sincronizar archivos con Studio. Aún no se ha instalado ni validado Rojo ni elegido el juego final.

El usuario solicita investigar preferencias antes de elegir. Menciona un juego popular llamado aproximadamente «adivina el color»; falta su enlace para identificarlo. El chat compartido anterior no pudo leerse (HTTP 403), por lo que estas notas solo recogen esta conversación.

## Investigación consultada: 2026-10-11

Fuentes oficiales leídas desde sus repositorios GitHub:

- https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/game-design/design-for-roblox.md
- https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/index.md
- https://github.com/rojo-rbx/rojo

Roblox recomienda llegar pronto a la diversión, interacción entre amigos, interfaces visuales y diseño para móviles. Su documentación describe exploración, experimentación y socialización como intereses de públicos jóvenes; también señala oportunidades entre usuarios mayores. La personalización visible permite expresar identidad. Recomienda actualizaciones frecuentes y compras transparentes, sin garantizar ingresos.

Estas son recomendaciones de diseño, no una encuesta propia ni evidencia de popularidad actual. Los rankings y APIs de Roblox no pudieron consultarse porque la red respondió 403. Se guardó un borrador de permisos de red para www.roblox.com, apis.roblox.com, games.roblox.com, create.roblox.com, corp.roblox.com y rojo.space; guardarlo no aplica ni publica los permisos.

## Propuestas pendientes de validar

1. Color Chaos: rondas cortas de supervivencia en plataformas de colores; variantes de memoria y equipos, colores acompañados de símbolos; monetización con efectos, gestos y servidores privados.
2. Laboratorio de criaturas: amigos combinan ingredientes, descubren criaturas y decoran su laboratorio; recetas deterministas y colección obtenida jugando; monetización con decoración y aspectos.
3. Hotel de desastres: cooperar en un hotel con eventos absurdos y rescates; salas variables y decoración de habitaciones; monetización con cosméticos y servidores privados.

Recomendación provisional: prototipo pequeño de Color Chaos, sujeto a investigación de competidores y pruebas con jugadores. Ninguna propuesta tiene popularidad o ingresos demostrados. No se ha decidido implementar ninguna.

## Próximos pasos

Identificar el juego de colores, consultar competidores cuando haya acceso y registrar cifras con fecha y hora. Validar diversión, comprensión, rendimiento móvil y retorno de jugadores antes de ampliar la tienda. Configurar GitHub/Rojo después de decidir el prototipo. Usar el checkout existente: el entorno ya está aislado y no requiere un worktree nuevo.

## Decisión e implementación de esta sesión

El usuario eligió Color Chaos y autorizó implementar el juego, solicitando una entrega completa con instrucciones para GitHub, Rojo y Roblox Studio. El concepto seleccionado utiliza colores y letras para reparar un reactor cooperativamente; no consiste en copiar un mapa, personajes ni código de otro juego.

Se implementó una primera versión con mapa generado, vestíbulo, tres desafíos (secuencia de puentes, estaciones de reparación y rescate de chispas), interfaz para distintos dispositivos, monedas y victorias, auras cosméticas obtenidas jugando y persistencia de servidor con bloqueo de sesión. Las compras con Robux están desactivadas hasta disponer de productos reales y probar recibos; no existe garantía de ingresos.

Rojo 7.6.1 y Luau 0.694 están disponibles con instalación verificada y repetible. La compilación y las pruebas de reglas se pueden ejecutar en Linux; el motor, los controles y la persistencia publicada deben validarse en Studio y Roblox. Consultar README.md para la entrega y los pasos. No afirmar que existe validación real multijugador, que el nombre está libre ni que es un lanzamiento comercial validado.
