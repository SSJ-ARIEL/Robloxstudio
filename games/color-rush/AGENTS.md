# Color Rush

Esta carpeta contiene el segundo juego, independiente de Color Chaos. Lee README.md y docs/PUBLICAR.md. No reemplaces el proyecto Rojo ni el archivo de Studio del juego anterior.

Reglas acordadas: 250 personajes propios, vista original de dos segundos, cinco caminos y una respuesta exacta. Cruzar una puerta confirma la elección. En la final gana la primera llegada correcta validada por el servidor. Una reentrada como máximo por partida, incluida la final; jamás revocar un ganador anunciado ni consumir créditos fuera de una etapa válida. Si todos fallan, la repetición gratuita no consume créditos reservados.

Los personajes se generan como modelos y retratos locales originales. Los PNG de assets/ son arte promocional generado, no capturas. Conserva los originales y usa image_gen para cambios de imagen solicitados por el usuario.

Los precios recomendados están en Config y docs/MONETIZACION.md; el importe real se consulta a Roblox y se confirma en su ventana nativa. Los cinco ProductId y el PassId son propios de esta experiencia. No reutilices IDs, DataStoreName ni nombres de servicios del primer juego. Nunca otorgues productos desde el cierre de una ventana: usa recibos atómicos y conserva su historial.

Ejecuta bash tools/validate.sh desde esta carpeta después de cambios de comportamiento. Las herramientas existentes están en /workspace/.tools/color-chaos. La simulación no acredita física, renderizado ni facturación reales. Al entregar una versión, genera build/ColorRush.rbxlx y actualiza explícitamente downloads/ColorRush.rbxlx.

Usa el checkout existente: el entorno ya está aislado y no requiere otro Git worktree. Comunica en español y conserva este alcance como memoria para próximas tareas.
