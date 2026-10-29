# Changelog

## 1.0.5

- Presets con nombre: pomodoro 25, jornada 45 y maratón 90. Los minutos siguen
  siendo editables; la migración desde 15/25/45 ocurre una sola vez.
- Medallas de nada: una por cada 45 minutos, con contador semanal (lunes) y
  colección histórica. 100 minutos = 2 medallas y 10 de avance.
- Copy nuevo, más seco y satírico. El manifiesto pasa a “el arte de no hacer
  nada”.
- El botón secundario de sesión y resumen ocupa el ancho completo, con la misma
  separación respecto al botón principal.
- “registro” en la cabecera de inicio es solo texto, sin borde.
- La web se rediseñó para escritorio, con presets con nombre y medallas.
- 26 tests, incluidos migración de presets y cálculo de medallas.

## 1.0.4

- Enlace a la versión web (nada.isdose.com) desde “acerca de nada!”.
- La web comparte marca, tipografías, flujo y registro con la app.
- La app sigue sin permiso de internet: el enlace abre el navegador.

## 1.0.3

- La notificación persistente ya no se congela en “quedan 46 s”: muestra la
  meta y la hora de fin, y el cronómetro nativo hace la cuenta atrás.
- Prueba de regresión del texto de la notificación.

## 1.0.2

- Chime corto de dos notas al guardar una sesión.
- Sonido también en la notificación de meta.
- Toggle de sonido y botón “probar sonido” en ajustes.
- Luz de fondo más perceptible en la pantalla de sesión.
- Botón principal más grande; en pausa queda hundido y al continuar se eleva.
- Releases versionadas automáticamente con `tool/release.ps1`.

## 1.0.1

- Widget nativo 2×2 con el total acumulado y las sesiones.
- Widget en tema negro y en tema blanco hueso.
- El widget llena la celda con tipografía más grande y el contenido distribuido.
- Luz de fondo en movimiento, muy lenta, en la pantalla de sesión.
- La pantalla en curso deja de mostrar la etiqueta “en curso”; “en pausa” solo
  aparece al pausar.
- Botón principal más grande y con estado físico: se hunde al pausar y se eleva al continuar.
- Tiempos rápidos editables con teclado y steppers.
- Selector de duración en una sola línea, sin etiqueta “meta”.
- Logo oficial, icono de Play Store y kit de tienda.
- El botón principal ahora tiene relieve de 4 px.

## 1.0.0

- Cronómetro libre y metas.
- Registro local, racha y total acumulado.
- Notificación persistente con cronómetro nativo.
- Historial, resumen, ajustes y manifiesto.
- Sin cuentas, sin nube y sin anuncios.
