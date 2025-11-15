import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/domain/usecases/create_asignacion_usecase.dart';
import 'package:flutter_application_1/data/models/asignacion_model.dart';

import 'package:flutter_application_1/data/repositories/fondo_repository.dart';

class _FakeRepo extends FondoRepository {
  int? lastInsertedId;
  AsignacionAhorro? lastAsignacion;

  @override
  Future<int> insertAsignacion(AsignacionAhorro a) async {
    lastAsignacion = a;
    lastInsertedId = 42;
    return lastInsertedId!;
  }
}

void main() {
  test('throws on non-positive monto', () async {
    final fake = _FakeRepo();
    final usecase = CreateAsignacionUseCase(fake as dynamic);

    expect(() => usecase.execute(AsignacionAhorro(montoAsignado: 0.0, transaccionId: 1, fondoId: 1)), throwsArgumentError);
  });

  test('inserts valid asignacion via repo', () async {
    final fake = _FakeRepo();
    final usecase = CreateAsignacionUseCase(fake as dynamic);

    final id = await usecase.execute(AsignacionAhorro(montoAsignado: 12.5, transaccionId: 1, fondoId: 1));
    expect(id, 42);
    expect(fake.lastAsignacion, isNotNull);
    expect(fake.lastAsignacion!.montoAsignado, closeTo(12.5, 0.01));
  });
}
