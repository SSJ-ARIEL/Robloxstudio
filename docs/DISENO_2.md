# Color Chaos 2 — Ciudad Prisma

Reconstrucción autorizada el 15 de octubre de 2026. Sustituye las rondas cooperativas con lava por la carrera de cinco puertas solicitada por el usuario. Se mantiene la identidad de la primera experiencia para conservar productos y progreso. El juego independiente `games/color-rush` permanece archivado como entrega separada.

## Acuerdo

Personajes originales 3D (250), referencia correcta durante dos segundos, después personaje con color alterado y cinco imágenes 3D con alternativas. Una alternativa es correcta. Elegir físicamente un camino confirma la respuesta. La puerta correcta se abre y los supervivientes avanzan físicamente al siguiente sector. El recorrido tiene ocho etapas. Final de velocidad cuando quedan dos competidores a partir de la tercera etapa, o en la última etapa. Si queda un solo competidor gana; una partida que comenzó con una persona es práctica y no concede victorias.

Los eliminados regresan al lobby. Pueden observar o entrar voluntariamente como fantasmas, igual que quienes llegan tarde. Los fantasmas ven el mismo reto y pueden recorrer y elegir, sin obtener aciertos, rachas, regalos de racha ni victorias. Sus regalos por tiempo siguen disponibles. No bloquean a competidores ni abren puertas de la partida.

Cada cinco aciertos consecutivos de un jugador elegible se concede un regalo gratuito aleatorio. Fallar reinicia la racha. Ganar conserva la racha para la siguiente partida; abandonar una partida activa la reinicia. La práctica individual permite ganar progreso gratuito, pero no victorias. Cosméticos y monedas pagados no compran regalos aleatorios ni respuestas. Se conservan las cantidades de los tres productos de monedas y el pase VIP ya existentes.

## Mundo y coordenadas compartidas

`Workspace.ColorChaosWorld` es permanente, visible en Studio sin scripts. LobbySpawn `(0,8,110)` sobre Plaza del reactor centrada en `(0,4,120)` de tamaño `(164,4,140)`. El terreno del lobby llega hasta z=50; un paseo conecta al inicio del recorrido. Punto del avatar en lobby `(0,11,110)`.

Ocho sectores: `Stages.Stage01` hasta `Stage08`. Para etapa i: `StartZ=-40-(i-1)*112`; `GateZ=StartZ-48`; `EndZ=StartZ-82`; centro de suelo `(0,4,StartZ-40)` tamaño `(120,4,112)`, superficie y=6. Avatar y=10. Cinco carriles x=-40,-20,0,20,40. Cada `Gates.Gate1..Gate5` es un Model con `Barrier` (16x16x2 a y=14,z=GateZ), `ChoicePad` (16x0.2x12 a y=6.15,z=GateZ+10) y `PortraitAnchor` invisible (1x1x1 a y=24,z=GateZ). La elección se valida con el HumanoidRootPart en el rectángulo del ChoicePad, y=7..20; sin aceptar índices del cliente. Referencia `Stages.StageXX.ReferenceAnchor` a `(0,31,StartZ-25)`. Los modelos se dibujan en ViewportFrames para una referencia y cinco alternativas, en UI y carteles del mundo. Pasillos laterales de fantasma con acceso desde UI; colisiones separadas de participantes/puertas.

Lobby con plaza original de islas flotantes, jardines, galería, tienda, regalos, podio, dos paneles de clasificación y teletransportador de fantasmas. Sin lava. Geometría propia; no se copian personajes, mapas ni interfaces ajenos.

## Arquitectura

Config existente sigue siendo la fuente de Commerce, DataStoreName y ajustes de persistencia antiguos. `GameSettings` y `Catalog` contienen los ajustes nuevos para que el instalador pueda conservar Config íntegro. Módulos compartidos: Characters, Portrait, GameRules, Economy, Catalog, GameSettings, ProfileLedger y módulos antiguos de compatibilidad. Servidor: Main, Profiles, Leaderboards, Cosmetics y Commerce existente. Cliente: Main y Bootstrap independiente.

El servidor controla respuestas, colisiones, regalos, tiempo, guardado, rachas y clasificaciones. No se muestra una respuesta correcta antes de resolver salvo la vista inicial intencional de dos segundos. No se envían premios ni cantidades desde el cliente. Los resultados de pruebas automatizadas no acreditan motor, controles ni facturación de Roblox.
