import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/cliente.dart';
import '../models/usuario.dart';
import '../models/venta.dart';
import '../providers/auth_provider.dart';
import '../providers/clientes_provider.dart';
import '../providers/ventas_provider.dart';
import '../services/ventas_service.dart';
import '../utils/formato.dart';
import '../widgets/estado_carga.dart';
import 'detalle_venta_screen.dart';

String _etiquetaFecha(DateTime fecha) {
  final hoy = DateTime.now();
  final soloHoy = DateTime(hoy.year, hoy.month, hoy.day);
  final soloFecha = DateTime(fecha.year, fecha.month, fecha.day);
  final diff = soloHoy.difference(soloFecha).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  return DateFormat('d MMMM', 'es').format(fecha);
}

Color _colorEstado(EstadoVenta estado) {
  switch (estado) {
    case EstadoVenta.PENDIENTE:
      return const Color(0xFFEF9F27);
    case EstadoVenta.POR_PAGAR:
      return const Color(0xFF378ADD);
    case EstadoVenta.PAGO_PARCIAL:
      return const Color(0xFF7B5EA7);
    case EstadoVenta.PAGADO:
      return const Color(0xFF639922);
    case EstadoVenta.CANCELADO:
      return const Color(0xFF888780);
  }
}

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  Set<EstadoVenta> _filtroEstados = {};
  int? _filtroClienteId;
  String? _filtroClienteNombre;
  final _captureKey = GlobalKey();
  bool _compartiendo = false;

  bool get _hayFiltros => _filtroEstados.isNotEmpty || _filtroClienteId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VentasProvider>().cargar();
      context.read<ClientesProvider>().cargar();
    });
  }

  Future<void> _abrirFiltros() async {
    final esAdmin =
        context.read<AuthProvider>().usuario?.rol == Rol.ADMIN;
    final clientes = context.read<ClientesProvider>().clientes;

    final result = await showModalBottomSheet<
        ({Set<EstadoVenta> estados, int? clienteId, String? clienteNombre})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FiltroSheet(
        estadosActuales: _filtroEstados,
        clienteIdActual: _filtroClienteId,
        clienteNombreActual: _filtroClienteNombre,
        clientes: clientes,
        esAdmin: esAdmin,
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      _filtroEstados = result.estados;
      _filtroClienteId = result.clienteId;
      _filtroClienteNombre = result.clienteNombre;
    });
    if (!mounted) return;
    context
        .read<VentasProvider>()
        .cargar(filtro: FiltroVentas(clienteId: result.clienteId));
  }

  Future<void> _compartirVista() async {
    setState(() => _compartiendo = true);
    await WidgetsBinding.instance.endOfFrame;
    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final uiImage = await boundary.toImage(pixelRatio: 3.0);
      final pngData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      if (pngData == null) return;

      final decoded = img.decodePng(pngData.buffer.asUint8List());
      if (decoded == null) return;
      final jpegBytes = img.encodeJpg(decoded, quality: 92);

      final nombre = _filtroClienteNombre?.replaceAll(' ', '_') ?? 'ventas';
      await Share.shareXFiles([
        XFile.fromData(
          jpegBytes,
          name: 'ventas_$nombre.jpg',
          mimeType: 'image/jpeg',
        ),
      ]);
    } finally {
      if (mounted) setState(() => _compartiendo = false);
    }
  }

  Widget _buildLista(
    BuildContext context,
    VentasProvider ventasProvider,
    bool esAdmin,
  ) {
    if (ventasProvider.cargando) {
      return EstadoCargando(avisoServidorLento: ventasProvider.avisoServidorLento);
    }
    if (ventasProvider.error != null) {
      return EstadoError(
        mensaje: ventasProvider.error!,
        onReintentar: () => ventasProvider.cargar(),
      );
    }

    final ventas = ventasProvider.ventas
        .where((v) => _filtroEstados.isEmpty || _filtroEstados.contains(v.estado))
        .toList();

    if (ventas.isEmpty) {
      return const Center(child: Text('No hay ventas para mostrar.'));
    }

    final totalPorPagar = _filtroClienteId != null
        ? ventas
            .where((v) => v.estado != EstadoVenta.CANCELADO)
            .fold<double>(0, (sum, v) => sum + v.saldoPendiente)
        : null;

    // Precalcular resumen por día: { día → (cantidad, total) }
    final resumenPorDia = <DateTime, ({int cantidad, double total})>{};
    for (final v in ventas) {
      final dia = DateTime(v.fecha.year, v.fecha.month, v.fecha.day);
      final prev = resumenPorDia[dia];
      resumenPorDia[dia] = prev == null
          ? (cantidad: 1, total: v.total)
          : (cantidad: prev.cantidad + 1, total: prev.total + v.total);
    }

    final items = <Object>[];
    DateTime? diaActual;
    for (final venta in ventas) {
      final dia = DateTime(venta.fecha.year, venta.fecha.month, venta.fecha.day);
      if (diaActual == null || dia != diaActual) {
        items.add(dia);
        diaActual = dia;
      }
      items.add(venta);
    }

    return RefreshIndicator(
      onRefresh: () => ventasProvider.cargar(forzar: true),
      child: ListView.builder(
        itemCount: items.length + (totalPorPagar != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (totalPorPagar != null && index == 0) {
            return _ResumenCliente(
              nombre: _filtroClienteNombre ?? 'Cliente',
              totalPorPagar: totalPorPagar,
            );
          }
          final realIndex = index - (totalPorPagar != null ? 1 : 0);
          final item = items[realIndex];
          if (item is DateTime) {
            final resumen = resumenPorDia[item]!;
            final labelCantidad = resumen.cantidad == 1 ? '1 orden' : '${resumen.cantidad} órdenes';
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  Text(
                    _etiquetaFecha(item),
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$labelCantidad · ${formatPrecio(resumen.total)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }
          final venta = item as Venta;
          return Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 5, color: _colorEstado(venta.estado)),
                    Expanded(
                      child: ListTile(
                        title: Text(
                            venta.cliente?.nombre ?? 'Cliente #${venta.clienteId}'),
                        subtitle: Text(
                          esAdmin
                              ? '${venta.vendedor?.nombre ?? ''} · ${estadoLabel(venta.estado)}'
                              : estadoLabel(venta.estado),
                        ),
                        trailing: venta.estado == EstadoVenta.PAGO_PARCIAL
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatPrecio(venta.saldoPendiente),
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    'restante',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: const Color(0xFF7B5EA7)),
                                  ),
                                ],
                              )
                            : Text(
                                formatPrecio(venta.total),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DetalleVentaScreen(ventaId: venta.id),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ventasProvider = context.watch<VentasProvider>();
    final esAdmin =
        context.watch<AuthProvider>().usuario?.rol == Rol.ADMIN;
    final titulo = esAdmin ? 'Ventas' : 'Mis ventas';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          if (_filtroClienteId != null)
            _compartiendo
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.share_outlined),
                    tooltip: 'Compartir como imagen',
                    onPressed: _compartirVista,
                  ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_alt_outlined),
                tooltip: 'Filtrar',
                onPressed: _abrirFiltros,
              ),
              if (_hayFiltros)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _captureKey,
        child: _buildLista(context, ventasProvider, esAdmin),
      ),
    );
  }
}

