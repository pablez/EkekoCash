import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_application_1/data/db_provider.dart';
import 'package:flutter_application_1/data/repositories/fondo_repository.dart';
import 'package:flutter_application_1/data/models/fondo_model.dart';
import 'package:flutter_application_1/data/models/asignacion_model.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('insert, get and delete asignacion flow', () async {
    // Initialize in-memory DB
    await DBProvider.init(inMemory: true);

    final repo = FondoRepository();

    final fondo = Fondo(nombre: 'Prueba Fondo', metaMonto: 200.0);
    final fondoId = await repo.insertFondo(fondo);
    expect(fondoId, greaterThan(0));

    final asign = AsignacionAhorro(montoAsignado: 25.0, transaccionId: 1, fondoId: fondoId);
    final asignId = await repo.insertAsignacion(asign);
    expect(asignId, greaterThan(0));

    final asigns = await repo.getAsignacionesByFondo(fondoId);
    expect(asigns.length, 1);
    expect(asigns.first.montoAsignado, closeTo(25.0, 0.01));

    final deleted = await repo.deleteAsignacion(asignId);
    expect(deleted, 1);

    final asignsAfter = await repo.getAsignacionesByFondo(fondoId);
    expect(asignsAfter.isEmpty, true);
  });
}
