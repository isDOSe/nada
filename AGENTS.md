# Contexto del proyecto — nada

Un solo repo con dos clientes que comparten número de versión.

```
app/    Flutter (Android)
web/    HTML/CSS/JS, sin build
```

## Repositorio público

El repo es público. **No** meter planes de negocio, QA manual, roadmap ni notas
internas: eso vive en la documentación interna (vault de Obsidian), fuera del
repo.

## App (Flutter)

```powershell
cd app
flutter analyze
flutter test
```

- Probar en el emulador `Celularzote_Pixel_8`.
- Releases: `powershell -ExecutionPolicy Bypass -File app\tool\release.ps1`.

## Web

- Sin build. Servir `web/` con `python -m http.server` para probar.
- El despliegue no es aparte: el sitio de isdose copia `web/` con
  `npm run labs:sync` (ver `docs/labs.md` en el repo de isdose). `web/` es la
  fuente de verdad.

## Versión y changelog

- `app/` y `web/` comparten número de versión desde la 1.0.5.
- Cada cambio u opción nueva se anota en el `## Changelog` del `README.md` al
  implementarla.
- Al publicar la versión, su entrada va también en `CHANGELOG.md`.
