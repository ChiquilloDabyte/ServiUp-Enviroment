# Contexto del proyecto ServiUp

Última actualización: 2026-07-27

## Propósito

ServiUp es un marketplace móvil desarrollado con Flutter que conecta clientes
que solicitan servicios con prestadores independientes. El producto contempla
publicación y gestión de solicitudes, negociación de precios, chat,
notificaciones y consulta offline de datos básicos de prestadores.

Este archivo describe el estado real y las decisiones vigentes del proyecto.
Las normas obligatorias de arquitectura, calidad, seguridad y estilo están en
[`AGENTS.md`](AGENTS.md).

## Estado actual

- Rama de integración actual: `develop`.
- La aplicación Flutter está en `app/`.
- Las reglas, índices y Cloud Functions de Firebase están en `backend/`.
- El proyecto Firebase configurado es `serviup`.
- La versión declarada de la aplicación es `1.0.0+1`.
- El SDK de Dart declarado en `pubspec.yaml` es `^3.7.0`.
- El backend de Cloud Functions usa Node.js 22 y TypeScript.
- El último cambio funcional integrado corresponde a chat y negociación.

### Funcionalidades con implementación

- Registro, inicio de sesión, recuperación de contraseña y cierre de sesión.
- Roles de cliente y prestador, con finalización de perfil mediante onboarding.
- Creación y consulta de solicitudes de servicio.
- Exploración de solicitudes por prestadores.
- Geolocalización, mapa, selección de ubicación y autocompletado de direcciones.
- Ofertas, contraofertas y aceptación de propuestas.
- Chat entre cliente y prestador, incluidos mensajes de texto e imágenes.
- Notificaciones dentro de la aplicación y notificaciones push mediante FCM.
- Cambios de estado de una solicitud: abierta, aceptada, en progreso,
  completada y cancelada.
- Directorio offline de prestadores almacenado con Isar.
- Sincronización del directorio local cuando existe conexión y sesión activa.
- Textos legales de términos y privacidad.
- Sistema visual Organic Utility aplicado a los flujos de identidad,
  solicitudes, listados, negociación, chat, notificaciones, modo offline y
  textos legales.
- Dashboard por rol: los clientes exploran prestadores mediante perfiles
  públicos y conservan sus solicitudes; los prestadores buscan solicitudes
  cercanas y administran sus trabajos activos.
- Consulta y edición del perfil propio, incluida foto y categorías del
  prestador, mediante el contrato acotado `ProfileUpdate`.
- Calificación única del cliente después de completar el servicio, persistida
  como `reviews/{requestId}`.
- Navegación principal persistente mediante una barra inferior con acceso al
  dashboard, las conversaciones y el perfil para ambos roles.

La presencia de código indica que estas funciones están implementadas, pero no
equivale por sí sola a validación completa para producción.

## Arquitectura vigente

La aplicación sigue una separación inspirada en Clean Architecture:

```text
app/lib/
├── config/                 # Inicialización de Firebase y GoRouter
├── core/                   # Constantes, errores, logger y tema
├── data/
│   ├── repositories/       # Acceso coordinado a fuentes de datos
│   └── services/           # Firebase, almacenamiento, mapas, red e Isar
├── domain/
│   ├── providers/          # Inyección y estado con Riverpod
│   └── viewmodels/         # Lógica de presentación
├── models/                 # Modelos de Firestore, Isar y enums
├── views/                  # Pantallas organizadas por funcionalidad
├── widgets/                # Componentes reutilizables
└── utils/                  # Utilidades de formato
```

Reglas arquitectónicas objetivo:

- Los Widgets y Views no deben consultar Firebase directamente.
- Los Repositories son la frontera de acceso a datos.
- Los Services encapsulan integraciones externas.
- Los ViewModels contienen la lógica de presentación.
- Riverpod gestiona estado e inyección de dependencias.
- GoRouter gestiona navegación y redirecciones de autenticación/perfil.
- El logger centralizado sustituye el uso de `print()`.

Existen desviaciones de estas fronteras en el código actual; se registran en
la sección de riesgos y deben corregirse gradualmente sin mezclar esa
refactorización con cambios funcionales no relacionados.

