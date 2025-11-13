import '../db_provider.dart';
import '../models/categoria_model.dart';

class CategoriaRepository {
  Future<List<Categoria>> getAllCategorias() async {
    final db = await DBProvider.database;
    final maps = await db.query('categorias', orderBy: 'categoria_id');
    return maps.map((m) => Categoria.fromMap(m)).toList();
  }

  Future<int> insertCategoria(Categoria c) async {
    final db = await DBProvider.database;
    return await db.insert('categorias', c.toMap());
  }
}
