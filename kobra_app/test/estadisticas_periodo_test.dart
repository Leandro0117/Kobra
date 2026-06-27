import 'package:flutter_test/flutter_test.dart';
import 'package:kobra_app/models/estadisticas.dart';

void main() {
  group('rangoDePeriodo', () {
    // Sábado 27 de junio de 2026 a media tarde, como referencia fija de "ahora".
    final ahora = DateTime(2026, 6, 27, 15, 30);

    test('todo no aplica filtro', () {
      final (desde, hasta) = rangoDePeriodo(PeriodoEstadisticas.todo, ahora);
      expect(desde, isNull);
      expect(hasta, isNull);
    });

    test('hoy cubre desde medianoche hasta el final del día', () {
      final (desde, hasta) = rangoDePeriodo(PeriodoEstadisticas.hoy, ahora);
      expect(desde, DateTime(2026, 6, 27));
      expect(hasta, DateTime(2026, 6, 27, 23, 59, 59, 999));
    });

    test('estaSemana empieza el lunes de esta semana', () {
      final (desde, hasta) = rangoDePeriodo(PeriodoEstadisticas.estaSemana, ahora);
      expect(desde!.weekday, DateTime.monday);
      expect(desde.isBefore(ahora) || desde.isAtSameMomentAs(ahora), true);
      expect(hasta, DateTime(2026, 6, 27, 23, 59, 59, 999));
    });

    test('semanaPasada es la semana completa anterior, sin solaparse con esta semana', () {
      final (desdeEstaSemana, _) = rangoDePeriodo(PeriodoEstadisticas.estaSemana, ahora);
      final (desde, hasta) = rangoDePeriodo(PeriodoEstadisticas.semanaPasada, ahora);
      expect(desde!.weekday, DateTime.monday);
      expect(hasta!.weekday, DateTime.sunday);
      expect(hasta.isBefore(desdeEstaSemana!), true);
      expect(hasta.difference(desde).inDays, 6);
    });

    test('esteMes empieza el día 1 del mes actual', () {
      final (desde, hasta) = rangoDePeriodo(PeriodoEstadisticas.esteMes, ahora);
      expect(desde, DateTime(2026, 6, 1));
      expect(hasta, DateTime(2026, 6, 27, 23, 59, 59, 999));
    });

    test('mesPasado cubre todo mayo cuando ahora es junio', () {
      final (desde, hasta) = rangoDePeriodo(PeriodoEstadisticas.mesPasado, ahora);
      expect(desde, DateTime(2026, 5, 1));
      expect(hasta, DateTime(2026, 5, 31, 23, 59, 59, 999));
    });

    test('mesPasado cruza de año cuando ahora es enero', () {
      final eneroDe2026 = DateTime(2026, 1, 15);
      final (desde, hasta) = rangoDePeriodo(PeriodoEstadisticas.mesPasado, eneroDe2026);
      expect(desde, DateTime(2025, 12, 1));
      expect(hasta, DateTime(2025, 12, 31, 23, 59, 59, 999));
    });

    test('esteAnio empieza el 1 de enero del año actual', () {
      final (desde, hasta) = rangoDePeriodo(PeriodoEstadisticas.esteAnio, ahora);
      expect(desde, DateTime(2026, 1, 1));
      expect(hasta, DateTime(2026, 6, 27, 23, 59, 59, 999));
    });

    test('anioPasado cubre el año calendario anterior completo', () {
      final (desde, hasta) = rangoDePeriodo(PeriodoEstadisticas.anioPasado, ahora);
      expect(desde, DateTime(2025, 1, 1));
      expect(hasta, DateTime(2025, 12, 31, 23, 59, 59, 999));
    });

    test('ultimoAnio es una ventana móvil de 365 días hacia atrás', () {
      final (desde, hasta) = rangoDePeriodo(PeriodoEstadisticas.ultimoAnio, ahora);
      expect(hasta, DateTime(2026, 6, 27, 23, 59, 59, 999));
      expect(ahora.difference(desde!).inDays, 365);
    });
  });
}
