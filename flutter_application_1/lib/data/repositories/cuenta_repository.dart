import '../../domain/repositories/i_cuenta_repository.dart';
import '../db_provider.dart';
import '../models/cuenta_model.dart';
import 'package:flutter/foundation.dart';

class CuentaRepository implements ICuentaRepository {
  @override
  Future<List<Cuenta>> getAllCuentas() async {
    final db = await DBProvider.database;
    final maps = await db.query('cuentas', orderBy: 'cuenta_id');
    return await compute(_mapsToCuentas, maps);
  }

  @override
  Future<Cuenta?> getCuentaById(int id) async {
    final db = await DBProvider.database;
    final maps = await db.query('cuentas', where: 'cuenta_id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Cuenta.fromMap(maps.first);
  }

  @override
  Future<void> adjustSaldo(int cuentaId, double delta) async {
    final db = await DBProvider.database;
    await db.transaction((txn) async {
      final res = await txn.query('cuentas', where: 'cuenta_id = ?', whereArgs: [cuentaId]);
      if (res.isEmpty) throw StateError('Cuenta no encontrada');
      // Work with cents internally to avoid floating point issues
      int currentCents;
      final row = res.first;
      if (row.containsKey('saldo_cents') && row['saldo_cents'] != null) {
        currentCents = (row['saldo_cents'] as num).toInt();
      } else {
        final currentDouble = (row['saldo_inicial'] as num).toDouble();
        currentCents = (currentDouble * 100).round();
      }
      final deltaCents = (delta * 100).round();
      final updatedCents = currentCents + deltaCents;
      final updatedDouble = updatedCents / 100.0;
      await txn.update('cuentas', {'saldo_inicial': updatedDouble, 'saldo_cents': updatedCents}, where: 'cuenta_id = ?', whereArgs: [cuentaId]);
    });
  }

  @override
  Future<int> insertCuenta(Cuenta c) async {
    final db = await DBProvider.database;
    return await db.insert('cuentas', c.toMap());
  }
}

List<Cuenta> _mapsToCuentas(List<Map<String, dynamic>> maps) {
  return maps.map((m) => Cuenta.fromMap(m)).toList();
}
