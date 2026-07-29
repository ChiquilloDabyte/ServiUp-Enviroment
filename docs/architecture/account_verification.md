# Verificación progresiva de cuenta

## Contrato funcional

- El registro usa correo y contraseña y envía un enlace de verificación.
- Una cuenta puede explorar con el perfil o la identidad incompletos.
- Un cliente necesita perfil completo y correo verificado para publicar.
- Un prestador necesita perfil completo, correo verificado y celular
  verificado para crear propuestas.
- Los clientes no proporcionan teléfono.
- `users.phone` usa E.164 y solo se sincroniza para prestadores cuando coincide
  con `request.auth.token.phone_number`.
- Solo los prestadores con `phoneVerifiedAt` aparecen en
  `provider_public_profiles` y en el directorio Isar.

La vinculación del proveedor telefónico no habilita una pantalla de inicio de
sesión por teléfono ni MFA.

## Configuración externa requerida

Antes de habilitar el flujo en producción:

1. Vincular el proyecto de Firebase con una cuenta de facturación.
2. Habilitar Phone en Authentication > Sign-in method.
3. Permitir únicamente Colombia en la política regional de SMS.
4. Registrar las huellas SHA-1 y SHA-256 de las variantes Android.
5. Confirmar la clave APNs, Push Notifications y Remote notifications para
   iOS. El proyecto ya declara el entitlement y el modo en segundo plano, pero
   debe validarse mediante Xcode y un dispositivo real.
6. Personalizar en español la plantilla de verificación de correo.
7. Configurar números ficticios `+57` y códigos de seis dígitos para pruebas.

No desactivar la verificación de aplicación ni incluir números ficticios en
builds de producción.

## Despliegue

La adopción se divide para no bloquear versiones antiguas antes de que puedan
mostrar el flujo:

1. Desplegar las reglas que permiten sincronizar `phone` y
   `phoneVerifiedAt`, y publicar la aplicación compatible.
2. Verificar Android e iOS con números ficticios y después con un número real.
3. Desplegar la regla que exige correo para nuevas solicitudes, la validación
   de `createProposal` y la proyección restringida.
4. Exportar Firestore a un destino controlado.
5. Ejecutar la migración primero en modo de lectura:

   ```bash
   cd backend/functions
   npm run migrate:projections
   ```

6. Revisar `clientPhonesCleared`, `providerProfilesDeleted` y el total de
   escrituras. Aplicar solo después de confirmar el respaldo:

   ```bash
   npm run migrate:projections -- --apply --backup-confirmed
   ```

La migración borra teléfonos históricos de clientes, conserva en privado los
teléfonos no verificados de prestadores y elimina sus proyecciones públicas.
Los directorios Isar se corrigen en la siguiente sincronización completa.

## Observabilidad

Analytics registra únicamente nombres de eventos de inicio, envío,
finalización y fallo. No se registran correo, teléfono, código SMS ni tokens.
Revisar la cuota de SMS, errores `too-many-requests`, fallos de APNs/reCAPTCHA y
rechazos `account-verification-required` durante el despliegue.
