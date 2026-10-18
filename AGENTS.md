# Color Chaos 2: Ciudad Prisma

Lee `PROJECT_NOTES.md` para las decisiones del usuario y `README.md` para el flujo de desarrollo. La comunicación con el usuario y la interfaz están en español.

Usa el checkout existente. Cada tarea en la nube ya está aislada; no crees un git worktree adicional salvo que el usuario lo pida.

El código administrado por Rojo vive en `src/`. El servidor decide participantes, respuestas físicas, monedas, regalos, propiedad y recompensas; el cliente presenta la interfaz. Cada camino tiene letra y número. Conserva código, escenarios y recursos propios o con licencia apropiada. `games/color-rush` es una entrega independiente y no forma parte de esta reconstrucción.

El lobby y spawn seguro se serializan en `scene/`; nunca dependas de DataStore o módulos de compras para crear el piso donde aparece el jugador. La dinámica actual es memorizar un personaje original 3D durante dos segundos, elegir una de cinco puertas y avanzar por ocho sectores. No hay lava. Las coordenadas y reglas acordadas están en `docs/DISENO_2.md`. El servidor valida la posición del avatar y no acepta respuestas ni premios declarados por el cliente. La final usa el mismo punto de salida para todos y gana la primera elección correcta validada.

Eliminados y jugadores tardíos esperan en lobby y pueden entrar voluntariamente como fantasmas; no obtienen aciertos, rachas, premios de racha ni victorias. Los regalos por tiempo sí funcionan. Una partida que empieza con una sola persona concede progreso gratuito, pero nunca victorias. Cada cinco aciertos consecutivos concede un regalo aleatorio gratuito; no se venden regalos aleatorios con Robux, monedas ni diamantes. Los cosméticos de la tienda tienen resultados conocidos.

El actualizador `release/Installer.luau` conserva Config completo, funciona solo con Studio detenido, mantiene modelos importados inactivos y deja copia reversible. La dinámica nueva usa `GameSettings` y `Catalog`; no depende de campos antiguos de lava de Config. Conserva `DataStoreName`, claves `Player_<UserId>`, recibos numéricos y auras existentes. Las tablas globales se actualizan con estadísticas cuyo guardado se confirmó.

Después de cambios de comportamiento, ejecuta `COLOR_CHAOS_TOOLS_DIR=/workspace/.tools/color-chaos bash tools/validate.sh`. Si faltan herramientas, instala primero con `tools/setup.sh` y la misma variable. Las pruebas de simulación no ejecutan el motor de Roblox: describe ese límite y usa el checklist de Studio antes de un lanzamiento.

La tienda admite tres productos de monedas y el pase cosmético VIP Prisma. Los cuatro IDs se configuran en `Config.Commerce`; los ceros desactivan compras sin inventar productos. Monedas y recibo se guardan juntos mediante UpdateAsync, y los guardados reconcilian recibos confirmados cuyo acuse falló. Nunca concedas productos desde eventos de cierre del diálogo ni elimines recibos persistidos. Conserva productos antiguos hasta resolver sus recibos pendientes. El guardado se desactiva en Studio; los checks simulados no acreditan cobros reales. No afirmes ingresos, disponibilidad del nombre ni pruebas reales del motor sin evidencia. Consulta `docs/PUBLICAR.md` y `docs/OPERACION.md` para activación y actualizaciones.

La entrega actual es `downloads/ColorChaos2-completo.zip`, generada con `tools/package-release.py`. Incluye el juego completo y el actualizador que conserva Config. No sobrescribas el ZIP archivado de la versión 1.1. Las imágenes nuevas son `assets/ciudad-prisma-icono.png` y `assets/ciudad-prisma-banner.png`; son ilustraciones promocionales, no capturas del motor. Entrega enlaces HTTPS de GitHub: el usuario no pudo descargar los enlaces internos del entorno.
