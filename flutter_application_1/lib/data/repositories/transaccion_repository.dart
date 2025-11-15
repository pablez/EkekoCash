import '../../domain/repositories/i_transaccion_repository.dart';
import '../models/transaccion_model.dart';
import '../db_provider.dart';
import 'package:flutter/foundation.dart';

class TransaccionRepository implements ITransaccionRepository {
  TransaccionRepository();

  @override
  Future<int> insertTransaccion(Transaccion t) async {
    final db = await DBProvider.database;
    // Use a transaction: insert transaccion and update cuenta saldo
    final payload = t.toMap();

    // Basic validation to catch missing required fields early
    if (!payload.containsKey('monto') || payload['monto'] == null) {
      throw StateError('Transaccion payload missing monto: $payload');
    }
    if (!payload.containsKey('monto_cents') || payload['monto_cents'] == null) {
      throw StateError('Transaccion payload missing monto_cents: $payload');
    }

    try {
      return await db.transaction<int>((txn) async {
        final id = await txn.insert('transacciones', payload);

        // Ajustar saldo de cuenta (trabajando en centavos internamente)
        final cuentaRes = await txn.query('cuentas', where: 'cuenta_id = ?', whereArgs: [t.cuentaId]);
        if (cuentaRes.isNotEmpty) {
          final row = cuentaRes.first;
          int currentCents;
          if (row.containsKey('saldo_cents') && row['saldo_cents'] != null) {
            currentCents = (row['saldo_cents'] as num).toInt();
          } else {
            final currentDouble = (row['saldo_inicial'] as num).toDouble();
            currentCents = (currentDouble * 100).round();
          }
          final deltaCents = ((t.monto) * 100 * (t.tipo == 'Ingreso' ? 1 : -1)).round();
          final updatedCents = currentCents + deltaCents;
          final updatedDouble = updatedCents / 100.0;
          await txn.update('cuentas', {'saldo_inicial': updatedDouble, 'saldo_cents': updatedCents}, where: 'cuenta_id = ?', whereArgs: [t.cuentaId]);
        }

        return id;
      });
    } catch (e, st) {
      // Print detailed context to logs to help identify the SQL error (the real SQL message
      // is wrapped by sqflite; printing the exception and stack should surface it in logcat)
      print('ERROR insertTransaccion: exception=$e');
      print('Payload: $payload');
      print('Stack: $st');
      rethrow;
    }
  }

  @override
  Future<List<Transaccion>> getAllTransacciones() async {
    final db = await DBProvider.database;
    final maps = await db.query('transacciones', orderBy: 'fecha DESC');
    // Perform Map->Model conversion in a background isolate to avoid UI jank
    return await compute(_mapsToTransacciones, maps);
  }

  @override
  Future<void> deleteAll() async {
    final db = await DBProvider.database;
    await db.delete('transacciones');
  }

  /// Elimina una transacción por id y ajusta el saldo de la cuenta asociada.
  @override
  Future<void> deleteTransaccion(int id) async {
    final db = await DBProvider.database;
    await db.transaction((txn) async {
      final maps = await txn.query('transacciones', where: 'transaccion_id = ?', whereArgs: [id]);
      if (maps.isEmpty) return;
      final t = Transaccion.fromMap(maps.first);

      // eliminar la transacción
      await txn.delete('transacciones', where: 'transaccion_id = ?', whereArgs: [id]);

      // ajustar saldo de cuenta: si era Ingreso, restar monto; si Egreso, sumar monto (usar centavos)
      final cuentaRes = await txn.query('cuentas', where: 'cuenta_id = ?', whereArgs: [t.cuentaId]);
      if (cuentaRes.isNotEmpty) {
        final row = cuentaRes.first;
        int currentCents;
        if (row.containsKey('saldo_cents') && row['saldo_cents'] != null) {
          currentCents = (row['saldo_cents'] as num).toInt();
        } else {
          final currentDouble = (row['saldo_inicial'] as num).toDouble();
          currentCents = (currentDouble * 100).round();
        }
        final deltaCents = ((t.monto) * 100 * (t.tipo == 'Ingreso' ? -1 : 1)).round();
        final updatedCents = currentCents + deltaCents;
        final updatedDouble = updatedCents / 100.0;
        await txn.update('cuentas', {'saldo_inicial': updatedDouble, 'saldo_cents': updatedCents}, where: 'cuenta_id = ?', whereArgs: [t.cuentaId]);
      }
    });
  }
}

// Helper for compute() - must be top-level
List<Transaccion> _mapsToTransacciones(List<Map<String, dynamic>> maps) {
  return maps.map((m) => Transaccion.fromMap(m)).toList();
}
