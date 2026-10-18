# Ciudad Prisma — escenario permanente de Color Chaos 2

Mundo original de islas flotantes, piedra clara, jardines, cristal y metal. El archivo `color-chaos-world.project.json` contiene la plaza, la galería de criaturas, la tienda, regalos, podio, paneles y ocho sectores consecutivos. Rojo lo incluye en `Workspace.ColorChaosWorld`. Los pisos, las cuarenta puertas y el spawn existen antes de ejecutar scripts; no dependen de DataStore, comercio, imágenes, modelos descargados o plugins.

La plaza usa una superficie marfil con roseta central, jardines elevados y cinco pequeñas criaturas esculpidas con geometría propia. El recorrido cambia de ambiente entre jardín del cielo, terrazas coral, puerto de nubes, bosque de cristal, órbita dorada, jardín lunar, galería aurora y observatorio. No contiene lava ni escenarios de las versiones anteriores.

## Contrato del servidor

| Objeto en `ColorChaosWorld` | Centro en studs | Uso |
| --- | --- | --- |
| `Plaza del reactor` | `(0, 4, 120)` | Piso de `164 × 4 × 140`, superficie a y=6; nombre conservado por compatibilidad. |
| `SceneSpawnFloor` | `(0, -7, 120)` | Plataforma de respaldo de `184 × 6 × 160` bajo el lobby. |
| `LobbySpawn` | `(0, 8, 110)` | Spawn neutral habilitado, invisible y sin colisión. El suelo está dos studs por debajo. |
| `GlobalBoard` | `(-48, 18, 171)` | BasePart del panel global. |
| `RoomBoard` | `(48, 18, 171)` | BasePart del panel de sala. |
| `GiftStand` | `(-52, 8, 110)` | BasePart para el prompt de regalos gratuitos. |
| `ShopStand` | `(52, 8, 110)` | BasePart para el prompt de tienda. |
| `GhostPortal` | `(57, 14, 73)` | BasePart transparente sin colisión para el prompt de modo fantasma. |
| `Instrucciones` | `(-47, 15, 73)` | Ancla de las reglas permanentes. |
| `Título` | `(0, 28, 48)` | Ancla de la entrada al recorrido. |

`Stages` contiene ocho modelos llamados `Stage01` a `Stage08`. Para la etapa i:

- `StartZ = -40 - (i - 1) * 112`.
- `Floor` tiene centro `(0, 4, StartZ - 40)` y tamaño `120 × 4 × 112`, superficie a y=6.
- `ReferenceAnchor` está en `(0, 31, StartZ - 25)`, invisible y sin colisión.
- `Gates.Gate1` a `Gate5` son modelos con centros x `-40, -20, 0, 20, 40`.
- Cada `Barrier` mide `16 × 16 × 2` y está en `(x, 14, StartZ - 48)`. Puede elevarse veinte studs sin dejar obstáculos bajo el dintel, situado a y=26.7.
- Cada `ChoicePad` mide `16 × 0.2 × 12` y está en `(x, 6.15, StartZ - 38)`.
- Cada `PortraitAnchor` está en `(x, 24, StartZ - 48)`, invisible y sin colisión.
- Los carriles se identifican A/1, B/2, C/3, D/4 y E/5. Sus colores decorativos no codifican la respuesta; las imágenes dinámicas muestran las alternativas.
- `GhostWalk-1` y `GhostWalk1` son pasillos continuos con centros x=-70 y x=70, ambos con suelo a y=6. Las colisiones y el acceso de los fantasmas los decide el servidor.

Los sectores comparten sus bordes: el último stud de un piso coincide con el primero del siguiente. El paseo entre z=-25 y z=51 une la plaza, que empieza en z=50, con el primer sector, que empieza en z=-24. Los muros laterales y divisores tienen 22 studs de altura sobre el piso y cierran los huecos a ambos lados de las puertas. La validación de una elección sigue siendo responsabilidad del servidor.

Todos los carteles estáticos se llaman `StaticSign`; se pueden conservar o sustituir al montar interfaces dinámicas. Los paneles global y de sala contienen un texto de espera legible incluso sin servidor. Los retratos dinámicos se añaden a las anclas vacías; no se incluye una alternativa correcta fija en la geometría.

## Edición y verificación

```sh
python3 tools/generate-scene.py
/workspace/.tools/color-chaos/rojo build default.project.json --output build/ColorChaos.rbxlx
```

La escena contiene 954 piezas ancladas. El generador es determinista y limita el presupuesto a 1050 piezas. El archivo generado es la fuente que Rojo abre; el usuario no necesita ejecutar Python. La compilación comprueba la serialización. La apariencia, cámara, colisiones y movimiento se deben observar dentro del motor de Roblox Studio antes de afirmar que fueron verificados.

Todas las piezas guardan su ubicación y rotación mediante `CFrame` explícito. El XML construido debe contener `CoordinateFrame`, con coordenadas y matriz de rotación; no se depende de las propiedades derivadas `Position` u `Orientation` para recuperar el mundo al abrir el archivo.