## Decisiones técnicas vigentes

| Área | Decisión | Motivo o uso actual |
|---|---|---|
| UI | Flutter y Material Design 3 | Aplicación multiplataforma |
| Estado | Riverpod | Estado reactivo e inyección comprobable |
| Navegación | GoRouter | Rutas declarativas y protección por sesión/perfil |
| Backend | Firebase | Auth, Firestore, Storage, FCM, Crashlytics y Analytics |
| Base local | Isar | Directorio offline de prestadores |
| Conectividad | `connectivity_plus` | Condicionar la sincronización local |
| Ubicación | Geolocator, Geocoding y Google Maps | Posición, direcciones y mapas |
| Autocompletado | Google Places SDK Plus | Búsqueda de direcciones |
| Backend reactivo | Cloud Functions v2 | Notificaciones y consistencia de flujos |
| Logging | `logger` | Registro centralizado de eventos y errores |

No se debe sustituir Isar, Riverpod o GoRouter sin documentar primero la
decisión y su impacto.

## Sistema visual

La interfaz usa el sistema Organic Utility documentado en [`DESIGN.md`](DESIGN.md):

- paleta semántica verde y superficies tonales de Material Design 3;
- Manrope local como tipografía de toda la aplicación;
- escala compartida de espaciados y radios;
- margen móvil de 20 px y contenido responsive con ancho máximo de 1200 px;
- botones con altura mínima de 48 px;
- tarjetas, estados vacíos, banners offline, chips de estado y superficies de
  formulario reutilizables;
- barra de progreso de 4 px para representar el ciclo de una solicitud.

Los tokens viven en `app/lib/core/theme/` y los componentes visuales
reutilizables en `app/lib/widgets/`. Los colores visibles de acciones
principales usan `#50752D`, mientras `#395C16` conserva el rol semántico
`primary` definido en el bloque de tokens de `DESIGN.md`.

## Modelo de dominio y Firestore

### Colecciones principales

- `users`: identidad de dominio, rol, perfil, categorías, teléfono y token FCM.
- `service_requests`: solicitudes creadas por clientes y su ciclo de vida.
- `offers`: propuestas y contrapropuestas económicas.
- `chats`: conversación determinista por solicitud y prestador.
- `chats/{chatId}/messages`: mensajes de texto o imagen.
- `notifications`: notificaciones persistentes por usuario.

### Estados relevantes

- Solicitud: `open`, `accepted`, `in_progress`, `completed`, `cancelled`.
- Oferta: `pending`, `accepted`, `rejected`, `superseded`.
- Chat: `active`, `read_only`.
- Roles: cliente y prestador; usar los valores definidos por `UserRole`.

### Reglas de negocio reflejadas en seguridad

- Solo usuarios autenticados acceden a los datos funcionales.
- El cliente crea y cancela sus propias solicitudes.
- Un prestador consulta solicitudes abiertas y las que le fueron asignadas.
- Solo participantes autorizados acceden a ofertas y chats.
- Los mensajes no se pueden editar ni eliminar.
- Los chats usan el identificador determinista
  `{requestId}_{providerId}`.
- Al aceptar una oferta se vinculan solicitud, oferta, prestador y precio.
- Las notificaciones solo son creadas por el backend.
- No se permiten eliminaciones de documentos funcionales desde el cliente.

Los índices compuestos se mantienen en
`backend/firestore.indexes.json` y las reglas en
`backend/firestore.rules` y `backend/storage.rules`.

## Cloud Functions

`backend/functions/src/index.ts` contiene actualmente:

- `onOfferCreated`: notifica al destinatario de una nueva propuesta.
- `onOfferAccepted`: notifica al autor cuando se acepta una propuesta.
- `onChatMessageCreated`: notifica al destinatario de un nuevo mensaje.
- `onServiceRequestUpdated`: cierra chats no aplicables y rechaza ofertas
  pendientes cuando cambia el estado de una solicitud.

Las funciones guardan primero una notificación en Firestore e intentan enviar
la notificación push si el usuario tiene un token FCM.

## Funcionamiento offline

