import 'package:intl/intl.dart';

final _formatoFechaHora = DateFormat('dd/MM/yyyy h:mm a', 'es');
final _formatoFecha = DateFormat('dd/MM/yyyy', 'es');

/// Formatea una fecha con hora: "30/06/2026 8:03 a. m."
String formatFechaHora(DateTime fecha) => _formatoFechaHora.format(fecha);

/// Formatea solo la fecha: "30/06/2026"
String formatFecha(DateTime fecha) => _formatoFecha.format(fecha);

/// Formatea un monto numérico con separador de miles (punto) y, si tiene
/// decimales significativos, los muestra con coma. Ejemplos:
///   1000.0   → "1.000"
///   1500.5   → "1.500,50"
///   999.99   → "999,99"
///   5000000  → "5.000.000"
String formatMonto(double valor) {
  final esEntero = valor == valor.truncateToDouble();
  final patron = esEntero ? '#,##0' : '#,##0.00';
  return NumberFormat(patron, 'es').format(valor);
}

/// Igual que [formatMonto] pero antepone el símbolo de moneda "$".
String formatPrecio(double valor) => '\$${formatMonto(valor)}';
