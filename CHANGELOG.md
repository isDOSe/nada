# Changelog

Desde 1.0.5 la app y la web comparten número de versión. Lo más reciente va
arriba. El resumen del día a día vive también en el `## Changelog` del
[`README.md`](README.md).

## 1.0.5 — 2026-10-28

### app

- Presets con nombre: **pomodoro 25**, **jornada 45** y **maratón 90**. Los
  minutos siguen siendo editables; la migración desde 15/25/45 ocurre una sola
  vez.
- **Medallas de nada:** una por cada 45 minutos, con contador semanal (lunes) y
  colección histórica. 100 minutos = 2 medallas y 10 de avance.
- Copy nuevo, más seco y satírico. El manifiesto pasa a “el arte de no hacer
  nada”.
- El botón secundario de sesión y resumen ocupa el ancho completo, con la misma
  separación respecto al botón principal.
- “registro” en la cabecera de inicio es solo texto, sin borde.
- 26 tests, incluidos migración de presets y cálculo de medallas.

### web

- Reconstrucción de la web como app de uso diario: temporizador al abrir y
  navegación clara entre Temporizador, Registro y la explicación.
- Historial agrupado, detalles y borrado de sesiones, resumen copiable,
  medallas, presets editables, sonido y contenido explicativo.
- Source Serif 4 para lectura de interfaz, empaquetada localmente junto a
  Instrument Serif. Sin fuentes remotas ni frameworks.
- En móvil, el inicio reúne selector, botón, total y medallas en la primera
  pantalla; durante la sesión, reloj, progreso y controles caben sin scroll.
- Diseño responsive, foco de teclado y movimiento reducido respetado.

### repositorio

- La app de Android y la web pasan a vivir en el mismo repositorio: `app/` y
  `web/`. Un solo `README.md`, un solo `CHANGELOG.md` y una sola licencia.

## 1.0.4 — 2026-10-26

- Enlace a la versión web (nada.isdose.com) desde “acerca de nada!”.
- La web comparte marca, tipografías, flujo y registro con la app.
- La app sigue sin permiso de internet: el enlace abre el navegador.
- Reescritura completa de la web para que sea la versión web de la app 1.0.4.
- Persistencia de la sesión activa y recuperación por marca de tiempo.
- Chime de dos notas con Web Audio y ajuste de sonido en la web.

## 1.0.3 — 2026-10-26

- La notificación persistente ya no se congela en “quedan 46 s”: muestra la
  meta y la hora de fin, y el cronómetro nativo hace la cuenta atrás.
- Prueba de regresión del texto de la notificación.

## 1.0.2 — 2026-10-25

- Chime corto de dos notas al guardar una sesión.
- Sonido también en la notificación de meta.
- Toggle de sonido y botón “probar sonido” en ajustes.
- Luz de fondo más perceptible en la pantalla de sesión.
- Botón principal más grande; en pausa queda hundido y al continuar se eleva.
- Releases versionadas automáticamente con `app/tool/release.ps1`.

## 1.0.1 — 2026-10-24

- Widget nativo 2×2 con el total acumulado y las sesiones.
- Widget en tema negro y en tema blanco hueso.
- Luz de fondo en movimiento, muy lenta, en la pantalla de sesión.
- La pantalla en curso deja de mostrar la etiqueta “en curso”.
- Tiempos rápidos editables con teclado y steppers.
- Selector de duración en una sola línea, sin etiqueta “meta”.
- Logo oficial, icono de Play Store y kit de tienda.
- El botón principal ahora tiene relieve de 4 px.

## 1.0.0 — 2026-10-24

- Cronómetro libre y metas.
- Registro local, racha y total acumulado.
- Notificación persistente con cronómetro nativo.
- Historial, resumen, ajustes y manifiesto.
- Sin cuentas, sin nube y sin anuncios.
