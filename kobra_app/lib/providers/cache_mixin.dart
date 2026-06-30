mixin CacheMixin {
  DateTime? _ultimaCarga;
  String? _claveCache;

  /// Devuelve true si los datos en memoria son suficientemente frescos.
  /// [clave] diferencia resultados por filtro/periodo; si cambia, el cache
  /// se considera inválido aunque no haya expirado el TTL.
  bool cacheVigente(Duration ttl, {String? clave}) {
    if (_ultimaCarga == null) return false;
    if (clave != null && clave != _claveCache) return false;
    return DateTime.now().difference(_ultimaCarga!) < ttl;
  }

  void marcarCargado({String? clave}) {
    _ultimaCarga = DateTime.now();
    _claveCache = clave;
  }

  void invalidarCache() => _ultimaCarga = null;
}
