import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_application_1/data/db_provider.dart';
import 'package:flutter_application_1/data/models/transaccion_model.dart';
import 'package:flutter_application_1/data/repositories/transaccion_repository.dart';
import 'package:flutter_application_1/data/repositories/cuenta_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Transaccion delete integrity', () {
    late TransaccionRepository repo;
    late CuentaRepository cuentaRepo;

    setUpAll(() async {
      await DBProvider.init(inMemory: true);
      repo = TransaccionRepository();
      cuentaRepo = CuentaRepository();
    });

    test('insert and delete transaction adjusts cuenta saldo', () async {
      // use seeded cuentas from DBProvider.onCreate
      final cuentas = await cuentaRepo.getAllCuentas();
      expect(cuentas, isNotEmpty);
      final cuenta = cuentas.first;

      final initial = cuenta.saldoInicial;

      final t = Transaccion(
        fecha: DateTime.now().toIso8601String(),
        monto: 100.0,
        descripcion: 'Test delete',
        cuentaId: cuenta.id!,
        tipo: 'Egreso',
      );

      final id = await repo.insertTransaccion(t);
      final afterInsertCuenta = await cuentaRepo.getCuentaById(cuenta.id!);
      expect(afterInsertCuenta, isNotNull);
      expect(afterInsertCuenta!.saldoInicial, equals(initial - 100.0));

      await repo.deleteTransaccion(id);
      final afterDeleteCuenta = await cuentaRepo.getCuentaById(cuenta.id!);
      expect(afterDeleteCuenta, isNotNull);
      expect(afterDeleteCuenta!.saldoInicial, closeTo(initial, 0.0001));
    });
  });
}
