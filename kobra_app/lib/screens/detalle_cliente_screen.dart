import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cliente.dart';
import '../models/usuario.dart';
import '../providers/auth_provider.dart';
import '../providers/clientes_provider.dart';
import '../utils/formato.dart';
import '../services/clientes_service.dart';
import '../widgets/estado_carga.dart';

class DetalleClienteScreen extends StatefulWidget {
  final int clienteId;
  final Cliente cliente;

  const DetalleClienteScreen({
    super.key,
    required this.clienteId,
    required this.cliente,
  });

  @override
  State<DetalleClienteScreen> createState() => _DetalleClienteScreenState();
}

class _DetalleClienteScreenState extends State<DetalleClienteScreen> {
  final ClientesService _service = ClientesService();
  late Future<DetalleCliente> _futuro;
  late Cliente _cliente;

  @override
  void initState() {
    super.initState();
    _cliente = widget.cliente;
    _futuro = _service.obtenerDetalle(widget.clienteId);
  }

  void _recargar() {
    setState(() => _futuro = _service.obtenerDetalle(widget.clienteId));
  }

  Future<void> _mostrarFormularioEditar() async {
    final nombreController = TextEditingController(text: _cliente.nombre);
    final telefonoController = TextEditingController(text: _cliente.telefono ?? '');
    final formKey = GlobalKey<FormState>();

    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar cliente'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                controller: telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (guardar == true && mounted) {
      final clientesProvider = context.read<ClientesProvider>();
      final nombre = nombreController.text.trim();
      final telefono = telefonoController.text.trim();
      final ok = await clientesProvider.actualizar(widget.clienteId, nombre, telefono);

      if (!mounted) return;
      if (ok) {
        setState(() {
          _cliente = Cliente(
            id: _cliente.id,
            nombre: nombre,
            telefono: telefono.isNotEmpty ? telefono : null,
            notas: _cliente.notas,
            creadoEn: _cliente.creadoEn,
          );
        });
        _recargar();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(clientesProvider.error ?? 'No se pudo guardar el cliente')),
        );
      }
    }
  }

  Future<void> _confirmarEliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text(
          '¿Eliminar "${_cliente.nombre}"? Si tiene ventas asociadas no se podrá eliminar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      final clientesProvider = context.read<ClientesProvider>();
      final ok = await clientesProvider.eliminar(widget.clienteId);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(clientesProvider.error ?? 'No se pudo eliminar el cliente')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = context.watch<AuthProvider>().usuario?.rol == Rol.ADMIN;

    return Scaffold(
      appBar: AppBar(
        title: Text(_cliente.nombre),
        actions: esAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar cliente',
                  onPressed: _mostrarFormularioEditar,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Eliminar cliente',
                  onPressed: _confirmarEliminar,
                ),
              ]
            : null,
      ),
      body: FutureBuilder<DetalleCliente>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const EstadoCargando();
          }
          if (snapshot.hasError) {
            return EstadoError(
              mensaje: 'No se pudo cargar el cliente.',
              onReintentar: _recargar,
            );
          }

          final detalle = snapshot.data!;
          final cliente = detalle.cliente;
          final colorScheme = Theme.of(context).colorScheme;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (cliente.telefono != null) ...[
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text(cliente.telefono!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
              if (cliente.creadoEn != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Cliente desde ${formatFecha(cliente.creadoEn!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),

              // Tarjeta resumen principal
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resumen', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _filaEstadistica(
                        context,
                        'Total comprado',
                        formatPrecio(detalle.totalComprado),
                        destacado: true,
                      ),
                      _filaEstadistica(
                        context,
                        'Cantidad de compras',
                        '${detalle.cantidadVentas}',
                      ),
                      if (detalle.cantidadVentas > 0)
                        _filaEstadistica(
                          context,
                          'Ticket promedio',
                          formatPrecio(detalle.ticketPromedio),
                        ),
                      if (detalle.saldoPendiente > 0)
                        _filaEstadistica(
                          context,
                          'Saldo pendiente',
                          formatPrecio(detalle.saldoPendiente),
                          color: colorScheme.error,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Tarjeta historial
              if (detalle.primeraCompra != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Historial', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        _filaEstadistica(
                          context,
                          'Primera compra',
                          formatFecha(detalle.primeraCompra!),
                        ),
                        _filaEstadistica(
                          context,
                          'Última compra',
                          formatFecha(detalle.ultimaCompra!),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Tarjeta preferencias
              if (detalle.productoMasComprado != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Preferencias', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        _filaEstadistica(
                          context,
                          'Producto más comprado',
                          '${detalle.productoMasComprado!.nombre} '
                              '(${formatMonto(detalle.productoMasComprado!.cantidad)})',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (detalle.cantidadVentas == 0) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Este cliente todavía no tiene compras registradas.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],

              if (cliente.notas != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notas', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(cliente.notas!),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _filaEstadistica(
    BuildContext context,
    String etiqueta,
    String valor, {
    bool destacado = false,
    Color? color,
  }) {
    final estilo = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: destacado ? FontWeight.bold : FontWeight.w600,
          fontSize: destacado ? 16 : null,
          color: color,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: Theme.of(context).textTheme.bodyMedium),
          Text(valor, style: estilo),
        ],
      ),
    );
  }
}
