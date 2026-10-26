# nada!

> el contador de lo que no hiciste.

**nada!** es la versión web de la app de Android. Un botón, un número que crece
y un registro que se acumula. Sin cuentas, sin nube y sin notificaciones que te
pidan hacer más.

No mide productividad. Mide presencia sin propósito.

**Web:** [nada.isdose.com](https://nada.isdose.com)
**App de Android:** [github.com/isDOSe/nada-flutter](https://github.com/isDOSe/nada-flutter)

---

## Qué hace

- **Cronómetro libre.** Empieza en cero y cuenta hacia arriba. Tú decides
  cuándo parar.
- **Metas de nada.** Tres tiempos rápidos editables, 15, 25 y 45 minutos por
  defecto. Al llegar, la sesión se cierra sola y queda guardada.
- **Un registro real.** Cada sesión se guarda con duración, hora de inicio,
  hora de fin y modalidad. El registro vive en tu navegador y sobrevive a un
  recargado o a cerrar la pestaña.
- **El total de tu vida.** Cuánto tiempo llevas sin hacer nada, cuántas
  sesiones, racha de días y detalle agrupado por día.
- **Pausa física.** El cronómetro se congela, la luz de fondo se detiene y el
  botón principal se hunde hasta que continúas.
- **Sonido al terminar.** Un chime corto de dos notas, generado con Web Audio.
  Se puede desactivar en ajustes o probar desde ahí.
- **La misma voz que la app.** Misma tipografía, mismos colores, mismas
  palabras y el mismo manifiesto. La app y la web se leen como el mismo
  producto.

## Capturas

Las capturas de la app viven en
[`nada-flutter/docs/screenshots`](https://github.com/isDOSe/nada-flutter/tree/main/docs/screenshots).
La web usa la misma dirección visual en el navegador.

## Cómo se ve

| Decisión | Por qué |
|---|---|
| Negro puro `#000000` | El vacío no es gris corporativo. En OLED, el fondo desaparece. |
| Hueso `#F2EFE6` | Un blanco cálido, de tinta y papel. |
| **Instrument Serif** | El número es el protagonista. Una serif editorial de alto contraste, con cursiva propia. |
| **Crimson Text** | Texto de libro, legible desde 16 px, con cursivas que susurran. |
| Sin radios, sin sombras suaves, sin gradientes de relleno | La jerarquía se construye con tipografía, espacio y líneas de 1 px. |
| Un solo elemento sólido | El botón principal es la única superficie blanca, con un relieve duro de 4 px. |
| Acciones secundarias con borde | Registro, volver, ajustes, manifiesto, copiar y borrar son botones cuadrados de 1 px. |
| Luz en movimiento | Dos haces hueso se mueven muy despacio detrás del reloj durante la sesión y se congelan al pausar. |
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
├── fonts/            # Instrument Serif + Crimson Text (SIL OFL)
├── images/           # icono, wordmark y Open Graph
└── README.md
```

No hay frameworks, bundler, `node_modules` ni paso de compilación. Es HTML,
CSS y JavaScript del navegador.

## Cómo se guarda

Todo vive en `localStorage` bajo la clave `nada.web.v1`:

- `sessions`: lista de sesiones terminadas.
- `active`: sesión en curso, con `startedAt`, `lastResumedAt` y `accumulatedMs`.
- `settings`: los tres tiempos rápidos, el modo, la meta y el sonido.

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
  y [Crimson Text](https://fonts.google.com/specimen/Crimson+Text), SIL Open
  Font License.
- Hecho con Flutter en Android y con HTML, CSS y JavaScript en la web. Sin
  frameworks, sin analytics, sin prisa.
- Ernesto Flames (DOSe) · MIT.

---

<p align="center"><sub>no hacer nada también es una forma de estar completo.</sub></p>
