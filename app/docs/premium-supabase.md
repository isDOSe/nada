# Premium: sincronización sin arruinar el producto

El plan gratuito de **nada!** es local y completo. El premium no desbloquea el
contador: desbloquea la continuidad entre dispositivos. Eso mantiene la promesa
de privacidad y evita el clásico "pague para usar su propio historial".

## Contrato ya implementado

`lib/data/sync_service.dart`

```dart
abstract interface class SyncService {
  Future<void> onLocalChange(NadaStoreData data);
  Future<NadaStoreData?> pull();
}
```

`NadaController` llama a `onLocalChange` después de cada escritura local. La
implementación actual (`NoopSyncService`) no hace nada. Sustituirla es todo el
trabajo de integración:

```dart
final controller = NadaController(
  repository: LocalSessionRepository(),
  sync: SupabaseSyncService(client),
  notifications: NadaNotifications.instance,
);
```

## Esquema Supabase

Ejecuta [`supabase/schema.sql`](../supabase/schema.sql). Resumen:

- `nada_sessions` guarda una fila por sesión, con `id` de texto generado en el
  dispositivo (idempotente, sin autoincrementales).
- RLS activado: cada usuario solo ve sus filas (`auth.uid() = user_id`).
- Índice por `user_id, started_at desc` para que el registro baje ordenado.

## Autenticación recomendada

1. Activa **Anonymous Sign-Ins** en Supabase → Authentication → Providers.
2. Al abrir la app premium, `signInAnonymously()`. No hay pantalla de login.
3. Al comprar, vincula email con `updateUser(email:)` o `linkIdentity`. Así el
   registro sobrevive a un cambio de teléfono.
4. El usuario gratuito nunca crea una cuenta ni toca la red.

## Estrategia de sincronización

- **Local es la fuente de verdad.** La UI siempre lee del repositorio local; la
  nube es una copia.
- **Subida idempotente:** `upsert` por `id`. Reintentar no duplica.
- **Bajada al arrancar:** `select * where user_id = auth.uid() and updated_at >
  last_pull`. Mezcla por `id`; gana el `updated_at` más reciente.
- **Borrados:** una fila eliminada en local necesita lápida para no resucitar.
  Añade `deleted_at timestamptz` (o una tabla `nada_deletions`) y sube la lápida
  antes de borrar. Es el único punto que el modelo local actual no cubre.
- **Conflictos:** no hay trabajo colaborativo; last-write-wins por sesión es
  suficiente y predecible.
- **Sesión activa:** no se sincroniza. Vive solo en el dispositivo y se cierra
  localmente.

## Cuándo subir

No en cada tick. `onLocalChange` ya se invoca solo en start/pause/resume/finish.
Aun así, conviene:

- debounce de 1–2 s,
- cola persistente de operaciones pendientes (si no hay red, se reintenta),
- subida inmediata al terminar una sesión,
- bajada al volver a primer plano, con un mínimo de 30 s entre pulls.

## Monetización

Opciones, de menor a mayor fricción:

1. **Pago único "de por vida"** (ej. 9–15 USD) con sync incluido. Simple, sin
   renovaciones, buen encaje con una app de nicho.
2. **Suscripción anual** (ej. 6–10 USD/año) con sync + backup + export + widgets.
3. **Freemium por funciones:** local gratis, nube y widgets de pago. La opción
   más honesta para este producto.

Para compras in-app, RevenueCat simplifica Android/iOS y valida recibos. No es
necesario para lanzar: se puede empezar con un pago único vía Play Billing y una
tabla `entitlements` en Supabase.

## Costos reales

- Supabase Free: proyecto, auth, base de datos y RLS sin costo. Suficiente para
  miles de usuarios mientras el uso sea de texto y el tráfico moderado.
- Si crece: el plan Pro (~25 USD/mes) elimina la pausa por inactividad y sube
  límites. Aun así, una sesión pesa menos de 200 bytes.
- Alternativa auto-hospedada: PocketBase en un VPS de 5 USD/mes, sin límites de
  filas ni de usuarios.
- Alternativa edge: Turso o Cloudflare D1, con free tiers generosos para este
  volumen.

## Privacidad

La versión gratuita no declara permiso de `INTERNET` en Android. Si algún día se
añade sync, el permiso debe entrar solo en la variante premium o declararse con
un texto claro: "tus sesiones se copian a tu cuenta para que no las pierdas".
Nunca analytics, nunca publicidad, nunca venta de datos.