El modo offline mantiene en Isar una copia limitada de prestadores que:

- tienen rol de prestador;
- completaron su perfil;
- tienen un número telefónico no vacío.

La sincronización reemplaza el directorio local completo con los datos más
recientes de Firestore. Solo se ejecuta si hay una sesión autenticada y el
servicio de conectividad informa acceso a red. La base local está separada de
Firestore y no almacena contraseñas.

## Navegación disponible

Las rutas declaradas incluyen:

- `/splash`
- `/login`, `/register`, `/forgot-password`
- `/onboarding`
- `/home`
- `/profile`, `/profile/edit`
- `/requests/create`, `/requests/:id`
- `/requests/:id/review`
- `/provider/requests/:id`
- `/request-location`
- `/chats`, `/chats/:id`
- `/notifications`
- `/offline`
- `/terms`, `/privacy`

Las rutas `/home`, `/chats` y `/profile` comparten una barra de navegación
inferior. Los detalles de chat, la edición del perfil y los demás flujos
secundarios se presentan fuera de esa barra.

Una sesión ausente redirige a login. Una sesión válida con perfil incompleto
redirige a onboarding.

## Configuración del entorno

Requisitos:

- Flutter estable compatible con Dart `^3.7.0`.
- Firebase CLI.
- Node.js 22 para Cloud Functions.
- Acceso autorizado al proyecto Firebase `serviup`.
- Configuración válida de Google Maps/Places por plataforma.

Preparar la aplicación:

