import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_application_1/data/db_provider.dart';
import 'package:flutter_application_1/data/repositories/categoria_repository.dart';
import 'package:flutter_application_1/domain/usecases/create_categoria_usecase.dart';
import 'package:flutter_application_1/domain/usecases/get_categorias_usecase.dart';
import 'package:flutter_application_1/domain/usecases/update_categoria_usecase.dart';
import 'package:flutter_application_1/domain/usecases/delete_categoria_usecase.dart';
import 'package:flutter_application_1/data/models/categoria_model.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Categoria usecases create/get/update/delete', () async {
    await DBProvider.init(inMemory: true);
    final repo = CategoriaRepository();
    final create = CreateCategoriaUseCase(repo);
    final get = GetCategoriasUseCase(repo);
    final update = UpdateCategoriaUseCase(repo);
    final del = DeleteCategoriaUseCase(repo);

    final id = await create.execute(Categoria(nombre: 'UC Test', tipo: 'Egreso'));
    expect(id, greaterThan(0));

    final cats = await get.execute();
    expect(cats.any((c) => c.nombre == 'UC Test'), true);

    final c = cats.firstWhere((c) => c.nombre == 'UC Test');
    await update.execute(Categoria(categoriaId: c.categoriaId, nombre: 'UC Test Updated', tipo: c.tipo));
    final updated = await repo.getCategoriaById(c.categoriaId!);
    expect(updated!.nombre, 'UC Test Updated');

    final res = await del.execute(c.categoriaId!);
    expect(res, 1);
  });
}
