import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_application_1/data/db_provider.dart';
import 'package:flutter_application_1/data/repositories/categoria_repository.dart';
import 'package:flutter_application_1/data/repositories/transaccion_repository.dart';
import 'package:flutter_application_1/data/models/categoria_model.dart';
import 'package:flutter_application_1/data/models/transaccion_model.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Categoria repository CRUD and transacciones by categoria', () async {
    await DBProvider.init(inMemory: true);

    final repo = CategoriaRepository();
    final cat = Categoria(nombre: 'Prueba', tipo: 'Egreso', colorHex: '#FF5722');
    final id = await repo.insertCategoria(cat);
    expect(id, greaterThan(0));

    final all = await repo.getAllCategorias();
    expect(all.any((c) => c.nombre == 'Prueba'), true);

    final fetched = await repo.getCategoriaById(id);
    expect(fetched, isNotNull);
    expect(fetched!.nombre, 'Prueba');

    // Insert a transaccion linked to category
    final tRepo = TransaccionRepository();
    final tx = Transaccion(fecha: DateTime.now().toIso8601String(), monto: 10.0, descripcion: 'cat test', cuentaId: 1, categoriaId: id, tipo: 'Egreso');
    final txId = await tRepo.insertTransaccion(tx);
    expect(txId, greaterThan(0));

    final txs = await repo.getTransaccionesByCategoria(id);
    expect(txs.length, greaterThanOrEqualTo(1));

    final del = await repo.deleteCategoria(id);
    expect(del, 1);
  });
}
