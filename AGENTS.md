# ServiUp — Instrucciones para agentes de IA

## Propósito del archivo

Este archivo define las reglas permanentes para trabajar en ServiUp.

Antes de realizar cambios:

1. Leer [`CONTEXT.md`](CONTEXT.md) para conocer el estado y las decisiones
   vigentes.
2. Inspeccionar el código relacionado y sus pruebas.
3. Preservar cambios locales ajenos a la tarea.

Actualizar `CONTEXT.md` cuando una tarea cambie de forma material la
arquitectura, el modelo de datos, las dependencias, el estado de una
funcionalidad, los riesgos conocidos o los próximos pasos. No usarlo como
registro detallado de cada edición; para eso existe Git.

## Objetivo del proyecto

ServiUp es una aplicación móvil en Flutter que conecta clientes que necesitan
un servicio con prestadores independientes.

Los clientes pueden publicar solicitudes indicando:

- tipo de servicio;
- descripción;
- ubicación;
- fecha y hora requeridas.

Los prestadores pueden:

- explorar solicitudes disponibles;
- enviar y negociar propuestas económicas;
- aceptar o gestionar servicios asignados;
- completar el servicio.

Cuando no haya conexión, la aplicación ofrece un directorio local con
información básica y números telefónicos de prestadores para permitir el
contacto directo.

## Estructura del repositorio

```text
ServiUp-Enviroment/
├── app/                         # Aplicación Flutter
│   ├── lib/
│   │   ├── config/              # Firebase bootstrap y GoRouter
│   │   ├── core/                # Constantes, errores, logger y tema
│   │   ├── data/
│   │   │   ├── repositories/    # Frontera de acceso a datos
│   │   │   └── services/        # Integraciones y fuentes de datos
│   │   ├── domain/
│   │   │   ├── providers/       # Proveedores Riverpod
│   │   │   └── viewmodels/      # Lógica de presentación
│   │   ├── models/              # Modelos y enums
│   │   ├── views/               # Pantallas
│   │   ├── widgets/             # Componentes reutilizables
│   │   └── utils/               # Utilidades
│   └── test/
└── backend/
    ├── functions/               # Cloud Functions en TypeScript
    ├── firestore.rules
    ├── firestore.indexes.json
    └── storage.rules
```

No mover carpetas ni cambiar esta arquitectura sin justificar y documentar la
decisión.

## Tecnologías y decisiones vigentes

- Flutter y Dart en las versiones compatibles con `app/pubspec.yaml`.
- Material Design 3.
- Riverpod para estado e inyección de dependencias.
- GoRouter para navegación.
- Firebase Authentication.
- Cloud Firestore.
- Firebase Storage.
- Firebase Cloud Messaging.
- Firebase Crashlytics.
- Firebase Analytics.
- Cloud Functions v2 con TypeScript y Node.js 22.
- Isar como base de datos local.
- Google Maps, Google Places, Geolocator y Geocoding.
- Connectivity Plus para detectar conectividad.

No agregar ni actualizar dependencias sin una justificación técnica y sin
evaluar compatibilidad, mantenimiento, impacto en plataformas y pruebas.
Mantener las versiones declaradas en los manifiestos; no cambiar a “la última”
de forma automática.

## Responsabilidades por capa

### Models

- Representan entidades persistidas, objetos de dominio y enums.
- No contienen lógica de interfaz ni acceso a fuentes de datos.
- La transformación y validación estructural pueden vivir en el modelo cuando
  sean propias de su representación.
- Toda colección de Firestore debe tener un modelo correspondiente.

### Repositories

- Son la API de datos que consumen ViewModels y Providers de dominio.
- Coordinan una o varias fuentes de datos y traducen sus errores.
- Ningún Widget, View o ViewModel debe consultar directamente Firestore,
  Firebase Authentication, Storage o Isar.
- Deben ser inyectables y comprobables; evitar instancias globales ocultas.

### Services

