class Cliente {
  final int id;
  final String nombre;
  final String? telefono;
  final String? notas;
  final DateTime? creadoEn;

  Cliente({
    required this.id,
    required this.nombre,
    this.telefono,
    this.notas,
    this.creadoEn,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String?,
      notas: json['notas'] as String?,
      creadoEn: json['creadoEn'] != null ? DateTime.parse(json['creadoEn'] as String).toLocal() : null,
    );
  }
}

class ProductoMasComprado {
  final String nombre;
  final double cantidad;

  ProductoMasComprado({required this.nombre, required this.cantidad});

  factory ProductoMasComprado.fromJson(Map<String, dynamic> json) {
    return ProductoMasComprado(
      nombre: json['nombre'] as String,
      cantidad: (json['cantidad'] as num).toDouble(),
    );
  }
}

class DetalleCliente {
  final Cliente cliente;
  final int cantidadVentas;
  final double totalComprado;
  final double ticketPromedio;
  final double saldoPendiente;
  final DateTime? primeraCompra;
  final DateTime? ultimaCompra;
  final ProductoMasComprado? productoMasComprado;

  DetalleCliente({
    required this.cliente,
    required this.cantidadVentas,
    required this.totalComprado,
    required this.ticketPromedio,
    required this.saldoPendiente,
    this.primeraCompra,
    this.ultimaCompra,
    this.productoMasComprado,
  });

  factory DetalleCliente.fromJson(Map<String, dynamic> json) {
    return DetalleCliente(
      cliente: Cliente.fromJson(json['cliente'] as Map<String, dynamic>),
      cantidadVentas: json['cantidadVentas'] as int,
      totalComprado: (json['totalComprado'] as num).toDouble(),
      ticketPromedio: (json['ticketPromedio'] as num).toDouble(),
      saldoPendiente: (json['saldoPendiente'] as num).toDouble(),
      primeraCompra: json['primeraCompra'] != null
          ? DateTime.parse(json['primeraCompra'] as String).toLocal()
          : null,
      ultimaCompra: json['ultimaCompra'] != null
          ? DateTime.parse(json['ultimaCompra'] as String).toLocal()
          : null,
      productoMasComprado: json['productoMasComprado'] != null
          ? ProductoMasComprado.fromJson(json['productoMasComprado'] as Map<String, dynamic>)
          : null,
    );
  }
}
