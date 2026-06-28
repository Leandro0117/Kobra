# Kobra — Control de ventas

Kobra es un MVP de control de ventas pensado para un equipo pequeño: varios vendedores registran sus ventas desde el celular (cada uno asignando cliente, productos y estado de pago) y un administrador puede ver todas las ventas de todos, desde cualquier lugar. El administrador además tiene un apartado de Gastos (compra de insumos, proveedores) y una vista de Finanzas que combina ingresos y egresos.

El proyecto tiene dos partes:

- **`kobra-backend/`** — API REST en NestJS + Prisma, base de datos PostgreSQL en Neon. Se despliega en Render.
- **`kobra_app/`** — App Flutter que consume esa API por HTTP. Sin base de datos local ni modo offline: todo se lee y escribe directo contra el backend.

No hay sincronización ni soporte offline a propósito: si el celular no tiene internet, la app no puede registrar ventas. Esto simplifica mucho el MVP.

## Orden recomendado para poner todo a andar

### 1. Backend en local

```bash
cd kobra-backend
npm install
npx prisma migrate dev   # ya se corrió una vez contra Neon; en otra máquina, repítelo
npx prisma db seed       # ya se corrió una vez; crea admin@kobra.com / vendedor@kobra.com
npm run start:dev
```

El backend queda en `http://localhost:3000`. Probar con `curl http://localhost:3000/health`.

Detalle completo (variables de entorno, endpoints, notas de seguridad) en [`kobra-backend/README.md`](kobra-backend/README.md).

### 2. Probar con la app Flutter (apuntando a local)

```bash
cd kobra_app
flutter pub get
flutter run -d windows   # o -d chrome, o con un emulador/dispositivo Android conectado
```

Por defecto la app apunta a `http://localhost:3000` (ver [`kobra_app/lib/config/api_config.dart`](kobra_app/lib/config/api_config.dart)). Si vas a correrla en un **emulador Android**, cambia esa URL a `http://10.0.2.2:3000` (así es como el emulador accede al host).

Usuarios de prueba:

| Email | Password | Rol |
|---|---|---|
| `admin@kobra.com` | `admin123` | ADMIN |
| `vendedor@kobra.com` | `vendedor123` | VENDEDOR |

### 3. Desplegar el backend en Render

Sigue la guía detallada en [`kobra-backend/README.md`](kobra-backend/README.md#desplegar-en-render). En resumen:

1. Sube `kobra-backend/` a un repositorio Git (sin el `.env`, que ya está en `.gitignore`).
2. Crea un Web Service en Render (puede usar el `render.yaml` incluido como Blueprint).
3. Configura las variables de entorno (`DATABASE_URL`, `DIRECT_URL`, `JWT_SECRET`, `JWT_EXPIRES_IN`) con los valores reales de Neon.
4. Render te da una URL pública, por ejemplo `https://kobra-backend.onrender.com`.

**Nota sobre el plan free de Render:** el servicio se "duerme" tras ~15 minutos sin tráfico. La primera petición después de eso puede tardar 30-60 segundos en responder mientras el contenedor se levanta de nuevo. La app Flutter ya está preparada para esto: si una petición tarda, muestra "Conectando con el servidor, puede tardar unos segundos..." en vez de un error.

### 4. Apuntar la app a producción

Edita [`kobra_app/lib/config/api_config.dart`](kobra_app/lib/config/api_config.dart) y cambia:

```dart
static const String baseUrl = 'http://localhost:3000';
```

por:

```dart
static const String baseUrl = 'https://kobra-backend.onrender.com';
```

(usa la URL real que te dio Render). Vuelve a compilar la app.

### 5. Instalar en los celulares de los vendedores

Para Android, genera el APK:

```bash
cd kobra_app
flutter build apk --release
```

El archivo queda en `kobra_app/build/app/outputs/flutter-apk/app-release.apk`. Pásalo a cada celular (por cable, Drive, WhatsApp, etc.) e instálalo habilitando "orígenes desconocidos" si Android lo pide. Cada vendedor inicia sesión con su propio usuario — créalos con `POST /auth/register` (o pídele al admin que los cree) antes de repartir la app.

Cuando quieras publicarla en Play Store más adelante, el nombre y diseño de la app ya son genéricos (no están atados a ningún producto específico), así que no debería ser necesario rediseñar nada para ese paso.

## ⚠️ Seguridad

- El `.env` del backend con las credenciales reales de Neon **no debe subirse a un repositorio público**. Ya está en `.gitignore`; verifica con `git status` antes de cada push.
- Cambia las contraseñas de los usuarios de seed (`admin123`, `vendedor123`) antes de usar la app con datos reales.
- En producción, usa un `JWT_SECRET` distinto al de desarrollo.

## Qué NO incluye este MVP (a propósito)

- Modo offline / sincronización.
- Recuperación de contraseña.
- Notificaciones push.
- Refresh tokens (el JWT simplemente expira a los 7 días y hay que volver a iniciar sesión).
