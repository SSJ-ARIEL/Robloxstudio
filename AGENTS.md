# Color Chaos

Lee `PROJECT_NOTES.md` para las decisiones del usuario y `README.md` para el flujo de desarrollo. La comunicación con el usuario y la interfaz están en español.

Usa el checkout existente. Cada tarea en la nube ya está aislada; no crees un git worktree adicional salvo que el usuario lo pida.

El código administrado por Rojo vive en `src/`. El servidor decide objetivos, monedas, propiedad de auras y recompensas; el cliente presenta la interfaz. Mantén el nombre acompañado de letras en las indicaciones de color. Conserva código, escenarios y recursos propios o con licencia apropiada.

Después de cambios de comportamiento, ejecuta `COLOR_CHAOS_TOOLS_DIR=/workspace/.tools/color-chaos bash tools/validate.sh`. Si faltan herramientas, instala primero con `tools/setup.sh` y la misma variable. Las pruebas de simulación no ejecutan el motor de Roblox: describe ese límite y usa el checklist de Studio antes de un lanzamiento.

La tienda admite tres productos de monedas y el pase cosmético VIP Prisma. Los cuatro IDs se configuran en `Config.Commerce`; los ceros desactivan compras sin inventar productos. Monedas y recibo se guardan juntos mediante UpdateAsync, y los guardados reconcilian recibos confirmados cuyo acuse falló. Nunca concedas productos desde eventos de cierre del diálogo ni elimines recibos persistidos. Conserva productos antiguos hasta resolver sus recibos pendientes. El guardado se desactiva en Studio; los checks simulados no acreditan cobros reales. No afirmes ingresos, disponibilidad del nombre ni pruebas reales del motor sin evidencia. Consulta `docs/PUBLICAR.md` y `docs/OPERACION.md` para activación y actualizaciones.
