import '../../data/repositories/categoria_repository.dart';

class DeleteCategoriaUseCase {
  final CategoriaRepository repo;
  DeleteCategoriaUseCase(this.repo);

  Future<int> execute(int id) async {
    return await repo.deleteCategoria(id);
  }
}
