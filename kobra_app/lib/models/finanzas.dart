import 'categoria_gasto.dart';

class ResumenCategoriaGasto {
  final CategoriaGasto categoria;
  final double total;

  ResumenCategoriaGasto({required this.categoria, required this.total});

  factory ResumenCategoriaGasto.fromJson(Map<String, dynamic> json) {
    return ResumenCategoriaGasto(
      categoria: categoriaGastoFromString(json['categoria'] as String),
      total: (json['total'] as num).toDouble(),
    );
  }
}

class ResumenMedioPago {
  final String nombre;
  final double total;
  final int cantidadVentas;

  ResumenMedioPago({
    required this.nombre,
    required this.total,
    required this.cantidadVentas,
  });

  factory ResumenMedioPago.fromJson(Map<String, dynamic> json) {
    return ResumenMedioPago(
      nombre: json['nombre'] as String,
      total: (json['total'] as num).toDouble(),
      cantidadVentas: json['cantidadVentas'] as int,
    );
  }
}

class ResumenFinanzas {
  final double totalCobrado;
  final double porCobrar;
  final double totalEgresos;
  final double balance;
  final List<ResumenCategoriaGasto> egresosPorCategoria;
  final List<ResumenMedioPago> mediosPago;

  ResumenFinanzas({
    required this.totalCobrado,
    required this.porCobrar,
    required this.totalEgresos,
    required this.balance,
    required this.egresosPorCategoria,
    required this.mediosPago,
  });

  factory ResumenFinanzas.fromJson(Map<String, dynamic> json) {
    return ResumenFinanzas(
      totalCobrado: (json['totalCobrado'] as num).toDouble(),
      porCobrar: (json['porCobrar'] as num).toDouble(),
      totalEgresos: (json['totalEgresos'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      egresosPorCategoria: (json['egresosPorCategoria'] as List)
          .map((c) => ResumenCategoriaGasto.fromJson(c as Map<String, dynamic>))
          .toList(),
      mediosPago: (json['mediosPago'] as List? ?? [])
          .map((m) => ResumenMedioPago.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
