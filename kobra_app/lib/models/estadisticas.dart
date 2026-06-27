/// Opciones de período para filtrar las estadísticas. El rango de fechas
/// se calcula en el cliente (hora local del dispositivo) y se envía al
/// backend como `desde`/`hasta`; el backend solo filtra por rango, no
/// conoce estos presets.
enum PeriodoEstadisticas {
  todo,
  hoy,
  estaSemana,
  semanaPasada,
  esteMes,
  mesPasado,
  esteAnio,
  anioPasado,
  ultimoAnio,
}

String periodoLabel(PeriodoEstadisticas periodo) {
  switch (periodo) {
    case PeriodoEstadisticas.todo:
      return 'Todo';
    case PeriodoEstadisticas.hoy:
      return 'Hoy';
    case PeriodoEstadisticas.estaSemana:
      return 'Esta semana';
    case PeriodoEstadisticas.semanaPasada:
      return 'Semana pasada';
    case PeriodoEstadisticas.esteMes:
      return 'Este mes';
    case PeriodoEstadisticas.mesPasado:
      return 'Mes pasado';
    case PeriodoEstadisticas.esteAnio:
      return 'Este año';
    case PeriodoEstadisticas.anioPasado:
      return 'Año pasado';
    case PeriodoEstadisticas.ultimoAnio:
      return 'Último año';
  }
}

DateTime _inicioDelDia(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _finDelDia(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
DateTime _lunesDeLaSemana(DateTime d) {
  final dia = _inicioDelDia(d);
  return dia.subtract(Duration(days: dia.weekday - 1));
}

/// Calcula el rango [desde, hasta] para un período, en base a "ahora".
/// Para [PeriodoEstadisticas.todo] devuelve (null, null): sin filtro.
(DateTime?, DateTime?) rangoDePeriodo(PeriodoEstadisticas periodo, DateTime ahora) {
  switch (periodo) {
    case PeriodoEstadisticas.todo:
      return (null, null);
    case PeriodoEstadisticas.hoy:
      return (_inicioDelDia(ahora), _finDelDia(ahora));
    case PeriodoEstadisticas.estaSemana:
      return (_lunesDeLaSemana(ahora), _finDelDia(ahora));
    case PeriodoEstadisticas.semanaPasada:
      final lunesActual = _lunesDeLaSemana(ahora);
      final lunesPasado = lunesActual.subtract(const Duration(days: 7));
      final domingoPasado = lunesActual.subtract(const Duration(days: 1));
      return (lunesPasado, _finDelDia(domingoPasado));
    case PeriodoEstadisticas.esteMes:
      return (DateTime(ahora.year, ahora.month, 1), _finDelDia(ahora));
    case PeriodoEstadisticas.mesPasado:
      final primerDiaMesActual = DateTime(ahora.year, ahora.month, 1);
      final ultimoDiaMesPasado = primerDiaMesActual.subtract(const Duration(days: 1));
      final primerDiaMesPasado = DateTime(ultimoDiaMesPasado.year, ultimoDiaMesPasado.month, 1);
      return (primerDiaMesPasado, _finDelDia(ultimoDiaMesPasado));
    case PeriodoEstadisticas.esteAnio:
      return (DateTime(ahora.year, 1, 1), _finDelDia(ahora));
    case PeriodoEstadisticas.anioPasado:
      return (DateTime(ahora.year - 1, 1, 1), DateTime(ahora.year - 1, 12, 31, 23, 59, 59, 999));
    case PeriodoEstadisticas.ultimoAnio:
      return (_inicioDelDia(ahora.subtract(const Duration(days: 365))), _finDelDia(ahora));
  }
}

class ResumenCliente {
  final int clienteId;
  final String nombre;
  final int cantidadVentas;
  final double cantidadProductos;
  final double totalComprado;

  ResumenCliente({
    required this.clienteId,
    required this.nombre,
    required this.cantidadVentas,
    required this.cantidadProductos,
    required this.totalComprado,
  });

  factory ResumenCliente.fromJson(Map<String, dynamic> json) {
    return ResumenCliente(
      clienteId: json['clienteId'] as int,
      nombre: json['nombre'] as String,
      cantidadVentas: json['cantidadVentas'] as int,
      cantidadProductos: (json['cantidadProductos'] as num).toDouble(),
      totalComprado: (json['totalComprado'] as num).toDouble(),
    );
  }
}

class ResumenProducto {
  final int productoId;
  final String nombre;
  final double cantidadVendida;
  final double totalFacturado;

  ResumenProducto({
    required this.productoId,
    required this.nombre,
    required this.cantidadVendida,
    required this.totalFacturado,
  });

  factory ResumenProducto.fromJson(Map<String, dynamic> json) {
    return ResumenProducto(
      productoId: json['productoId'] as int,
      nombre: json['nombre'] as String,
      cantidadVendida: (json['cantidadVendida'] as num).toDouble(),
      totalFacturado: (json['totalFacturado'] as num).toDouble(),
    );
  }
}

class ResumenEstadisticas {
  final int totalVentas;
  final double totalFacturado;
  final List<ResumenCliente> topClientes;
  final List<ResumenProducto> topProductos;

  ResumenEstadisticas({
    required this.totalVentas,
    required this.totalFacturado,
    required this.topClientes,
    required this.topProductos,
  });

  factory ResumenEstadisticas.fromJson(Map<String, dynamic> json) {
    return ResumenEstadisticas(
      totalVentas: json['totalVentas'] as int,
      totalFacturado: (json['totalFacturado'] as num).toDouble(),
      topClientes: (json['topClientes'] as List)
          .map((c) => ResumenCliente.fromJson(c as Map<String, dynamic>))
          .toList(),
      topProductos: (json['topProductos'] as List)
          .map((p) => ResumenProducto.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}
