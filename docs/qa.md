# QA manual — nada! 1.0

Emulador: Pixel 8 (`sdk gphone16k`, Android 16 / API 36), APK de **release**.

## Flujos verificados

| Flujo | Resultado |
|---|---|
| Arranque en frío | Splash negro, wordmark de arranque y home sin pantalla en blanco. |
| Marca | `nada!` con exclamación en wordmark, héroe, label de Android, notificación e icono. |
| Legibilidad | Etiquetas de 16 px como mínimo, cuerpo de 18–21 px, acciones de 19 px y contraste subido. |
| Pantalla principal | Pregunta “¿cuánto tiempo?”, separa “sin límite” de “meta”, explica el modo y deja el CTA fijo abajo. |
| Acciones secundarias | Registro, volver, cerrar, ajustes, manifiesto, copiar, borrar y cerrar hojas son botones cuadrados con borde, no enlaces subrayados. |
| Selector de duración | Texto con subrayado, sin caja. `sin límite` y las metas comparten una sola línea, sin etiqueta “meta”. |
| Inicio de sesión libre | Un toque, cronómetro visible, notificación persistente con cronómetro nativo. |
| Notificación en segundo plano | Sigue visible en la sección Silencio, `ongoing`, con cronómetro que avanza solo. |
| Pausa | El cronómetro se congela, la notificación desaparece, el estado dice "en pausa". |
| Reanudar | El tiempo continúa desde el acumulado, no desde cero. |
| Muerte de proceso | Force-stop con sesión activa; al relanzar, el tiempo incluye los segundos en que la app estuvo muerta. |
| Finalizar | La sesión se guarda con duración, inicio y fin; el resumen muestra el total actualizado. |
| Meta cumplida | El modo meta cierra la sesión exactamente en la meta, no en el momento de volver. |
| Registro | Total, sesiones, racha, fecha de inicio, agrupación por día y detalle por sesión. |
| Borrar sesión | Confirmación, actualización del total y del estado vacío. |
| Copiar resumen | Copia un texto plano con total, sesiones y racha. |
| Ajustes | Tres tiempos rápidos editables con teclado y steppers, toggle de notificación, enlaces y versión. |
| Persistencia de ajustes | Al cambiar un tiempo, se guarda al instante y la pantalla principal muestra el nuevo valor. |
| Relieve del CTA | El botón sólido se hunde 2 px y reduce su sombra dura al pulsarlo. |
| Widget 2×2 | Se añade desde ajustes o desde el selector de widgets; muestra el total y el número de sesiones. |
| Tema del widget | Negro con letras hueso y blanco hueso con letras negras; cambia al instante desde ajustes. |
| Permiso de notificaciones | Solicitud en el primer inicio de sesión; si se niega, la app sigue funcionando. |
| Arranque sin red | La app no declara `INTERNET`; todo funciona offline. |
| Rutas empujadas | Registro y manifiesto sin el texto amarillo de fallback (Material propio). |
| Tipografía | Instrument Serif + Crimson Text empaquetadas; sin descargas en runtime. |

## Pendiente de probar en dispositivo físico

- Notificación con cronómetro en fabricantes con optimizaciones agresivas
  (Xiaomi, Huawei, Samsung): el aviso de meta usa alarmas inexactas.
- Permiso de notificaciones en Android 12 y anteriores (no existe el prompt).
- Rotación: la app está bloqueada en retrato.
- Escalado de texto del sistema al 130 % en pantallas pequeñas.

## Notas de build

- `compileSdk = 37`, AGP 9.1.1, desugaring activo por
  `flutter_local_notifications` 22.
- El APK de release usa la firma de debug para pruebas locales; para Play se
  debe configurar un keystore propio.
- El ícono de notificación (`drawable/ic_nada`) se conserva con
  `NOTIFICATION_ICON` en el manifiesto y `res/raw/keep.xml`.