```bash
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Ejecutar:

```bash
cd app
flutter run
```

Validar la aplicación:

```bash
cd app
dart format .
flutter analyze
flutter test
```

Validar el backend:

```bash
cd backend/functions
npm ci
npm run lint
npm run build
npm run test:rules
```

No registrar claves privadas, tokens, contraseñas ni valores secretos en este
archivo. Los archivos de configuración Firebase por plataforma existentes
deben tratarse según la política de seguridad del equipo.

## Pruebas existentes

La suite Flutter incluye pruebas para:

- tema, tipografía, colores y tamaño mínimo de botones;
- layout responsive en móvil y escritorio;
- tarjetas y chips semánticos de solicitudes;
- superficies de identidad y textos legales;
- enums y modelos de chat/ofertas;
- servicio de ubicación y configuración de mapas;
- ViewModel de búsqueda de lugares;
- vistas de chat, listado de chats y detalle de solicitud;
- prueba base de widgets.

El backend incluye pruebas de reglas en
`backend/functions/test/rules.test.js`.

El estado de aprobación de todas las pruebas no fue establecido al crear este
documento; debe confirmarse ejecutando los comandos de calidad antes de cada
commit.

## Riesgos y pendientes conocidos

- Corregir accesos directos desde presentación a Firebase o Services. Por
  ejemplo, `splash_view.dart` usa `FirebaseAuth` y servicios directamente;
  otras Views consumen `LocationService`, y algunos ViewModels consumen
  Services en lugar de Repositories.
- Crear o ampliar Repositories para autenticación de sesión, ubicación,
  búsqueda de lugares, conectividad y sincronización donde sea necesario,
  manteniendo los Services como adaptadores de bajo nivel.
- Confirmar que `flutter analyze`, `flutter test`, el build TypeScript, lint y
  las pruebas de reglas pasan en el entorno actual.
- Revisar la cobertura unitaria de toda la lógica de negocio crítica.
- Validar reglas e índices contra los flujos completos de negociación y chat
  usando Firebase Emulator Suite.
- Verificar FCM, permisos de ubicación, mapas, Places y carga de imágenes en
  dispositivos Android e iOS reales.
- Definir y documentar la estrategia de despliegue por ambientes.
- Revisar las credenciales/configuraciones Firebase incluidas en el repositorio
  y rotarlas si alguna credencial sensible hubiera sido expuesta.
- Mantener sincronizados `README.md`, este archivo y las decisiones
  arquitectónicas futuras.

## Estado del árbol de trabajo al crear este archivo

Había modificaciones locales previas en archivos generados de plugins para
Linux, macOS y Windows. No forman parte de la creación de este documento y no
deben descartarse sin confirmar su origen:

- `app/linux/flutter/generated_plugin_registrant.cc`
- `app/linux/flutter/generated_plugin_registrant.h`
- `app/linux/flutter/generated_plugins.cmake`
- `app/macos/Flutter/GeneratedPluginRegistrant.swift`
- `app/windows/flutter/generated_plugin_registrant.cc`
- `app/windows/flutter/generated_plugin_registrant.h`
- `app/windows/flutter/generated_plugins.cmake`

## Próximos pasos recomendados

1. Ejecutar y corregir toda la suite de calidad.
2. Probar los flujos críticos de extremo a extremo con dos roles.
3. Documentar configuración y despliegue separados para desarrollo,
   pruebas y producción.
4. Convertir decisiones arquitectónicas importantes futuras en ADR dentro de
   `docs/architecture/`.
5. Actualizar este archivo cuando cambien el estado, los bloqueos o las
   decisiones vigentes.

## Actualización: estabilización previa al dashboard

La rama de estabilización del núcleo parte del `develop` que ya contiene la
nueva interfaz. Las pantallas principales de cliente y prestador quedan
reservadas para el trabajo de dashboard y no forman parte de esta
estabilización.

Cambios de arquitectura y dominio:

- `users` pasa a ser privado y los prestadores publican una proyección limitada
  en `provider_public_profiles`.
- Las solicitudes abiertas se consultan mediante
  `open_request_listings`, que no expone la dirección ni las coordenadas
  exactas a prestadores no asignados.
- Propuestas, aceptación y transiciones del servicio se ejecutan mediante
  Cloud Functions callable y transacciones.
- El ciclo incorpora `pending_confirmation`: el prestador solicita cierre y el
  cliente confirma o devuelve el servicio a `in_progress` con un motivo.
- `reviews/{requestId}` queda reservado para una única calificación del cliente
  después de completar el servicio. `rating` y `ratingCount` son agregados de
  servidor.
- App Check se inicializa en Flutter; su exigencia en producción se habilitará
  gradualmente después de configurar y verificar los proveedores de cada
  plataforma.
- El cierre de sesión desactiva primero las suscripciones autenticadas de
  Riverpod y después revoca Firebase Auth, evitando consultas Firestore
  residuales sin permisos durante la transición.
- El directorio Isar se sincroniza desde `provider_public_profiles`.
- Los listados crecientes exponen un tamaño de página predeterminado de 20.

La integración de `juan-david` se portó manualmente sobre `develop` para
preservar la estabilización. Las vistas de perfil usan el contrato acotado
`ProfileUpdate` y la calificación respeta `reviews/{requestId}`.

El orden de despliegue, la migración de proyecciones y la configuración de
Maps/firma están documentados en
`docs/architecture/core_stabilization.md`.

Riesgos técnicos todavía controlados:

- El feed de solicitudes cercanas requiere dos índices de
  `open_request_listings` que solo difieren en la dirección de `__name__`: la
  consulta normal usa `DESCENDING` implícito y la paginación con cursor usa
  `ASCENDING` explícito. Ambos deben desplegarse.
- Las reglas permiten actualizar exclusivamente `fcmToken` en perfiles
  anteriores a `ratingCount`; esto mantiene el inicio de sesión compatible
  mientras se completa la migración. La sincronización del token es de mejor
  esfuerzo y no bloquea la sesión ni reporta un fallo fatal.
- `npm audit --omit=dev` conserva ocho avisos moderados transitivos cuya única
  corrección propuesta requiere actualizar `firebase-admin` a una versión
  mayor; la vulnerabilidad alta y la baja corregibles sin salto mayor sí
  quedaron resueltas en el lockfile.
- Flutter advierte que próximamente dejará de soportar las versiones actuales
  de Gradle, Android Gradle Plugin y Kotlin. El build Android sigue pasando,
  pero esas actualizaciones deben realizarse juntas en una tarea de
  compatibilidad separada.
- La configuración iOS se preparó en Windows y debe validarse mediante build,
  firma y notificaciones en un equipo macOS antes de distribuirse.