// ── Resumen por cliente ───────────────────────────────────────────────────────

class _ResumenCliente extends StatelessWidget {
  final String nombre;
  final double totalPorPagar;

  const _ResumenCliente({required this.nombre, required this.totalPorPagar});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hayDeuda = totalPorPagar > 0;
    final color = hayDeuda ? cs.primary : cs.secondary;
    final colorContainer = hayDeuda ? cs.primaryContainer : cs.secondaryContainer;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Card(
        color: colorContainer.withValues(alpha: 0.45),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                hayDeuda ? Icons.account_balance_wallet_outlined : Icons.check_circle_outline,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nombre,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatPrecio(totalPorPagar),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    hayDeuda ? 'por pagar' : 'al día',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: color,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sheet de filtros ──────────────────────────────────────────────────────────

class _FiltroSheet extends StatefulWidget {
  final Set<EstadoVenta> estadosActuales;
  final int? clienteIdActual;
  final String? clienteNombreActual;
  final List<Cliente> clientes;
  final bool esAdmin;

  const _FiltroSheet({
    required this.estadosActuales,
    required this.clienteIdActual,
    required this.clienteNombreActual,
    required this.clientes,
    required this.esAdmin,
  });

  @override
  State<_FiltroSheet> createState() => _FiltroSheetState();
}

class _FiltroSheetState extends State<_FiltroSheet> {
  late Set<EstadoVenta> _estados;
  int? _clienteId;
  String? _clienteNombre;
  final _searchController = TextEditingController();
  List<Cliente> _filtrados = [];

  @override
  void initState() {
    super.initState();
    _estados = Set.from(widget.estadosActuales);
    _clienteId = widget.clienteIdActual;
    _clienteNombre = widget.clienteNombreActual;
    _filtrados = widget.clientes;
    _searchController.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrar() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtrados = q.isEmpty
          ? widget.clientes
          : widget.clientes
                .where((c) => c.nombre.toLowerCase().contains(q))
                .toList();
    });
  }

