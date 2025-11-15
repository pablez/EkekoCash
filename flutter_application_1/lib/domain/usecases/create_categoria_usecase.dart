import '../../data/models/categoria_model.dart';
import '../../data/repositories/categoria_repository.dart';

class CreateCategoriaUseCase {
  final CategoriaRepository repo;
  CreateCategoriaUseCase(this.repo);

  Future<int> execute(Categoria c) async {
    if (c.nombre.trim().isEmpty) throw ArgumentError('Nombre de categoría requerido');
    if (!(c.tipo == 'Ingreso' || c.tipo == 'Egreso')) throw ArgumentError('Tipo inválido');
    return await repo.insertCategoria(c);
  }
}
