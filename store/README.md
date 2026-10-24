# nada! — brand & store kit

## El logo oficial

El logo es **solamente la palabra `nada!`** en una serif editorial de alto
contraste, hueso sobre negro. No lleva icono, tagline ni textura.

| Archivo | Uso |
|---|---|
| `brand/nada-wordmark.svg` | Vector oficial para la web y publicidad. |
| `brand/nada-wordmark-2048.png` | Cuadrado 2048×2048 sobre negro. |
| `brand/nada-wordmark-1024.png` | Versión rápida para redes. |
| `brand/nada-wordmark-transparent.png` | Wordmark recortado con transparencia, para composiciones. |
| `brand/nada-wordmark-black-tight.png` | Wordmark recortado sobre negro, para mockups. |

**Reglas de uso**

- No cambiar el texto, el orden ni la exclamación.
- No añadir sombras, degradados, contornos ni iconos.
- No colocar el logo sobre fondos claros sin una versión invertida aprobada.
- Espacio libre mínimo alrededor: la altura de la letra `n`.
- Tamaño mínimo en pantalla: 120 px de ancho.

**Dirección de arte**

- Negro `#000000`, hueso `#F2EFE6`, ceniza `#A6A096`, borde `#4A453D`.
- Referencias tipográficas: Instrument Serif Italic (palabra) y Crimson Text
  Italic (tagline).
- Generado con **Recraft V4.1 Pro Vector** vía OpenRouter y vectorizado en SVG,
  para que escale sin pérdida desde un favicon hasta una valla.

## Iconos

| Archivo | Uso |
|---|---|
| `brand/icon-play-512.png` | **Icono recomendado para Google Play y launcher**: monograma `n!`, 512×512, PNG 32-bit con alfa opaco (sin transparencia). |
| `brand/icon-play-1024.png` | Master del monograma. |
| `brand/icon-wordmark-512.png` | Alternativa con el wordmark completo, para contextos grandes. |

El launcher de Android ya usa el monograma `n!`, así que el icono de Play y el
del teléfono coinciden. Un wordmark horizontal completo pierde legibilidad a
48 px; por eso el sistema es **wordmark para la marca + monograma para el
icono**.

## Google Play

| Recurso | Archivo | Especificación |
|---|---|---|
| Icono | `brand/icon-play-512.png` | 512×512, PNG 32-bit, sin transparencia |
| Gráfico destacado | `feature-graphic-1024x500.png` | 1024×500, PNG/JPEG, sin alfa |
| Capturas | `screenshots/phone-01…04.png` | 1080×1920, 9:16 |
| Título | ver `listing.md` | ≤ 30 caracteres |
| Descripción corta | ver `listing.md` | ≤ 80 caracteres |
| Descripción completa | ver `listing.md` | ≤ 4000 caracteres |

Las capturas se generaron desde el APK de release y se componen sobre negro
con un marco de 1 px para que se lean como pantallas de teléfono. Si Play
Console recorta el marco, se pueden subir las capturas originales de
`docs/screenshots/` recortadas a 9:16.

Checklist antes de publicar:

1. Reemplazar el icono de la app en Play Console por `icon-play-512.png`.
2. Subir `feature-graphic-1024x500.png`.
3. Subir las cuatro capturas en el orden `01 → 04`.
4. Configurar la ficha de `listing.md`.
5. Añadir una URL de política de privacidad, aunque la app no recopile datos.
6. Firmar el AAB con un keystore propio (el APK de prueba usa la firma debug).

## Web y publicidad

| Archivo | Uso |
|---|---|
| `web/hero-1920x1080.png` | Hero para la landing. |
| `web/og-1200x630.png` | Open Graph / Twitter Card. |
| `brand/nada-wordmark.svg` | Logo para el `<header>`. |
| `brand/nada-wordmark-transparent.png` | Logo sobre fondos propios. |
| `brand/icon-play-512.png` | Favicon / app icon en la web. |

Ejemplo de metadatos:

```html
<meta property="og:title" content="nada! — el contador de lo que no hiciste">
<meta property="og:description" content="El contador del tiempo que no le debes a nadie.">
<meta property="og:image" content="https://nada.isdose.com/og-1200x630.png">
<meta property="og:type" content="website">
<meta name="twitter:card" content="summary_large_image">
```

## Archivos fuente

- `ai/logo-recraft-a.svg` y `.png`: salida original del modelo.
- `tool/make_store_assets.py`: reconstruye todo el kit desde el logo.
- `tool/openrouter_image.py`: cliente mínimo de la Images API de OpenRouter.
