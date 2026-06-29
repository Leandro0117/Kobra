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
      creadoEn: json['creadoEn'] != null ? DateTime.parse(json['creadoEn'] as String) : null,
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
  final ProductoMasComprado? productoMasComprado;

  DetalleCliente({
    required this.cliente,
    required this.cantidadVentas,
    required this.totalComprado,
    this.productoMasComprado,
  });

  factory DetalleCliente.fromJson(Map<String, dynamic> json) {
    return DetalleCliente(
      cliente: Cliente.fromJson(json['cliente'] as Map<String, dynamic>),
      cantidadVentas: json['cantidadVentas'] as int,
      totalComprado: (json['totalComprado'] as num).toDouble(),
      productoMasComprado: json['productoMasComprado'] != null
          ? ProductoMasComprado.fromJson(json['productoMasComprado'] as Map<String, dynamic>)
          : null,
    );
  }
}
