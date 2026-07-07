# ServiUp

Marketplace móvil en Flutter que conecta clientes con prestadores de servicios.

## Estructura

- `app/` — Aplicación Flutter (Clean Architecture, Riverpod, GoRouter)
- `backend/` — Reglas Firestore/Storage y Cloud Functions

## Requisitos

- Flutter SDK estable (Dart ^3.12)
- Firebase CLI
- Cuenta de Firebase proyecto `serviup`

## Configuración

```bash
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Android

- Application ID: `com.teamMaster.ServiUp`
- Google Maps API key en `android/app/src/main/AndroidManifest.xml`

### iOS

- `GoogleService-Info.plist` en `ios/Runner/`

## Ejecutar

```bash
cd app
flutter run
```

## Calidad

```bash
dart format .
flutter analyze
flutter test
```

## Flujos principales

1. Registro/login con rol cliente o prestador
2. Cliente publica solicitudes con ubicación y fecha
3. Prestador explora solicitudes cercanas y envía ofertas
4. Cliente acepta oferta y prestador completa el servicio
5. Modo offline con directorio local de prestadores (Isar)

## Git

- `main` — producción
- `develop` — integración
- `feature/*` — nuevas funcionalidades
