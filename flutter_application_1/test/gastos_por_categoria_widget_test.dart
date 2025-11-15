import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_application_1/presentation/screens/categorias_screen.dart';
import 'package:flutter_application_1/data/models/categoria_model.dart';
import 'package:flutter_application_1/data/models/transaccion_model.dart';
import 'package:flutter_application_1/app_providers.dart';

import 'package:flutter_application_1/data/repositories/categoria_repository.dart';

class FakeCategoriaRepo extends CategoriaRepository {
  @override
  Future<List<Transaccion>> getTransaccionesByCategoria(int categoriaId) async {
    return [Transaccion(id: 1, fecha: DateTime.now().toIso8601String(), monto: 12.34, descripcion: 't1', cuentaId: 1, tipo: 'Egreso')];
  }
}

void main() {
  testWidgets('GastosPorCategoriaScreen shows transacciones from repo', (tester) async {
    final c = Categoria(categoriaId: 1, nombre: 'TestCat', tipo: 'Egreso');

    // Override repository provider with fake
    final fakeRepo = FakeCategoriaRepo();
    await tester.pumpWidget(ProviderScope(overrides: [
      categoriaRepositoryProvider.overrideWith((ref) => fakeRepo),
    ], child: MaterialApp(home: GastosPorCategoriaScreen(categoria: c))));

    await tester.pumpAndSettle();

    expect(find.textContaining('12.34'), findsOneWidget);
    expect(find.text('t1'), findsOneWidget);
  });
}
