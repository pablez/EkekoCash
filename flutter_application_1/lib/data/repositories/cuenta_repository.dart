import '../db_provider.dart';
import '../models/cuenta_model.dart';

class CuentaRepository {
  Future<List<Cuenta>> getAllCuentas() async {
    final db = await DBProvider.database;
    final maps = await db.query('cuentas', orderBy: 'cuenta_id');
    return maps.map((m) => Cuenta.fromMap(m)).toList();
  }

  Future<Cuenta?> getCuentaById(int id) async {
    final db = await DBProvider.database;
    final maps = await db.query('cuentas', where: 'cuenta_id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Cuenta.fromMap(maps.first);
  }

  Future<void> adjustSaldo(int cuentaId, double delta) async {
    final db = await DBProvider.database;
    await db.transaction((txn) async {
      final res = await txn.query('cuentas', where: 'cuenta_id = ?', whereArgs: [cuentaId]);
      if (res.isEmpty) throw StateError('Cuenta no encontrada');
      final current = (res.first['saldo_inicial'] as num).toDouble();
      final updated = current + delta;
      await txn.update('cuentas', {'saldo_inicial': updated}, where: 'cuenta_id = ?', whereArgs: [cuentaId]);
    });
  }

  Future<int> insertCuenta(Cuenta c) async {
    final db = await DBProvider.database;
    return await db.insert('cuentas', c.toMap());
  }
}
