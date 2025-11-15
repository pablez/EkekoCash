import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/domain/usecases/create_transaccion_usecase.dart';
import 'package:flutter_application_1/data/models/transaccion_model.dart';
import 'package:flutter_application_1/data/repositories/transaccion_repository.dart';
import 'package:flutter_application_1/data/repositories/cuenta_repository.dart';
import 'package:flutter_application_1/data/models/cuenta_model.dart';

class _FakeRepo extends TransaccionRepository {
  int lastId = 0;
  @override
  Future<int> insertTransaccion(Transaccion t) async {
    lastId++;
    return lastId;
  }
}

class _CuentaRepoOk extends CuentaRepository {
  @override
  Future<Cuenta?> getCuentaById(int id) async => Cuenta(id: id, nombre: 'CuentaTest', saldoInicial: 0.0);
}

class _CuentaRepoNull extends CuentaRepository {
  @override
  Future<Cuenta?> getCuentaById(int id) async => null;
}

void main() {
  group('CreateTransaccionUseCase', () {
    test('lanza ArgumentError cuando monto <= 0', () async {
      final repo = _FakeRepo();
      final cuentaRepo = _CuentaRepoOk();
      final usecase = CreateTransaccionUseCase(repo, cuentaRepo);

      final t = Transaccion(fecha: '2025-11-12', monto: 0.0, descripcion: 'x', cuentaId: 1, tipo: 'Ingreso');

      expect(() => usecase.execute(t), throwsA(isA<ArgumentError>()));
    });

    test('lanza ArgumentError cuando tipo inválido', () async {
      final repo = _FakeRepo();
      final cuentaRepo = _CuentaRepoOk();
      final usecase = CreateTransaccionUseCase(repo, cuentaRepo);

      final t = Transaccion(fecha: '2025-11-12', monto: 10.0, descripcion: 'x', cuentaId: 1, tipo: 'Otro');

      expect(() => usecase.execute(t), throwsA(isA<ArgumentError>()));
    });

    test('lanza StateError cuando cuenta inexistente', () async {
      final repo = _FakeRepo();
      final cuentaRepo = _CuentaRepoNull();
      final usecase = CreateTransaccionUseCase(repo, cuentaRepo);

      final t = Transaccion(fecha: '2025-11-12', monto: 10.0, descripcion: 'x', cuentaId: 999, tipo: 'Ingreso');

      expect(() => usecase.execute(t), throwsA(isA<StateError>()));
    });

    test('caso feliz devuelve id', () async {
      final repo = _FakeRepo();
      final cuentaRepo = _CuentaRepoOk();
      final usecase = CreateTransaccionUseCase(repo, cuentaRepo);

      final t = Transaccion(fecha: '2025-11-12', monto: 10.0, descripcion: 'ok', cuentaId: 1, tipo: 'Ingreso');

      final id = await usecase.execute(t);
      expect(id, 1);
    });
  });
}
