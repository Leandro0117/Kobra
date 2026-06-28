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
  models/     # Usuario, Cliente, Producto, Variante, Venta, DetalleVenta, Estadisticas,
              # Proveedor, Insumo, Gasto, DetalleGasto, CategoriaGasto, Finanzas
  services/   # ApiClient (Dio) + servicios por recurso (auth, clientes, productos, variantes,
              # ventas, estadisticas, proveedores, insumos, gastos, finanzas)
  providers/  # Estado de la app con Provider, uno por recurso
  screens/    # login, home, clientes, productos, nueva venta, ventas (en curso/historial),
              # detalle, estadísticas, proveedores, insumos, nuevo gasto, gastos, detalle de
              # gasto, finanzas, y los submenús ventas_menu/gastos_menu
  widgets/    # Componentes reutilizables (estados de carga/error, grid de opciones del menú)
```

## Estructura de la app: Ventas / Gastos / Finanzas

El Home se divide según el rol:

- **VENDEDOR** ve directo las opciones de ventas (es lo único a lo que tiene acceso): nueva venta, ventas en curso, historial, clientes, productos.
- **ADMIN** ve 3 apartados: **Ventas** (lo mismo que ve el vendedor, más Estadísticas), **Gastos** (nuevo gasto, historial de gastos, proveedores, insumos) y **Finanzas** (ingresos vs. egresos, con desglose por categoría de gasto).

Notas sobre ventas:

- "Ventas en curso" (`PENDIENTE`/`POR_PAGAR`) e "Historial" (`PAGADO`/`CANCELADO`) son la misma pantalla (`VentasScreen`) reutilizada con distinto filtro de estados.
- **Cancelar** una venta es cambiarle el estado a `CANCELADO` (desde el detalle). **Eliminar** la borra por completo y no se puede deshacer — disponible desde el listado o el detalle. ADMIN elimina cualquier venta; VENDEDOR solo las suyas.
- "Estadísticas" es una pantalla solo para ADMIN. El selector de período (hoy, esta semana, semana pasada, este mes, mes pasado, este año, año pasado, último año, todo) calcula el rango de fechas en el dispositivo y se lo manda al backend como `desde`/`hasta`; el backend solo filtra por rango, no conoce los presets. "Finanzas" usa el mismo selector de período.

Notas sobre gastos (todo exclusivo de ADMIN):

- Un gasto es un carrito como una venta, pero el precio de cada insumo lo ingresa quien registra el gasto (no hay un precio "oficial" de catálogo: varía de compra en compra).
- No hay "cancelar" gastos — se asumen pagados al registrarse. Solo se pueden eliminar.
- Cada gasto tiene una categoría (Insumos, Equipamiento, Servicios, Transporte, Otro) usada para el desglose en Finanzas.

Notas sobre productos:

- Cada `Variante` puede tener un `costo` opcional (lo que cuesta producir/comprar esa variante). Si está, la pantalla de Productos muestra la ganancia estimada (`precio - costo`) y el margen en %.

## Tests

```bash
flutter test test/widget_test.dart             # smoke test de la pantalla de login, no requiere backend
flutter test test/estadisticas_periodo_test.dart  # casos límite del cálculo de rangos de fecha (cruces de mes/año)
flutter test test/integration_login_test.dart  # prueba real contra el backend: requiere
                                                # `kobra-backend` corriendo en localhost:3000
```
