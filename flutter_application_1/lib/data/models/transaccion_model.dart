class Transaccion {
  int? id;
  String fecha; // ISO-8601 string
  double monto;
  String? descripcion;
  int cuentaId;
  int? subcategoriaId;
  int? miembroId;
  String tipo; // 'Ingreso' | 'Egreso'

  Transaccion({
    this.id,
    required this.fecha,
    required this.monto,
    this.descripcion,
    required this.cuentaId,
    this.subcategoriaId,
    this.miembroId,
    required this.tipo,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'fecha': fecha,
      'monto': monto,
      'descripcion': descripcion,
      'cuenta_id': cuentaId,
      'subcategoria_id': subcategoriaId,
      'miembro_id': miembroId,
      'tipo': tipo,
    };
    if (id != null) map['transaccion_id'] = id;
    return map;
  }

  factory Transaccion.fromMap(Map<String, dynamic> map) => Transaccion(
        id: map['transaccion_id'] as int?,
        fecha: map['fecha'] as String,
        monto: (map['monto'] as num).toDouble(),
        descripcion: map['descripcion'] as String?,
        cuentaId: map['cuenta_id'] as int,
        subcategoriaId: map['subcategoria_id'] as int?,
        miembroId: map['miembro_id'] as int?,
        tipo: map['tipo'] as String,
      );
}
