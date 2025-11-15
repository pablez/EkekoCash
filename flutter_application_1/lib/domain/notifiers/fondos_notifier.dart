import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/fondo_model.dart';
import '../../data/repositories/fondo_repository.dart';

class FondosNotifier extends StateNotifier<List<Fondo>> {
  final FondoRepository repo;
  FondosNotifier(this.repo) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final f = await repo.getAllFondos();
    state = f;
  }

  /// Public refresh to reload fondos from repository.
  Future<void> refresh() async {
    final f = await repo.getAllFondos();
    state = f;
  }

  Future<void> addFondo(Fondo f) async {
    final id = await repo.insertFondo(f);
    final inserted = Fondo(id: id, nombre: f.nombre, metaMonto: f.metaMonto, fechaMeta: f.fechaMeta, iconoId: f.iconoId);
    state = [inserted, ...state];
  }
}
