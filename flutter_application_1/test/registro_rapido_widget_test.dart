import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_application_1/presentation/screens/registro_rapido_screen.dart';
import 'package:flutter_application_1/app_providers.dart';
import 'package:flutter_application_1/data/models/transaccion_model.dart';
import 'package:flutter_application_1/data/models/cuenta_model.dart';
import 'package:flutter_application_1/data/models/categoria_model.dart';
import 'package:flutter_application_1/data/models/fondo_model.dart';
import 'package:flutter_application_1/data/models/asignacion_model.dart';
import 'package:flutter_application_1/data/repositories/fondo_repository.dart';
import 'package:flutter_application_1/domain/repositories/i_transaccion_repository.dart';
import 'package:flutter_application_1/domain/repositories/i_cuenta_repository.dart';

class FakeTransaccionRepository implements ITransaccionRepository {
  @override
  Future<int> insertTransaccion(Transaccion t) async => 1;

  @override
  Future<void> deleteAll() async {}

  @override
  Future<void> deleteTransaccion(int id) async {}

  @override
  Future<List<Transaccion>> getAllTransacciones() async => [];
}

class FakeCuentaRepository implements ICuentaRepository {
  @override
  Future<Cuenta?> getCuentaById(int id) async => Cuenta(id: id, nombre: 'Efectivo', saldoInicial: 100.0);

  @override
  Future<List<Cuenta>> getAllCuentas() async => [Cuenta(id: 1, nombre: 'Efectivo', saldoInicial: 100.0)];
  @override
  Future<void> adjustSaldo(int cuentaId, double delta) async {}

  @override
  Future<int> insertCuenta(Cuenta c) async => 1;
}

class FakeFondoRepository extends FondoRepository {
  @override
  Future<List<Fondo>> getAllFondos() async => [Fondo(id: 1, nombre: 'Ahorro', metaMonto: 200.0)];

  @override
  Future<List<AsignacionAhorro>> getAsignacionesByFondo(int fondoId) async => [];

  @override
  Future<List<AsignacionAhorro>> getAsignacionesByTransaccion(int transaccionId) async => [];
}

void main() {
  testWidgets('SnackBar shows Asignar action and opens dialog when pressed', (tester) async {
    final fakeTransRepo = FakeTransaccionRepository();
    final fakeCuentaRepo = FakeCuentaRepository();
    final fakeFondoRepo = FakeFondoRepository();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        transaccionRepositoryProvider.overrideWithValue(fakeTransRepo),
        cuentaRepositoryProvider.overrideWithValue(fakeCuentaRepo),
        fondoRepositoryProvider.overrideWithValue(fakeFondoRepo),
        cuentasListProvider.overrideWithProvider(FutureProvider<List<Cuenta>>((ref) async => [Cuenta(id: 1, nombre: 'Efectivo', saldoInicial: 100.0)])),
        categoriasListProvider.overrideWithProvider(FutureProvider<List<Categoria>>((ref) async => [Categoria(id: 1, nombre: 'General', tipo: 'Ingreso')])),
      ],
      child: const MaterialApp(home: RegistroRapidoScreen()),
    ));

    await tester.pumpAndSettle();

    // Enter amount into the first TextFormField (Monto)
    final montoField = find.byType(TextFormField).first;
    expect(montoField, findsOneWidget);
    await tester.enterText(montoField, '50');

    // Select Ingreso via ToggleButtons by tapping the child text
    await tester.tap(find.text('Ingreso'));
    await tester.pumpAndSettle();

    // Tap Guardar
    await tester.tap(find.text('Guardar'));
    await tester.pump(); // allow SnackBar to appear

    // SnackBar with action 'Asignar' should be visible
    expect(find.text('Asignar'), findsOneWidget);

    // Tap the SnackBar action (use SnackBarAction widget)
    await tester.pumpAndSettle();
    final actionFinder = find.byType(SnackBarAction);
    expect(actionFinder, findsOneWidget);
    await tester.tap(actionFinder);
    await tester.pumpAndSettle();

    // Dialog should open
    expect(find.text('Asignar a fondo'), findsOneWidget);
  });
}
