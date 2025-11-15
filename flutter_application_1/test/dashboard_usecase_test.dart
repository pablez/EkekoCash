import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/domain/usecases/get_dashboard_kpis_usecase.dart';
import 'package:flutter_application_1/data/models/transaccion_model.dart';
import 'package:flutter_application_1/domain/repositories/i_transaccion_repository.dart';
import 'package:flutter_application_1/domain/repositories/i_cuenta_repository.dart';
import 'package:flutter_application_1/data/repositories/fondo_repository.dart';
import 'package:flutter_application_1/data/models/fondo_model.dart';
import 'package:flutter_application_1/data/models/asignacion_model.dart';
import 'package:flutter_application_1/data/models/cuenta_model.dart';

class FakeTransRepo implements ITransaccionRepository {
  final List<Transaccion> items;
  FakeTransRepo(this.items);

  @override
  Future<int> insertTransaccion(Transaccion t) async => 1;

  @override
  Future<void> deleteAll() async {}

  @override
  Future<void> deleteTransaccion(int id) async {}

  @override
  Future<List<Transaccion>> getAllTransacciones() async => items;
}

class FakeCuentaRepo implements ICuentaRepository {
  @override
  Future<int> insertCuenta(Cuenta c) async => 1;

  @override
  Future<List<Cuenta>> getAllCuentas() async => <Cuenta>[];

  @override
  Future<void> adjustSaldo(int cuentaId, double delta) async {}

  @override
  Future<Cuenta?> getCuentaById(int id) async => null;
}

class FakeFondoRepo extends FondoRepository {
  final List<Fondo> fondos;
  final Map<int, List<AsignacionAhorro>> asigns;
  FakeFondoRepo(this.fondos, this.asigns);

  @override
  Future<List<Fondo>> getAllFondos() async => fondos;

  @override
  Future<List<AsignacionAhorro>> getAsignacionesByFondo(int fondoId) async => asigns[fondoId] ?? [];
}

void main() {
  test('GetDailySeries returns buckets for range', () async {
    final now = DateTime.now();
    final t1 = Transaccion(fecha: now.toIso8601String(), monto: 100.0, cuentaId: 1, tipo: 'Ingreso');
    final t2 = Transaccion(fecha: now.subtract(const Duration(days: 1)).toIso8601String(), monto: 50.0, cuentaId: 1, tipo: 'Egreso');
    final repo = FakeTransRepo([t1, t2]);

    final cuentaRepo = FakeCuentaRepo();
    final fondoRepo = FakeFondoRepo([], {});
    final usecase = GetDashboardKpisUseCase(repo, cuentaRepo, fondoRepo);
    final from = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 2));
    final to = DateTime(now.year, now.month, now.day);
    final series = await usecase.getDailySeries(from: from, to: to);
    expect(series.length, equals(3));
    // verify values
    final today = series.last;
    expect(today.ingresos, closeTo(100.0, 0.001));
  });
}
