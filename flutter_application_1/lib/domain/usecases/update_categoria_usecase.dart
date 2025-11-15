import '../../data/models/categoria_model.dart';
import '../../data/repositories/categoria_repository.dart';

class UpdateCategoriaUseCase {
  final CategoriaRepository repo;
  UpdateCategoriaUseCase(this.repo);

  Future<int> execute(Categoria c) async {
    if (c.categoriaId == null) throw ArgumentError('Categoria id requerido');
    if (c.nombre.trim().isEmpty) throw ArgumentError('Nombre de categoría requerido');
    return await repo.updateCategoria(c);
  }
}
