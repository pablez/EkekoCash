class Categoria {
  int? id;
  String nombre;
  String tipo; // 'Ingreso' | 'Egreso'

  Categoria({this.id, required this.nombre, required this.tipo});

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nombre': nombre,
      'tipo': tipo,
    };
    if (id != null) map['categoria_id'] = id;
    return map;
  }

  factory Categoria.fromMap(Map<String, dynamic> map) => Categoria(
        id: map['categoria_id'] as int?,
        nombre: map['nombre'] as String,
        tipo: map['tipo'] as String,
      );
}
