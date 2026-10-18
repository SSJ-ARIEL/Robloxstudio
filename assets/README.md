# Recursos originales de Color Chaos

Para **Ciudad Prisma**, usa `ciudad-prisma-icono.png` y `ciudad-prisma-banner.png`, las nuevas ilustraciones promocionales. Sus dimensiones, procedencia y uso se describen en [CIUDAD_PRISMA_ART.md](CIUDAD_PRISMA_ART.md). No son capturas del motor. Los personajes del desafío se construyen en 3D dentro del juego y no necesitan subir imágenes al Dashboard.

Los recursos vectoriales de la tabla siguiente pertenecen a la primera versión; los cuatro iconos de productos se mantienen para las mismas compras. `logo.png` y `banner.png` se conservan como archivo del diseño anterior.

Estos recursos antiguos se crearon para este proyecto mediante geometría vectorial propia.
No contienen personajes, logotipos, imágenes ni archivos descargados de otros
juegos. Las letras también se dibujan mediante trazos definidos en el proyecto.
El concepto gráfico no certifica la exclusividad del nombre «Color Chaos».

| Archivo PNG | Tamaño | Uso |
| --- | --- | --- |
| `logo.png` | 512 × 512 | Icono de la experiencia |
| `vip-prisma.png` | 512 × 512 | Imagen del pase VIP Prisma |
| `coins100.png` | 512 × 512 | Imagen del producto de 100 monedas |
| `coins400.png` | 512 × 512 | Imagen del producto de 400 monedas |
| `coins1000.png` | 512 × 512 | Imagen del producto de 1000 monedas |
| `banner.png` | 1920 × 1080 | Miniatura promocional ilustrada |

Los archivos `.svg` son las fuentes editables de cada PNG. El banner es una
ilustración del reactor y no una captura del juego; no representa contenido,
premios o compras adicionales. Los iconos de monedas representan moneda interna
del juego, no Robux ni dinero real. Los beneficios y cantidades se explican en las
descripciones de sus productos y deben coincidir con la configuración del juego.

Los autores de este proyecto conceden permiso para usar, modificar y distribuir
estos recursos con Color Chaos, incluidos sus anuncios e imágenes en Roblox.
Este permiso se refiere a estos archivos originales; no autoriza usar recursos de
terceros ni afirma derechos exclusivos sobre mecánicas, palabras o colores.

Para regenerar únicamente los archivos vectoriales antiguos, si se dispone de Python y Pillow:

```sh
python tools/make-icons.py
```

Este generador es opcional y no interviene en el juego, Rojo ni Roblox Studio.
