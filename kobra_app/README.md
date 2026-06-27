# kobra_app

App Flutter de Kobra (control de ventas). Consume el backend de `kobra-backend` siempre por HTTP — no hay base de datos local ni modo offline.

Ver el README general del proyecto (`../README.md`) para el flujo completo de extremo a extremo. Resumen rápido:

```bash
flutter pub get
flutter run            # elige un dispositivo/emulador/navegador conectado
```

La URL del backend se configura en [`lib/config/api_config.dart`](lib/config/api_config.dart) — por defecto apunta a `http://localhost:3000`.

## Estructura

```
lib/
  config/     # ApiConfig: URL base del backend, timeouts
  models/     # Usuario, Cliente, Producto, Venta, DetalleVenta
  services/   # ApiClient (Dio) + servicios por recurso (auth, clientes, productos, ventas)
  providers/  # Estado de la app con Provider (Auth, Clientes, Productos, Ventas)
  screens/    # Pantallas: login, home, clientes, productos, nueva venta, ventas, detalle
  widgets/    # Componentes reutilizables (estados de carga/error)
```

## Tests

```bash
flutter test test/widget_test.dart          # smoke test de la pantalla de login, no requiere backend
flutter test test/integration_login_test.dart  # prueba real contra el backend: requiere
                                                # `kobra-backend` corriendo en localhost:3000
```
