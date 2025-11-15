import '../../data/models/categoria_model.dart';
import '../../data/repositories/categoria_repository.dart';

class GetCategoriasUseCase {
  final CategoriaRepository repo;
  GetCategoriasUseCase(this.repo);

  Future<List<Categoria>> execute({String? tipo}) async {
    return await repo.getAllCategorias(tipo: tipo);
  }
}