- Encapsulan SDK, clientes externos y operaciones de bajo nivel.
- Ejemplos: autenticación, Firestore, Storage, geolocalización, Places,
  notificaciones, conectividad e Isar.
- Pueden acceder directamente al SDK que encapsulan.
- No contienen código de interfaz ni decisiones de presentación.

### ViewModels

- Contienen lógica de presentación y coordinan Repositories.
- Exponen estados explícitos de carga, éxito y error.
- No contienen Widgets, `BuildContext` persistente ni consultas directas a
  fuentes de datos.

### Views

- Componen pantallas y reaccionan al estado expuesto.
- No contienen lógica de negocio ni consultas de datos.
- La lógica efímera puramente visual puede permanecer en la vista.

### Widgets

- Son componentes de interfaz reutilizables y enfocados.
- Preferir `StatelessWidget` o `ConsumerWidget`.
- Usar `StatefulWidget` solo para estado efímero de UI, controladores,
  animaciones o ciclos de vida.
- Extraer componentes cuando mejoren lectura, reutilización o pruebas.
- Evitar archivos de más de 300 líneas; si se supera el límite, evaluar una
  separación por responsabilidades en lugar de dividir mecánicamente.

## Principios de desarrollo

Aplicar:

- SOLID;
- DRY;
- KISS;
- Clean Code;
- separación de responsabilidades.

Elegir soluciones legibles, modulares, reutilizables, fáciles de probar y
mantener. Evitar abstracciones especulativas y soluciones rápidas que
comprometan la arquitectura.

## Estado y navegación

- Usar Riverpod; no introducir Provider tradicional.
- No usar `setState` para lógica de negocio o estado compartido.
- Usar GoRouter para navegación.
- No usar `Navigator.push` salvo que exista una razón técnica concreta y
  documentada.
- Mantener centralizadas las reglas de redirección por autenticación y perfil.

## Firebase y datos

- Toda operación solicitada por la capa de presentación debe atravesar un
  Repository.
- Centralizar referencias de colecciones y nombres de campos compartidos.
- Manejar y traducir excepciones en todas las lecturas y escrituras.
- Minimizar lecturas repetidas y usar consultas e índices apropiados.
- Mantener modelos, reglas e índices alineados con cada cambio de esquema.
- Para cambios de seguridad o consultas, añadir o actualizar pruebas de reglas
  y validar con Firebase Emulator Suite.
- No depender solo de validaciones del cliente; las reglas deben imponer
  propiedad, rol, transiciones permitidas y campos modificables.
- Evitar eliminaciones destructivas de datos funcionales salvo que el diseño
  las requiera y estén protegidas por reglas y pruebas.

## Base de datos local y sincronización

- Isar es la base local elegida para el directorio offline.
- Mantener la información local separada de Firestore.
- Ejecutar sincronización remota únicamente cuando exista conexión.
- No mezclar sincronización ni resolución de conflictos con la interfaz.
- Definir de forma explícita qué datos se reemplazan, fusionan o conservan.
- No almacenar contraseñas, tokens privados ni información sensible
  innecesaria en la base local.
- Los cambios en esquemas de Isar requieren regenerar código y considerar una
  estrategia de migración.

## Autenticación y seguridad

- Gestionar autenticación mediante Firebase Authentication.
- Nunca almacenar contraseñas localmente.
- Validar y normalizar toda entrada del usuario.
- No registrar tokens, credenciales, datos personales sensibles ni secretos.
- No mostrar `StackTrace`, mensajes internos o detalles de infraestructura al
  usuario en producción.
- Mantener claves de Maps/Places restringidas por aplicación, plataforma y API.
- No introducir secretos en código, documentación, pruebas o historial Git.

## Manejo de errores y logging

- Nunca ignorar excepciones silenciosamente.
- Mostrar mensajes útiles y comprensibles al usuario.
- Registrar errores inesperados mediante el logger centralizado y, cuando
  corresponda, Crashlytics.
