import '../db_provider.dart';
import '../models/fondo_model.dart';
import '../models/asignacion_model.dart';
import 'package:flutter/foundation.dart';

class FondoRepository {
  FondoRepository();

  Future<int> insertFondo(Fondo f) async {
    final db = await DBProvider.database;
    return await db.insert('fondos', f.toMap());
  }

  Future<List<Fondo>> getAllFondos() async {
    final db = await DBProvider.database;
    final maps = await db.query('fondos', orderBy: 'fondo_id');
    return await compute(_mapsToFondos, maps);
  }

  Future<int> insertAsignacion(AsignacionAhorro a) async {
    final db = await DBProvider.database;
    return await db.insert('asignaciones_ahorro', a.toMap());
  }

  Future<List<AsignacionAhorro>> getAsignacionesByFondo(int fondoId) async {
    final db = await DBProvider.database;
    final maps = await db.query('asignaciones_ahorro', where: 'fondo_id = ?', whereArgs: [fondoId]);
    return maps.map((m) => AsignacionAhorro.fromMap(m)).toList();
  }

  Future<List<AsignacionAhorro>> getAsignacionesByTransaccion(int transaccionId) async {
    final db = await DBProvider.database;
    final maps = await db.query('asignaciones_ahorro', where: 'transaccion_id = ?', whereArgs: [transaccionId]);
    return maps.map((m) => AsignacionAhorro.fromMap(m)).toList();
  }

  Future<int> deleteAsignacion(int id) async {
    final db = await DBProvider.database;
    return await db.delete('asignaciones_ahorro', where: 'asignacion_id = ?', whereArgs: [id]);
  }
}

List<Fondo> _mapsToFondos(List<Map<String, dynamic>> maps) => maps.map((m) => Fondo.fromMap(m)).toList();
