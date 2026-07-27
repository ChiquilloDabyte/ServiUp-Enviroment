# Estabilización del núcleo antes del dashboard

## Límites de integración

La estabilización parte del `develop` que ya contiene
`feature/integrate-new-ui`. No modifica:

- `app/lib/views/home/home_view.dart`;
- `app/lib/views/client/client_home_view.dart`;
- `app/lib/views/provider/provider_home_view.dart`.

La rama `juan-david` no debe fusionarse directamente. Cuando perfil y
calificación estén terminados, se crea una rama nueva desde el `develop`
actualizado y se portan manualmente sus vistas. El perfil debe usar
`UserRepository.updateEditableProfile`; no debe escribir un `UserModel`
completo ni modificar `role`, `rating` o `ratingCount`.

Las rutas reservadas para ese portado son `/profile` y `/profile/edit`. Los
accesos desde las pantallas principales se coordinan con el responsable del
dashboard.

## Contratos de Firestore

- `users/{uid}`: perfil privado. Solo lo lee el propietario. El cliente puede
  editar nombre, teléfono, foto, ubicación, categorías, estado de perfil y
  token FCM. Rol y agregados de calificación son de solo servidor.
- `provider_public_profiles/{uid}`: proyección autenticada con nombre,
  teléfono, foto, categorías, `rating`, `ratingCount` y `updatedAt`.
- `service_requests/{requestId}`: solicitud privada con dirección y
  coordenadas exactas. Solo la leen el cliente y el prestador aceptado.
- `open_request_listings/{requestId}`: proyección para el feed del prestador.
  Mientras está abierta usa coordenadas redondeadas a dos decimales y omite la
  dirección exacta. Al asignarse solo queda visible para sus participantes.
- `reviews/{requestId}`: una reseña por servicio completado, creada por su
  cliente, con calificación entera de 1 a 5 y comentario de hasta 500
  caracteres.

El ciclo del servicio es:

```text
open -> accepted -> in_progress -> pending_confirmation -> completed
                               ^             |
                               |-------------|
                                devolución
```

La devolución exige un motivo de 10 a 500 caracteres. No existe cierre
automático ni estado de disputa.

## Orden obligatorio de despliegue

1. Desplegar Functions y los índices sin publicar todavía las reglas
   restrictivas.
2. Ejecutar `npm run migrate:projections` sin argumentos. Este es el modo
   simulación y solo imprime cantidades.
3. Revisar las cantidades y ejecutar
   `npm run migrate:projections -- --apply` con credenciales administrativas.
4. Verificar muestras de ambas proyecciones.
5. Publicar la aplicación que consume las proyecciones y las Functions
   callable.
6. Desplegar `backend/firestore.rules` y `backend/storage.rules`.
7. Activar gradualmente la exigencia de App Check en Firebase Console después
   de comprobar Play Integrity y App Attest. Las callables aceptan tokens de
   App Check, pero todavía no los exigen.

La migración es idempotente y escribe en lotes de hasta 400 operaciones.

## Configuración local y release

Cloud Functions requiere Node.js 22. Flutter no necesita Node para ejecutar la
aplicación.

La clave de Google Maps no vive en el manifiesto. En desarrollo se declara en
`app/android/local.properties`:

```properties
MAPS_API_KEY=valor_local
```

En CI puede pasarse como propiedad Gradle `MAPS_API_KEY`. La clave retirada del
historial debe restringirse por aplicación/API y rotarse en Google Cloud.

En iOS se crea localmente `app/ios/Flutter/Secrets.xcconfig`, ignorado por Git:

```text
GOOGLE_MAPS_API_KEY=valor_local
```

La firma Android release usa `app/android/key.properties`:

```properties
storeFile=ruta/al/keystore.jks
storePassword=...
keyAlias=...
keyPassword=...
```

El archivo y los keystores están ignorados por Git. iOS declara permisos,
notificaciones remotas y entitlements diferenciados entre Debug y Release.
Los identificadores de paquete actuales se conservan hasta disponer de
archivos Firebase válidos para los identificadores oficiales.

## Validación

Desde `app/`:

```bash
flutter analyze
flutter test
```

Desde `backend/functions/`, usando Node.js 22:

```bash
npm ci
npm run lint
npm run build
npm run test:rules
npm run test:functions
```

Las pruebas de reglas y Functions usan Firestore Emulator, cuyos puertos están
declarados en `firebase.json`.
