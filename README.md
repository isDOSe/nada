# nada!

> la app para hacer... nada. o algo. depende.

**nada!** es un contador para hacer algo productivo o no. Eliges un tiempo,
inicias y el registro se acumula. Sin cuentas, sin nube y sin nadie mirando.

No es una app de productividad. Es una app de presencia. La productividad es tu
problema.

**Web:** [nada.isdose.com](https://nada.isdose.com)
**App de Android:** [github.com/isDOSe/nada-flutter](https://github.com/isDOSe/nada-flutter)

---

## Qué hace

- **Cronómetro libre.** Empieza en cero y cuenta hacia arriba. Tú decides
  cuándo parar de no hacer nada.
- **Pomodoro, jornada y maratón.** Tres presets con nombre y minutos editables:
  25, 45 y 90 por defecto. El nombre no cambia; los minutos sí.
- **Un registro real.** Cada sesión se guarda con duración, hora de inicio,
  hora de fin y modalidad. Vive en tu navegador y sobrevive a un recargado.
- **El total de tu vida.** Cuánto tiempo llevas sin hacer nada, cuántas
  sesiones, racha de días y detalle agrupado por día.
- **Medallas.** Una por cada 45 minutos de nada. La semana empieza el lunes y
  las que ya ganaste se quedan en tu colección.
- **Pausa física.** El cronómetro se congela, la luz de fondo se detiene y el
  botón principal se hunde hasta que continúas.
- **Sonido al terminar.** Un chime corto de dos notas, generado con Web Audio.
  Se puede desactivar en ajustes o probar desde ahí.
- **Una interfaz de app, no una página promocional.** El temporizador abre
  directamente; Registro y Ajustes están siempre a mano.
- **La misma voz que la app.** Misma paleta, serif editorial y humor seco. La
  app y la web se leen como el mismo producto.

## Capturas

Las capturas de la app viven en
[`nada-flutter/docs/screenshots`](https://github.com/isDOSe/nada-flutter/tree/main/docs/screenshots).
La web mantiene el carácter editorial, con un flujo de temporizador directo y
un registro fácil de encontrar.

## Cómo se ve

La web conserva la voz y el negro/hueso de nada!, pero prioriza el uso diario:
el selector de tiempo y el botón de inicio forman un solo flujo; el total, las
medallas y los accesos al registro quedan juntos en una columna lateral en
escritorio y pasan debajo en móvil.

| Decisión | Por qué |
|---|---|
| Negro puro `#000000` | El vacío no es gris corporativo. En OLED, el fondo desaparece. |
| Hueso `#F2EFE6` | Un blanco cálido, de tinta y papel. |
| **Source Serif 4** | Serif diseñada para lectura en pantalla, usada en controles y texto corrido. Se sirve localmente; la app no llama a Google Fonts. |
| **Instrument Serif** | La voz editorial de los titulares y el reloj. |
| Sin radios, sin sombras suaves, sin gradientes de relleno | La jerarquía se construye con tipografía, espacio y líneas de 1 px. |
| Un CTA principal | El botón claro inicia; pausar, terminar y volver son acciones secundarias claramente diferenciadas. |
| Opciones con nombre y minutos | Sin límite, pomodoro, jornada y maratón muestran lo que ocurrirá antes de iniciar. |
| Navegación persistente | Temporizador, Registro y Ajustes están visibles y no hay que volver a una landing. |
| Movimiento reducido | La luz de sesión es tenue, se detiene al pausar y respeta `prefers-reduced-motion`. |
| Cero emojis, cero mayúsculas gritadas | El humor está en el copy, no en un icono. |
| Cero red | Las fuentes y las imágenes se sirven desde el proyecto; no hay analytics, ni cuentas, ni llamadas a terceros. |

El cronómetro usa ranuras de ancho fijo para que los dígitos no tiemblen al
cambiar de segundo. El tiempo se calcula con marcas de tiempo, no restando un
segundo por tick: una pestaña dormida o un recargado no alteran el total.

## Cómo correrla

No hay build ni dependencias. Abre `index.html` en el navegador o sirve el
directorio:

```bash
python -m http.server 8080
```

Luego visita `http://localhost:8080`. El servidor local es recomendable para
que el portapapeles funcione en todos los navegadores.

## Estructura

```
nada/
├── index.html        # vistas, diálogos y contenido
├── style.css         # el sistema visual completo
├── script.js         # estado, cronómetro, registro y persistencia
├── fonts/            # Instrument Serif + Source Serif 4 (SIL OFL)
├── images/           # icono, wordmark y Open Graph
└── README.md
```

No hay frameworks, bundler, `node_modules` ni paso de compilación. Es HTML,
CSS y JavaScript del navegador.

## Cómo se guarda

Todo vive en `localStorage` bajo la clave `nada.web.v1`:

- `sessions`: lista de sesiones terminadas.
- `active`: sesión en curso, con `startedAt`, `lastResumedAt` y `accumulatedMs`.
- `settings`: los tres presets, el modo, la meta y el sonido.

El cronómetro se apoya en marcas de tiempo. Si cierras la pestaña con una
sesión corriendo, al volver se calcula el tiempo real transcurrido. Si la meta
se cumplió mientras estabas fuera, la sesión se cierra exactamente en la meta,
no cuando vuelves.

Nada sale de tu navegador. No hay cuentas, analytics ni peticiones de red.

## Diferencias con la app

La app de Android añade lo que el navegador no puede prometer: notificación
persistente con cronómetro nativo, widget 2×2 en la pantalla de inicio y aviso
de meta en segundo plano. El contador, el registro, los ajustes y la voz son
los mismos.

## Changelog

### 2026-10-28

- Reconstrucción de la web como app de uso diario: temporizador al abrir y
  navegación clara entre Temporizador, Registro y explicación.
- Flujo de inicio simplificado; reloj, pausa, finalizar y progreso visibles.
- Historial agrupado, detalles y borrado de sesiones, resumen copiable,
  medallas, presets editables, sonido y contenido explicativo conservados.
- Source Serif 4 para lectura de interfaz, empaquetada localmente junto a
  Instrument Serif. Sin fuentes remotas ni frameworks.
- Todos los botones usan etiquetas con mayúscula inicial y verbos claros.
- En móvil, el inicio reúne selector, botón, total y medallas en la primera
  pantalla; durante la sesión, reloj, progreso y controles caben sin scroll.
- Diseño responsive, foco de teclado y movimiento reducido respetado.

### 2026-10-26

- Reescritura completa para que la web sea la versión web de la app 1.0.4.
- Misma marca: wordmark `nada!`, negro `#000000`, hueso `#F2EFE6`, Instrument
  Serif y Crimson Text empaquetadas.
- Modo libre y metas con los mismos tres tiempos editables.
- Registro local con total, sesiones, racha, promedio, agrupación por día y
  detalle de cada sesión.
- Persistencia de la sesión activa y recuperación por marca de tiempo.
- Luz de fondo en movimiento, pausa física, resumen de cierre y manifiesto.
- Chime de dos notas con Web Audio y ajuste de sonido.
- Copiar resumen, borrar sesiones y diseño responsive.
- Sin frameworks: HTML, CSS y JavaScript.

## Créditos

- Tipografías: [Instrument Serif](https://fonts.google.com/specimen/Instrument+Serif)
  y [Source Serif 4](https://fonts.google.com/specimen/Source+Serif+4), SIL Open
  Font License. Licencia incluida en `fonts/`.
- Hecho con Flutter en Android y con HTML, CSS y JavaScript en la web. Sin
  frameworks, sin analytics, sin prisa.
- Ernesto Flames (DOSe) · MIT.

---

<p align="center"><sub>no hacer nada también es una forma de estar completo.</sub></p>
