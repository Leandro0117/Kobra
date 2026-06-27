import 'dart:async';
import '../config/api_config.dart';

/// Mixin para providers que hacen llamadas HTTP: si la petición tarda más
/// que [ApiConfig.umbralServidorDormido] (Render free tier "dormido"),
/// activa [avisoServidorLento] para que la UI cambie el mensaje de carga.
mixin CargaLentaMixin {
  bool avisoServidorLento = false;
  Timer? _timer;

  void iniciarAvisoServidorLento(void Function() notificar) {
    avisoServidorLento = false;
    _timer?.cancel();
    _timer = Timer(ApiConfig.umbralServidorDormido, () {
      avisoServidorLento = true;
      notificar();
    });
  }

  void detenerAvisoServidorLento() {
    _timer?.cancel();
    avisoServidorLento = false;
  }
}
