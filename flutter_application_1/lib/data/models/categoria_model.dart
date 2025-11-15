class Categoria {
  final int? categoriaId;
  final String nombre;
  final String tipo; // 'Ingreso' | 'Egreso'
  final String? colorHex;
  final String? iconName;
  final DateTime? createdAt;

  // Backwards-compatible constructor accepts either `id` or `categoriaId`.
  Categoria({
    int? id,
    int? categoriaId,
    required this.nombre,
    required this.tipo,
    this.colorHex,
    this.iconName,
    this.createdAt,
  }) : categoriaId = categoriaId ?? id;

  // Legacy alias used across the codebase/tests
  int? get id => categoriaId;

  factory Categoria.fromMap(Map<String, dynamic> m) => Categoria(
        categoriaId: m['categoria_id'] as int?,
        nombre: m['nombre'] as String,
        tipo: m['tipo'] as String,
        colorHex: m['color_hex'] as String?,
        iconName: m['icon_name'] as String?,
        createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : null,
      );

  Map<String, dynamic> toMap() => {
      if (categoriaId != null) 'categoria_id': categoriaId,
        'nombre': nombre,
        'tipo': tipo,
        if (colorHex != null) 'color_hex': colorHex,
        if (iconName != null) 'icon_name': iconName,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}

// Backwards-compatible alias
typedef CategoriaModel = Categoria;
