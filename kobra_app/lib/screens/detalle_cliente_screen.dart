import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../utils/formato.dart';
import '../services/clientes_service.dart';
import '../widgets/estado_carga.dart';

class DetalleClienteScreen extends StatefulWidget {
  final int clienteId;

  const DetalleClienteScreen({super.key, required this.clienteId});

  @override
  State<DetalleClienteScreen> createState() => _DetalleClienteScreenState();
}

class _DetalleClienteScreenState extends State<DetalleClienteScreen> {
  final ClientesService _service = ClientesService();
  late Future<DetalleCliente> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _service.obtenerDetalle(widget.clienteId);
  }

  void _recargar() {
    setState(() => _futuro = _service.obtenerDetalle(widget.clienteId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del cliente')),
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(cliente.nombre, style: Theme.of(context).textTheme.headlineSmall),
              if (cliente.telefono != null) ...[
                const SizedBox(height: 4),
                Text(cliente.telefono!, style: Theme.of(context).textTheme.bodyMedium),
              ],
              if (cliente.creadoEn != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Cliente desde ${formatFecha(cliente.creadoEn!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estadísticas', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _filaEstadistica(
                        context,
                        'Total comprado',
                        formatPrecio(detalle.totalComprado),
                      ),
                      _filaEstadistica(
                        context,
                        'Cantidad de ventas',
                        '${detalle.cantidadVentas}',
                      ),
                      _filaEstadistica(
                        context,
                        'Producto más comprado',
                        detalle.productoMasComprado != null
                            ? '${detalle.productoMasComprado!.nombre} '
                                '(${formatMonto(detalle.productoMasComprado!.cantidad)})'
                            : 'Sin compras registradas',
                      ),
                    ],
                  ),
                ),
              ),
              if (cliente.notas != null) ...[
                const SizedBox(height: 16),
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

  Widget _filaEstadistica(BuildContext context, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: Theme.of(context).textTheme.bodyMedium),
          Text(valor, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }

}
