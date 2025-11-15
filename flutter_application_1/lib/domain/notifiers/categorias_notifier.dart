import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/categoria_model.dart';
import '../../data/repositories/categoria_repository.dart';

class CategoriasNotifier extends StateNotifier<List<Categoria>> {
  final CategoriaRepository repo;
  CategoriasNotifier(this.repo) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final cats = await repo.getAllCategorias();
    state = cats;
  }

  Future<void> refresh() async {
    final cats = await repo.getAllCategorias();
    state = cats;
  }

  Future<void> addCategoria(Categoria c) async {
    final id = await repo.insertCategoria(c);
    final inserted = Categoria(categoriaId: id, nombre: c.nombre, tipo: c.tipo, colorHex: c.colorHex);
    state = [inserted, ...state];
  }

  Future<void> updateCategoria(Categoria c) async {
    if (c.categoriaId == null) return;
    await repo.updateCategoria(c);
    state = state.map((e) => e.categoriaId == c.categoriaId ? c : e).toList();
  }

  Future<void> deleteCategoria(int id) async {
    await repo.deleteCategoria(id);
    state = state.where((c) => c.categoriaId != id).toList();
  }
}
