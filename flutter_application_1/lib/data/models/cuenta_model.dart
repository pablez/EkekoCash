class Cuenta {
  int? id;
  String nombre;
  /// Internal storage in cents
  int saldoCents;
  String? tipoMoneda;

  Cuenta({this.id, required this.nombre, double saldoInicial = 0.0, this.tipoMoneda}) : saldoCents = (saldoInicial * 100).round();

  /// Getter for compatibility
  double get saldoInicial => saldoCents / 100.0;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nombre': nombre,
      // keep legacy field
      'saldo_inicial': saldoCents / 100.0,
      'saldo_cents': saldoCents,
      'tipo_moneda': tipoMoneda,
    };
    if (id != null) map['cuenta_id'] = id;
    return map;
  }

  factory Cuenta.fromMap(Map<String, dynamic> map) {
    int cents;
    final saldoCentsRaw = map['saldo_cents'];
    if (saldoCentsRaw != null) {
      if (saldoCentsRaw is num) {
        cents = saldoCentsRaw.toInt();
      } else {
        cents = int.tryParse(saldoCentsRaw.toString()) ?? 0;
      }
    } else {
      final real = (map['saldo_inicial'] as num?)?.toDouble() ?? 0.0;
      cents = (real * 100).round();
    }
    final id = (map['cuenta_id'] as num?)?.toInt();
    final nombre = map['nombre'] as String?;
    if (nombre == null) throw StateError('Cuenta missing nombre: $map');
    return Cuenta(
      id: id,
      nombre: nombre,
      saldoInicial: cents / 100.0,
      tipoMoneda: map['tipo_moneda'] as String?,
    );
  }
}