- Evitar reportar como error una condición esperada de negocio.
- No dejar `print()` ni `debugPrint()` como logging de producción.

## Convenciones

- Clases, enums y extensiones: `PascalCase`.
- Variables, funciones, parámetros y constantes: `camelCase`.
- Archivos y carpetas Dart: `snake_case`.
- Constantes: declarar con `const`; no añadir prefijos artificiales al nombre.
- Usar `const` en Widgets y valores inmutables siempre que sea posible.
- Comentar decisiones o algoritmos complejos, no código obvio.
- Añadir DartDoc a APIs públicas cuando el contrato, las restricciones o el
  comportamiento no sean evidentes.
- Respetar el formateador oficial de Dart y las reglas de
  `analysis_options.yaml`.

## Rendimiento y accesibilidad

- Evitar reconstrucciones innecesarias y observar solo el estado requerido.
- Paginar o limitar colecciones que puedan crecer.
- Evitar múltiples lecturas del mismo documento dentro de un flujo.
- Comprimir y validar imágenes antes de subirlas cuando corresponda.
- Mantener interfaz consistente con Material Design 3.
- Considerar contraste, escalado de texto, etiquetas semánticas, áreas
  táctiles, foco y lectores de pantalla.

## Pruebas

- Toda lógica de negocio nueva o modificada debe tener pruebas unitarias.
- Los Repositories y ViewModels deben probar éxito, error y estados límite.
- Los Widgets críticos deben tener pruebas de interacción y estados.
- Los flujos críticos deben tener pruebas de integración cuando la
  infraestructura del proyecto lo permita.
- Los cambios en reglas Firestore/Storage requieren pruebas positivas y
  negativas.
- Una corrección de bug debe incluir una prueba de regresión cuando sea
  razonable.
- No borrar, omitir ni debilitar pruebas para hacer pasar una implementación.

## Comandos de calidad

Antes de entregar cambios en Flutter, ejecutar desde `app/`:

```bash
dart format .
flutter analyze
flutter test
```

Si cambió un modelo o esquema con generación de código:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Antes de entregar cambios en Cloud Functions o reglas, ejecutar desde
`backend/functions/`:

```bash
npm run lint
npm run build
npm run test:rules
```

Informar con claridad qué comandos se ejecutaron, cuáles no pudieron ejecutarse
y por qué. No afirmar que una validación pasó si no fue ejecutada.

## Archivos generados

- No editar manualmente archivos generados por Flutter, Firebase, Isar o
  `build_runner`.
- Regenerarlos mediante la herramienta correspondiente.
- No descartar cambios generados preexistentes sin confirmar su origen.
- Revisar el diff generado para evitar incluir cambios ajenos o innecesarios.

## Git

Ramas previstas:

- `main`: producción.
- `develop`: integración.
- `feature/nombre`: funcionalidades.
- `bugfix/nombre`: correcciones.
- `hotfix/nombre`: correcciones urgentes de producción.

Usar Conventional Commits:

- `feat:`
- `fix:`
- `refactor:`
- `docs:`
- `style:`
- `test:`
- `build:`
- `ci:`
- `perf:`
- `chore:`

No crear ramas, commits, pushes ni pull requests salvo que la tarea lo solicite.
No sobrescribir ni revertir cambios ajenos para limpiar el árbol de trabajo.

## Restricciones

- No duplicar código.
- No escribir lógica de negocio dentro de Widgets o Views.
- No acceder directamente a fuentes de datos desde la interfaz.
- No crear clases o archivos con responsabilidades excesivas.
- No usar estado global mutable innecesario.
- No agregar dependencias sin justificación técnica.
- No modificar arquitectura, contratos persistidos o reglas de seguridad sin
  documentar el cambio.
- No incluir credenciales ni secretos.
- No ampliar el alcance de una tarea sin una razón explícita.

## Objetivo final

Mantener un proyecto profesional, seguro, accesible, escalable y preparado para
evolucionar hacia una aplicación de producción.
