# AGENTS.md

# ServiUp - Instrucciones para Agentes de IA

## Objetivo del proyecto

ServiUp es una aplicación móvil desarrollada en Flutter que conecta personas que necesitan un servicio con trabajadores independientes que pueden prestarlo.

Los clientes pueden publicar solicitudes indicando:

- Tipo de servicio
- Descripción
- Ubicación
- Fecha y hora requerida

Los prestadores de servicio pueden:

- Explorar solicitudes cercanas
- Aceptar solicitudes
- Negociar el precio con el cliente
- Completar el servicio

Como funcionalidad adicional, cuando el dispositivo no tenga acceso a internet, la aplicación ofrecerá una base de datos local con información básica y números telefónicos de prestadores de servicios para permitir el contacto directo.

---

# Tecnologías

- Flutter (última versión estable)
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging
- Firebase Crashlytics
- Firebase Analytics
- Firestore Offline Persistence
- SQLite (o Isar/Hive según la decisión final) para almacenamiento local
- Google Maps
- Geolocator
- Git
- GitHub

---

# Arquitectura

Todo el proyecto deberá seguir una arquitectura limpia (Clean Architecture) adaptada a Flutter.

La estructura general será:

lib/

core/
config/
models/
data/
repositories/
services/
domain/
providers/
viewmodels/
views/
widgets/
utils/

Cada capa debe tener responsabilidades claras.

## Model

Representa las entidades de Firestore.

No contiene lógica de negocio.

## Repository

Es el único encargado de acceder a Firebase o a la base de datos local.

Ningún ViewModel ni Widget debe acceder directamente a Firestore.

## Services

Contienen integraciones externas.

Ejemplos:

- Firebase Authentication
- Cloud Storage
- Geolocalización
- Notificaciones
- Base de datos local

## ViewModels

Contienen toda la lógica de presentación.

Nunca deben contener código de interfaz.

## Views

Solo muestran información.

No deben contener lógica de negocio.

## Widgets

Componentes reutilizables.

---

# Principios de desarrollo

Siempre seguir:

- SOLID
- DRY
- KISS
- Clean Code
- Separation of Concerns

---

# Gestión del estado

Utilizar Riverpod como gestor de estado.

No utilizar Provider tradicional.

No utilizar setState para lógica compleja.

---

# Navegación

Utilizar GoRouter.

No utilizar Navigator.push directamente salvo casos excepcionales.

---

# Firestore

Toda interacción con Firestore debe pasar por un Repository.

Nunca escribir consultas desde Widgets.

Cada colección debe tener su Model correspondiente.

Toda lectura y escritura debe manejar excepciones.

---

# Base de datos local

La información offline deberá mantenerse separada de Firestore.

La sincronización deberá realizarse únicamente cuando exista conexión.

Nunca mezclar lógica de sincronización con la interfaz.

---

# Autenticación

Toda autenticación debe gestionarse mediante Firebase Authentication.

Nunca almacenar contraseñas localmente.

---

# Convenciones de nombres

## Clases

PascalCase

Ejemplo:

UserRepository

## Variables

camelCase

Ejemplo:

userLocation

## Archivos

snake_case

Ejemplo:

user_repository.dart

## Constantes

camelCase precedidas por "const"

Ejemplo:

const maxImageSize

---

# Comentarios

Solo comentar código complejo.

Evitar comentarios redundantes.

Todo método público debe tener documentación DartDoc cuando sea necesario.

---

# Widgets

Preferir StatelessWidget.

Utilizar StatefulWidget únicamente cuando sea realmente necesario.

Extraer widgets reutilizables.

Evitar archivos de más de 300 líneas.

---

# Manejo de errores

Nunca ignorar excepciones.

Registrar errores mediante Crashlytics.

Mostrar mensajes amigables al usuario.

No mostrar StackTrace en producción.

---

# Logging

Utilizar un sistema de Logger.

Nunca dejar print() en producción.

---

# Rendimiento

Evitar reconstrucciones innecesarias.

Usar const siempre que sea posible.

Optimizar consultas a Firestore.

Evitar múltiples lecturas de un mismo documento.

---

# Seguridad

Aplicar reglas de seguridad de Firebase.

Validar toda entrada del usuario.

No confiar únicamente en validaciones del cliente.

Nunca almacenar información sensible en texto plano.

---

# Git

Usar ramas:

main

develop

feature/nombre

bugfix/nombre

hotfix/nombre

---

# Convención de commits

Seguir Conventional Commits.

Ejemplos:

feat:

fix:

refactor:

docs:

style:

test:

build:

ci:

perf:

---

# Calidad del código

Antes de realizar un commit ejecutar:

flutter analyze

flutter test

dart format .

El proyecto no debe contener warnings.

---

# Pruebas

Toda lógica de negocio debe tener pruebas unitarias.

Las funcionalidades críticas deben tener pruebas de integración.

---

# Diseño

Seguir Material Design 3.

Mantener una interfaz limpia y consistente.

La accesibilidad debe considerarse desde el inicio.

---

# Objetivo del código generado

Todo código debe ser:

- Legible
- Modular
- Escalable
- Reutilizable
- Fácil de probar
- Fácil de mantener

Evitar soluciones rápidas que comprometan la arquitectura del proyecto.

Cuando existan varias alternativas, elegir aquella que facilite el mantenimiento a largo plazo.

---

# Restricciones

No duplicar código.

No escribir lógica de negocio dentro de Widgets.

No acceder directamente a Firebase desde la interfaz.

No crear clases excesivamente grandes.

No usar variables globales innecesarias.

No agregar dependencias sin una justificación técnica.

No modificar la arquitectura sin documentar el cambio.

---

# Objetivo final

Mantener un proyecto profesional, escalable y preparado para evolucionar hacia una aplicación de producción.