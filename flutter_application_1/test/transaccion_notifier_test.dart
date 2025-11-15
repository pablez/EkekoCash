import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/domain/notifiers/transaccion_notifier.dart';
import 'package:flutter_application_1/data/models/transaccion_model.dart';
import 'package:flutter_application_1/domain/usecases/create_transaccion_usecase.dart';
import 'package:flutter_application_1/data/repositories/transaccion_repository.dart';
import 'package:flutter_application_1/data/repositories/cuenta_repository.dart';
import 'package:flutter_application_1/data/models/cuenta_model.dart';

/// Tests unitarios para [TransaccionNotifier].
void main() {
  group('TransaccionNotifier', () {
    test('carga transacciones iniciales en la construcción', () async {
      final t1 = Transaccion(
        id: 1,
        fecha: '2025-11-12',
        monto: 50.0,
        descripcion: ' inicial ',
        cuentaId: 1,
        tipo: 'Ingreso',
      );

      final repo = _FakeTransaccionRepository(initial: [t1]);
      final cuentaRepo = _TestCuentaRepository();
      final usecase = CreateTransaccionUseCase(repo, cuentaRepo);

      final notifier = TransaccionNotifier(usecase, repo);
      // permitir que el microtask de _loadAll complete
      await Future.delayed(Duration.zero);

      expect(notifier.state.length, 1);
      expect(notifier.state.first.id, 1);
      expect(notifier.state.first.monto, 50.0);
    });

    test('addTransaccion agrega y pre-pende la transacción', () async {
      final repo = _FakeTransaccionRepository(initial: []);
      final cuentaRepo = _TestCuentaRepository();
      final usecase = CreateTransaccionUseCase(repo, cuentaRepo);

      final notifier = TransaccionNotifier(usecase, repo);
      await Future.delayed(Duration.zero);

      final t = Transaccion(
        fecha: '2025-11-12',
        monto: 20.0,
        descripcion: 'compra',
        cuentaId: 1,
        tipo: 'Egreso',
      );

      await notifier.addTransaccion(t);

      expect(notifier.state.length, 1);
      final added = notifier.state.first;
      expect(added.monto, 20.0);
      expect(added.id, isNotNull);
      // repo también debe contener la transacción
      expect(repo.storage.length, 1);
      expect(repo.storage.first.monto, 20.0);
    });

    test('deleteTransaccion elimina de estado y repo', () async {
      final t1 = Transaccion(
        id: 1,
        fecha: '2025-11-12',
        monto: 30.0,
        descripcion: 'pago',
        cuentaId: 1,
        tipo: 'Egreso',
      );

      final repo = _FakeTransaccionRepository(initial: [t1]);
      final cuentaRepo = _TestCuentaRepository();
      final usecase = CreateTransaccionUseCase(repo, cuentaRepo);

      final notifier = TransaccionNotifier(usecase, repo);
      await Future.delayed(Duration.zero);

      await notifier.deleteTransaccion(1);

      expect(notifier.state, isEmpty);
      expect(repo.storage, isEmpty);
    });
  });
}

/// Implementaciones de prueba mínimas (fakes) para evitar acceso a DB real.
class _FakeTransaccionRepository extends TransaccionRepository {
  final List<Transaccion> storage = [];
  int _nextId = 1;

  _FakeTransaccionRepository({List<Transaccion>? initial}) {
    if (initial != null) {
      storage.addAll(initial.map((t) => Transaccion(
            id: t.id,
            fecha: t.fecha,
            monto: t.monto,
            descripcion: t.descripcion,
            cuentaId: t.cuentaId,
            subcategoriaId: t.subcategoriaId,
            miembroId: t.miembroId,
            tipo: t.tipo,
          )));
      // asegurar el siguiente id
      final maxId = storage.map((e) => e.id ?? 0).fold<int>(0, (p, n) => n > p ? n : p);
      _nextId = maxId + 1;
    }
  }

  @override
  Future<int> insertTransaccion(Transaccion t) async {
    final id = _nextId++;
    final copy = Transaccion(
      id: id,
      fecha: t.fecha,
      monto: t.monto,
      descripcion: t.descripcion,
      cuentaId: t.cuentaId,
      subcategoriaId: t.subcategoriaId,
      miembroId: t.miembroId,
      tipo: t.tipo,
    );
    storage.insert(0, copy);
    return id;
  }

  @override
  Future<List<Transaccion>> getAllTransacciones() async {
    // devolver una copia para evitar aliasing en tests
    return storage.map((t) => Transaccion(
          id: t.id,
          fecha: t.fecha,
          monto: t.monto,
          descripcion: t.descripcion,
          cuentaId: t.cuentaId,
          subcategoriaId: t.subcategoriaId,
          miembroId: t.miembroId,
          tipo: t.tipo,
        )).toList();
  }

  @override
  Future<void> deleteTransaccion(int id) async {
    storage.removeWhere((t) => t.id == id);
  }
}

class _TestCuentaRepository extends CuentaRepository {
  @override
  Future<Cuenta?> getCuentaById(int id) async {
    return Cuenta(id: id, nombre: 'CuentaTest', saldoInicial: 100.0);
  }
}
