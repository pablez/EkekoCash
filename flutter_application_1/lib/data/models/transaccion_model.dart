class Transaccion {
  int? id;
  String fecha; // ISO-8601 string
  /// Amount stored internally as integer cents.
  int montoCents;
  String? descripcion;
  int cuentaId;
  int? subcategoriaId;
  int? categoriaId;
  int? miembroId;
  String tipo; // 'Ingreso' | 'Egreso'

  /// Constructor accepts a `monto` in double (e.g. 12.34) and stores as cents.
  Transaccion({
    this.id,
    required this.fecha,
    required double monto,
    this.descripcion,
    required this.cuentaId,
    this.subcategoriaId,
    this.categoriaId,
    this.miembroId,
    required this.tipo,
  }) : montoCents = (monto * 100).round();

  /// Getter for convenience (display value in units)
  double get monto => montoCents / 100.0;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'fecha': fecha,
      // Keep legacy 'monto' (REAL) for compatibility; also store 'monto_cents' (INT)
      'monto': montoCents / 100.0,
      'monto_cents': montoCents,
      'descripcion': descripcion,
      'cuenta_id': cuentaId,
      'subcategoria_id': subcategoriaId,
      'categoria_id': categoriaId,
      'miembro_id': miembroId,
      'tipo': tipo,
    };
    if (id != null) map['transaccion_id'] = id;
    return map;
  }

  factory Transaccion.fromMap(Map<String, dynamic> map) {
    // Prefer monto_cents if present (new schema). Fallback to old 'monto' REAL.
    int cents;
    if (map.containsKey('monto_cents') && map['monto_cents'] != null) {
      final v = map['monto_cents'];
      if (v is num) {
        cents = v.toInt();
      } else {
        throw StateError('Invalid monto_cents value: $v');
      }
    } else {
      final realMonto = (map['monto'] as num?)?.toDouble() ?? 0.0;
      cents = (realMonto * 100).round();
    }

    // Required fields validation with helpful errors
    final fecha = map['fecha'] as String?;
    if (fecha == null) throw StateError('Transaccion missing fecha: $map');

    final tipo = map['tipo'] as String?;
    if (tipo == null) throw StateError('Transaccion missing tipo: $map');

    final cuentaRaw = map['cuenta_id'];
    if (cuentaRaw == null) throw StateError('Transaccion missing cuenta_id: $map');
    final cuentaId = (cuentaRaw is num) ? cuentaRaw.toInt() : int.tryParse(cuentaRaw.toString());
    if (cuentaId == null) throw StateError('Invalid cuenta_id: $cuentaRaw');

    final subcategoriaRaw = map['subcategoria_id'];
    final subcategoriaId = (subcategoriaRaw is num) ? subcategoriaRaw.toInt() : (subcategoriaRaw == null ? null : int.tryParse(subcategoriaRaw.toString()));

    final categoriaRaw = map['categoria_id'];
    final categoriaId = (categoriaRaw is num) ? categoriaRaw.toInt() : (categoriaRaw == null ? null : int.tryParse(categoriaRaw.toString()));

    final miembroRaw = map['miembro_id'];
    final miembroId = (miembroRaw is num) ? miembroRaw.toInt() : (miembroRaw == null ? null : int.tryParse(miembroRaw.toString()));

    return Transaccion(
      id: (map['transaccion_id'] as num?)?.toInt(),
      fecha: fecha,
      monto: cents / 100.0,
      descripcion: map['descripcion'] as String?,
      cuentaId: cuentaId,
      subcategoriaId: subcategoriaId,
      categoriaId: categoriaId,
      miembroId: miembroId,
      tipo: tipo,
    );
  }
}
