import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_application_1/presentation/screens/categorias_screen.dart';
import 'package:flutter_application_1/data/models/categoria_model.dart';
import 'package:flutter_application_1/app_providers.dart';
import 'package:flutter_application_1/data/repositories/categoria_repository.dart';
import 'package:flutter_application_1/domain/notifiers/categorias_notifier.dart';

class FakeCategoriaRepo extends CategoriaRepository {
  final List<Categoria> items;
  FakeCategoriaRepo(this.items);

  @override
  Future<List<Categoria>> getAllCategorias({String? tipo}) async => items;
}

void main() {
  testWidgets('CategoriasScreen shows provided categories', (tester) async {
    final fakeRepo = FakeCategoriaRepo([Categoria(categoriaId: 1, nombre: 'PruebaCat', tipo: 'Egreso')]);
    final notifier = CategoriasNotifier(fakeRepo);

    await tester.pumpWidget(ProviderScope(overrides: [
      categoriasNotifierProvider.overrideWith((ref) => notifier),
    ], child: const MaterialApp(home: CategoriasScreen())));

    await tester.pumpAndSettle();

    expect(find.text('PruebaCat'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
