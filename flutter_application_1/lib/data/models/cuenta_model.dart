class Cuenta {
  int? id;
  String nombre;
  double saldoInicial;
  String? tipoMoneda;

  Cuenta({this.id, required this.nombre, this.saldoInicial = 0.0, this.tipoMoneda});

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nombre': nombre,
      'saldo_inicial': saldoInicial,
      'tipo_moneda': tipoMoneda,
    };
    if (id != null) map['cuenta_id'] = id;
    return map;
  }

  factory Cuenta.fromMap(Map<String, dynamic> map) => Cuenta(
        id: map['cuenta_id'] as int?,
        nombre: map['nombre'] as String,
        saldoInicial: (map['saldo_inicial'] as num).toDouble(),
        tipoMoneda: map['tipo_moneda'] as String?,
      );
}
