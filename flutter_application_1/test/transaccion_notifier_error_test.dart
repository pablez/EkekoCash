import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/domain/notifiers/transaccion_notifier.dart';
import 'package:flutter_application_1/data/models/transaccion_model.dart';
import 'package:flutter_application_1/data/repositories/transaccion_repository.dart';
import 'package:flutter_application_1/domain/usecases/create_transaccion_usecase.dart';
import 'package:flutter_application_1/data/repositories/cuenta_repository.dart';

class _ThrowingUseCase extends CreateTransaccionUseCase {
  _ThrowingUseCase() : super(_NoopRepo(), _NoopCuentaRepo());

  @override
  Future<int> execute(Transaccion t) async {
    throw StateError('simulated failure');
  }
}

class _NoopRepo extends TransaccionRepository {}

class _NoopCuentaRepo extends CuentaRepository {}

class _InMemoryRepo extends TransaccionRepository {
  final List<Transaccion> storage = [];
  int _next = 1;

  @override
  Future<int> insertTransaccion(Transaccion t) async {
    final id = _next++;
    storage.insert(0, Transaccion(id: id, fecha: t.fecha, monto: t.monto, descripcion: t.descripcion, cuentaId: t.cuentaId, tipo: t.tipo));
    return id;
  }

  @override
  Future<List<Transaccion>> getAllTransacciones() async => storage;

  @override
  Future<void> deleteTransaccion(int id) async {
    storage.removeWhere((t) => t.id == id);
  }
}

void main() {
  test('addTransaccion propaga error y no cambia estado cuando usecase falla', () async {
    final repo = _InMemoryRepo();
    final throwing = _ThrowingUseCase();
    final notifier = TransaccionNotifier(throwing, repo);
    await Future.delayed(Duration.zero);

    final t = Transaccion(fecha: '2025-11-12', monto: 10.0, descripcion: 'x', cuentaId: 1, tipo: 'Ingreso');

    expect(() => notifier.addTransaccion(t), throwsA(isA<StateError>()));
    // estado no debe cambiar
    expect(notifier.state, isEmpty);
  });
}