  void _aplicar() {
    Navigator.of(context).pop((
      estados: _estados,
      clienteId: _clienteId,
      clienteNombre: _clienteNombre,
    ));
  }

  void _limpiar() {
    Navigator.of(context).pop((
      estados: <EstadoVenta>{},
      clienteId: null,
      clienteNombre: null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: widget.esAdmin ? 0.75 : 0.45,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filtros',
                      style: Theme.of(context).textTheme.titleMedium),
                  TextButton(
                    onPressed: _limpiar,
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  // ── Estado ──
                  Text('Estado',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Todos'),
                        selected: _estados.isEmpty,
                        onSelected: (_) => setState(() => _estados.clear()),
                      ),
                      ...EstadoVenta.values.map(
                        (e) => FilterChip(
                          label: Text(estadoLabel(e)),
                          selected: _estados.contains(e),
                          selectedColor: _colorEstado(e).withValues(alpha: 0.18),
                          checkmarkColor: _colorEstado(e),
                          labelStyle: _estados.contains(e)
                              ? TextStyle(color: _colorEstado(e))
                              : null,
                          onSelected: (_) => setState(() {
                            if (_estados.contains(e)) {
                              _estados.remove(e);
                            } else {
                              _estados.add(e);
                            }
                          }),
                        ),
                      ),
                    ],
                  ),

                  // ── Cliente (solo admin) ──
                  if (widget.esAdmin) ...[
                    const SizedBox(height: 20),
                    Text('Cliente',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar cliente…',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // "Todos" chip
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Radio<int?>(
                        value: null,
                        groupValue: _clienteId,
                        onChanged: (v) => setState(() {
                          _clienteId = null;
                          _clienteNombre = null;
                        }),
                      ),
                      title: const Text('Todos los clientes'),
                      onTap: () => setState(() {
                        _clienteId = null;
                        _clienteNombre = null;
                      }),
                    ),
                    ..._filtrados.map(
                      (c) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Radio<int?>(
                          value: c.id,
                          groupValue: _clienteId,
                          onChanged: (v) => setState(() {
                            _clienteId = c.id;
                            _clienteNombre = c.nombre;
                          }),
                        ),
                        title: Text(c.nombre),
                        subtitle: c.telefono != null ? Text(c.telefono!) : null,
                        onTap: () => setState(() {
                          _clienteId = c.id;
                          _clienteNombre = c.nombre;
                        }),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: FilledButton(
                onPressed: _aplicar,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                child: const Text('Aplicar filtros'),
              ),
            ),
          ],
        );
      },
    );
  }
}
