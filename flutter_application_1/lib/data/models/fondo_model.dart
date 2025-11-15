class Fondo {
  int? id;
  String nombre;
  /// meta_monto stored as cents internally
  int metaMontoCents;
  String? fechaMeta;
  int? iconoId;

  Fondo({this.id, required this.nombre, required double metaMonto, this.fechaMeta, this.iconoId})
      : metaMontoCents = (metaMonto * 100).round();

  double get metaMonto => metaMontoCents / 100.0;

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'nombre': nombre,
      'meta_monto': metaMontoCents / 100.0,
      'meta_monto_cents': metaMontoCents,
      'fecha_meta': fechaMeta,
      'icono_id': iconoId,
    };
    if (id != null) m['fondo_id'] = id;
    return m;
  }

  factory Fondo.fromMap(Map<String, dynamic> map) {
    int cents;
    if (map.containsKey('meta_monto_cents') && map['meta_monto_cents'] != null) {
      cents = (map['meta_monto_cents'] as num).toInt();
    } else {
      final real = (map['meta_monto'] as num?)?.toDouble() ?? 0.0;
      cents = (real * 100).round();
    }

    return Fondo(
      id: (map['fondo_id'] as num?)?.toInt(),
      nombre: map['nombre'] as String? ?? '',
      metaMonto: cents / 100.0,
      fechaMeta: map['fecha_meta'] as String?,
      iconoId: (map['icono_id'] as num?)?.toInt(),
    );
  }
}
