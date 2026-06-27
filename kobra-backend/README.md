# Kobra Backend

API REST para Kobra, una app de control de ventas. Construida con NestJS + Prisma, usando PostgreSQL alojado en [Neon](https://neon.tech).

## ⚠️ Importante: el archivo `.env`

Este proyecto ya incluye un archivo `.env` con las credenciales reales de la base de datos de Neon y un `JWT_SECRET` generado, para que puedas correrlo de inmediato.

**NUNCA subas el archivo `.env` a un repositorio público (GitHub, GitLab, etc.).** El `.gitignore` ya lo excluye, pero verifica siempre con `git status` antes de hacer commit/push que `.env` no aparezca como archivo a subir. Si necesitas compartir la configuración con otra persona, usa `.env.example` como plantilla y entrega las credenciales reales por un canal seguro (no por chat público ni commit).

Si en algún momento sospechas que las credenciales de Neon quedaron expuestas (por ejemplo, las subiste por error a un repo público), rota la contraseña de la base de datos desde el dashboard de Neon y actualiza el `.env`.

## Stack

- NestJS 11
- Prisma 6 (ORM) + PostgreSQL 18 (Neon)
- JWT (`@nestjs/jwt` + `passport-jwt`) para autenticación
- `bcrypt` para hash de contraseñas
- `class-validator` / `class-transformer` para validación de DTOs

## Modelo de datos

`Usuario` (ADMIN | VENDEDOR) → `Venta` → `DetalleVenta` → `Variante`, y `Venta` → `Cliente`.

`Producto` es solo el nombre base que agrupa (ej. "Yogurt griego"); cada combinación concreta y vendible (tamaño, topping, o ambos) es una `Variante` con su propio precio (ej. "250g sin topping", "250g mermelada de fresa", "500g arándanos"). Las ventas siempre apuntan a una `Variante`, nunca al producto directo — así no hay que resolver combinaciones en el momento de vender, ya quedan pre-registradas. Ver `prisma/schema.prisma` para el detalle completo.

## Variables de entorno

| Variable | Descripción |
|---|---|
| `DATABASE_URL` | Connection string de Neon **con pooler** (`-pooler` en el host). Se usa en runtime. |
| `DIRECT_URL` | Connection string de Neon **sin pooler**. Se usa solo para migraciones (`prisma migrate`). |
| `JWT_SECRET` | Secreto para firmar los JWT. Cambia este valor en producción. |
| `JWT_EXPIRES_IN` | Expiración del JWT (por defecto `7d`). |
| `PORT` | Puerto local (Render lo asigna automáticamente en producción). |

## Correr el backend localmente

```bash
npm install

# Si es la primera vez (o cambiaste el schema): crea/aplica migraciones
npx prisma migrate dev

# Carga los datos de prueba (1 admin, 1 vendedor, 1 producto con 1 variante "Base")
npx prisma db seed

# Levanta el servidor en modo watch
npm run start:dev
```

El servidor queda escuchando en `http://localhost:3000` (o el `PORT` que definas).

### Usuarios de prueba (creados por el seed)

| Email | Password | Rol |
|---|---|---|
| `admin@kobra.com` | `admin123` | ADMIN |
| `vendedor@kobra.com` | `vendedor123` | VENDEDOR |

Cambia estas contraseñas o crea usuarios nuevos vía `POST /auth/register` antes de usar la app con datos reales.

## Endpoints principales

- `POST /auth/login` — `{ email, password }` → `{ accessToken, usuario }`
- `POST /auth/register` — crea un usuario (pensado para el setup inicial)
- `GET /health` — chequeo de vida, sin autenticación
- `GET/POST/PATCH/DELETE /clientes` — ADMIN y VENDEDOR pueden ver/crear clientes; solo ADMIN puede editar/eliminar
- `GET/POST/PATCH/DELETE /productos` — todos pueden ver (cada producto incluye sus variantes anidadas); solo ADMIN puede crear/editar/eliminar. Eliminar un producto borra también sus variantes (en transacción), salvo que alguna ya tenga ventas registradas, en cuyo caso falla con 400 y no borra nada.
- `POST /productos/:productoId/variantes` — solo ADMIN, crea una variante (nombre + precio) para ese producto
- `PATCH/DELETE /variantes/:id` — solo ADMIN, edita o elimina una variante existente
- `POST /ventas` — crea una venta con sus detalles, cada detalle referencia una `varianteId` (el total se calcula en el backend a partir del precio actual de cada variante)
- `GET /ventas` — ADMIN ve todas (filtros `?vendedorId=&clienteId=&estado=`), VENDEDOR solo ve las suyas
- `GET /ventas/:id` — detalle de una venta
- `PATCH /ventas/:id/estado` — cambia el estado de una venta (`PENDIENTE`, `POR_PAGAR`, `PAGADO`, `CANCELADO`). Esto es **cancelar** una venta (pasarla a `CANCELADO`), no borrarla.
- `DELETE /ventas/:id` — **elimina** la venta y sus detalles. ADMIN puede eliminar cualquiera; VENDEDOR solo las suyas. Distinto de cancelar: esto borra el registro por completo y no se puede deshacer.
- `GET /estadisticas` — solo ADMIN. Devuelve `totalVentas`, `totalFacturado`, `topClientes` (ranking por cantidad de ventas, con productos comprados y total gastado) y `topProductos` (ranking por unidades vendidas). Las ventas `CANCELADO` no se cuentan. Acepta filtros opcionales `?desde=&hasta=` (fechas ISO 8601) para acotar por rango de `Venta.fecha`; la app calcula esos rangos a partir de presets (hoy, esta semana, este mes, este año, etc.).

Todos los endpoints salvo `/health`, `/auth/login` y `/auth/register` requieren el header `Authorization: Bearer <token>`.

## Desplegar en Render

1. Sube este proyecto a un repositorio de GitHub/GitLab (**verifica que `.env` no se suba**, solo `.env.example`).
2. En Render, crea un nuevo **Web Service** y conecta el repositorio. Si usas el `render.yaml` incluido, Render detecta automáticamente la configuración (Blueprint).
3. Si lo configuras a mano:
   - **Build command**: `npm install && npx prisma generate && npm run build`
   - **Start command**: `npx prisma migrate deploy && npm run start:prod`
   - **Environment**: Node
   - **Plan**: Free o Starter
4. Configura las variables de entorno en el panel de Render (no se suben por git):
   - `DATABASE_URL` (la de Neon, con `-pooler`)
   - `DIRECT_URL` (la de Neon, sin `-pooler`)
   - `JWT_SECRET` (genera uno distinto al de desarrollo)
   - `JWT_EXPIRES_IN=7d`
5. Configura el **Health Check Path** en `/health` (ya está en `render.yaml`). Esto ayuda a Render a saber si el servicio está vivo; en el plan free el servicio "duerme" tras ~15 min de inactividad y la primera petición después de eso puede tardar 30-60s en responder mientras se reactiva — esto es esperado, no es un error.
6. Una vez desplegado, copia la URL pública (algo como `https://kobra-backend.onrender.com`) y úsala en la app Flutter (ver README general del proyecto).

## Notas de seguridad para producción

- Cambia `JWT_SECRET` por un valor distinto al usado en desarrollo.
- Cambia las contraseñas de los usuarios de seed (`admin123`, `vendedor123`) o elimínalos y crea usuarios reales con `POST /auth/register`.
- Considera proteger `POST /auth/register` (por ejemplo, exigiendo rol ADMIN) una vez que ya tengas los usuarios iniciales creados, ya que en este MVP queda abierto para simplificar el setup.
