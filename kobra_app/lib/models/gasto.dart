import 'proveedor.dart';
import 'detalle_gasto.dart';
import 'categoria_gasto.dart';

class UsuarioResumen {
  final int id;
  final String nombre;
  final String email;

  UsuarioResumen({required this.id, required this.nombre, required this.email});

  factory UsuarioResumen.fromJson(Map<String, dynamic> json) {
    return UsuarioResumen(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
    );
  }
}

class Gasto {
  final int id;
  final int usuarioId;
  final int proveedorId;
  final CategoriaGasto categoria;
  final DateTime fecha;
  final double total;
  final Proveedor? proveedor;
  final UsuarioResumen? usuario;
  final List<DetalleGasto> detalles;

  Gasto({
    required this.id,
    required this.usuarioId,
    required this.proveedorId,
    required this.categoria,
    required this.fecha,
    required this.total,
    this.proveedor,
    this.usuario,
    this.detalles = const [],
  });

  factory Gasto.fromJson(Map<String, dynamic> json) {
    return Gasto(
      id: json['id'] as int,
      usuarioId: json['usuarioId'] as int,
      proveedorId: json['proveedorId'] as int,
      categoria: categoriaGastoFromString(json['categoria'] as String),
      fecha: DateTime.parse(json['fecha'] as String),
      total: (json['total'] as num).toDouble(),
      proveedor: json['proveedor'] != null
          ? Proveedor.fromJson(json['proveedor'] as Map<String, dynamic>)
          : null,
      usuario: json['usuario'] != null
          ? UsuarioResumen.fromJson(json['usuario'] as Map<String, dynamic>)
          : null,
      detalles: json['detalles'] != null
          ? (json['detalles'] as List)
              .map((d) => DetalleGasto.fromJson(d as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
