class AsignacionAhorro {
  int? id;
  int montoAsignadoCents;
  int transaccionId;
  int fondoId;

  AsignacionAhorro({this.id, required double montoAsignado, required this.transaccionId, required this.fondoId})
      : montoAsignadoCents = (montoAsignado * 100).round();

  double get montoAsignado => montoAsignadoCents / 100.0;

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'monto_asignado': montoAsignadoCents / 100.0,
      'monto_asignado_cents': montoAsignadoCents,
      'transaccion_id': transaccionId,
      'fondo_id': fondoId,
    };
    if (id != null) m['asignacion_id'] = id;
    return m;
  }

  factory AsignacionAhorro.fromMap(Map<String, dynamic> map) {
    int cents;
    if (map.containsKey('monto_asignado_cents') && map['monto_asignado_cents'] != null) {
      cents = (map['monto_asignado_cents'] as num).toInt();
    } else {
      final real = (map['monto_asignado'] as num?)?.toDouble() ?? 0.0;
      cents = (real * 100).round();
    }

    return AsignacionAhorro(
      id: (map['asignacion_id'] as num?)?.toInt(),
      montoAsignado: cents / 100.0,
      transaccionId: (map['transaccion_id'] as num).toInt(),
      fondoId: (map['fondo_id'] as num).toInt(),
    );
  }
}
