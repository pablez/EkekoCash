import '../models/transaccion_model.dart';
import '../db_provider.dart';

class TransaccionRepository {
  TransaccionRepository();

  Future<int> insertTransaccion(Transaccion t) async {
    final db = await DBProvider.database;
    // Use a transaction: insert transaccion and update cuenta saldo
    return await db.transaction<int>((txn) async {
      final id = await txn.insert('transacciones', t.toMap());

      // Ajustar saldo de cuenta
      final cuentaRes = await txn.query('cuentas', where: 'cuenta_id = ?', whereArgs: [t.cuentaId]);
      if (cuentaRes.isNotEmpty) {
        final current = (cuentaRes.first['saldo_inicial'] as num).toDouble();
        final delta = t.tipo == 'Ingreso' ? t.monto : -t.monto;
        final updated = current + delta;
        await txn.update('cuentas', {'saldo_inicial': updated}, where: 'cuenta_id = ?', whereArgs: [t.cuentaId]);
      }

      return id;
    });
  }

  Future<List<Transaccion>> getAllTransacciones() async {
    final db = await DBProvider.database;
    final maps = await db.query('transacciones', orderBy: 'fecha DESC');
    return maps.map((m) => Transaccion.fromMap(m)).toList();
  }

  Future<void> deleteAll() async {
    final db = await DBProvider.database;
    await db.delete('transacciones');
  }

  /// Elimina una transacción por id y ajusta el saldo de la cuenta asociada.
  Future<void> deleteTransaccion(int id) async {
    final db = await DBProvider.database;
    await db.transaction((txn) async {
      final maps = await txn.query('transacciones', where: 'transaccion_id = ?', whereArgs: [id]);
      if (maps.isEmpty) return;
      final t = Transaccion.fromMap(maps.first);

      // eliminar la transacción
      await txn.delete('transacciones', where: 'transaccion_id = ?', whereArgs: [id]);

      // ajustar saldo de cuenta: si era Ingreso, restar monto; si Egreso, sumar monto
      final cuentaRes = await txn.query('cuentas', where: 'cuenta_id = ?', whereArgs: [t.cuentaId]);
      if (cuentaRes.isNotEmpty) {
        final current = (cuentaRes.first['saldo_inicial'] as num).toDouble();
        final delta = t.tipo == 'Ingreso' ? -t.monto : t.monto;
        final updated = current + delta;
        await txn.update('cuentas', {'saldo_inicial': updated}, where: 'cuenta_id = ?', whereArgs: [t.cuentaId]);
      }
    });
  }
}
