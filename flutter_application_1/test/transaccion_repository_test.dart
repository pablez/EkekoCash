import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_application_1/data/db_provider.dart';
import 'package:flutter_application_1/data/models/transaccion_model.dart';
import 'package:flutter_application_1/data/repositories/transaccion_repository.dart';

void main() {
  // Inicializar ffi para ejecutar sqflite en desktop tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('TransaccionRepository', () {
    setUpAll(() async {
      await DBProvider.init(inMemory: true);
    });

    test('insert y getAll', () async {
      final repo = TransaccionRepository();

      final t = Transaccion(
        fecha: DateTime.now().toIso8601String(),
        monto: 123.45,
        descripcion: 'Test',
        cuentaId: 1,
        tipo: 'Egreso',
      );

      final id = await repo.insertTransaccion(t);
      expect(id, greaterThan(0));

      final all = await repo.getAllTransacciones();
      expect(all, isNotEmpty);
      expect(all.first.monto, 123.45);
    });
  });
}
