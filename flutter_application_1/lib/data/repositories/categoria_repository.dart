import 'package:sqflite/sqflite.dart';
import '../db_provider.dart';
import '../models/categoria_model.dart';
import '../models/transaccion_model.dart';

class CategoriaRepository {
  Future<int> insertCategoria(Categoria c) async {
    final db = await DBProvider.database;
    final payload = c.toMap();
    // Filter payload keys to existing columns to avoid errors on older DBs
    final pragma = await db.rawQuery('PRAGMA table_info(categorias)');
    final cols = pragma.map((r) => r['name'] as String).toSet();
    final filtered = <String, dynamic>{};
    payload.forEach((k, v) {
      if (cols.contains(k)) filtered[k] = v;
    });
    return await db.insert('categorias', filtered);
  }

  Future<int> updateCategoria(Categoria c) async {
    final db = await DBProvider.database;
    final payload = c.toMap();
    final pragma = await db.rawQuery('PRAGMA table_info(categorias)');
    final cols = pragma.map((r) => r['name'] as String).toSet();
    final filtered = <String, dynamic>{};
    payload.forEach((k, v) {
      if (cols.contains(k)) filtered[k] = v;
    });
    return await db.update('categorias', filtered, where: 'categoria_id = ?', whereArgs: [c.categoriaId]);
  }

  Future<int> deleteCategoria(int id) async {
    final db = await DBProvider.database;
    return await db.delete('categorias', where: 'categoria_id = ?', whereArgs: [id]);
  }

  Future<List<Categoria>> getAllCategorias({String? tipo}) async {
    final db = await DBProvider.database;
    final maps = await db.query('categorias', where: tipo != null ? 'tipo = ?' : null, whereArgs: tipo != null ? [tipo] : null, orderBy: 'nombre ASC');
    return maps.map((m) => Categoria.fromMap(m)).toList();
  }

  Future<Categoria?> getCategoriaById(int id) async {
    final db = await DBProvider.database;
    final maps = await db.query('categorias', where: 'categoria_id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Categoria.fromMap(maps.first);
  }

  Future<List<Transaccion>> getTransaccionesByCategoria(int categoriaId) async {
    final db = await DBProvider.database;
    final maps = await db.query('transacciones', where: 'categoria_id = ?', whereArgs: [categoriaId], orderBy: 'fecha DESC');
    return maps.map((m) => Transaccion.fromMap(m)).toList();
  }
}

