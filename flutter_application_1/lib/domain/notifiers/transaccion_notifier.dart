import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../usecases/create_transaccion_usecase.dart';
import '../../data/models/transaccion_model.dart';
import '../repositories/i_transaccion_repository.dart';

class TransaccionNotifier extends StateNotifier<List<Transaccion>> {
  final CreateTransaccionUseCase createUseCase;
  final ITransaccionRepository repository;

  TransaccionNotifier(this.createUseCase, this.repository) : super([]) {
    _loadAll();
  }

  Future<void> _loadAll() async {
    final all = await repository.getAllTransacciones();
    state = all;
  }

  Future<Transaccion> addTransaccion(Transaccion t) async {
    final id = await createUseCase.execute(t);
    final inserted = Transaccion(
      id: id,
      fecha: t.fecha,
      monto: t.monto,
      descripcion: t.descripcion,
      cuentaId: t.cuentaId,
      subcategoriaId: t.subcategoriaId,
      miembroId: t.miembroId,
      tipo: t.tipo,
    );
    state = [inserted, ...state];
    return inserted;
  }

  Future<void> deleteTransaccion(int transaccionId) async {
    await repository.deleteTransaccion(transaccionId);
    state = state.where((t) => t.id != transaccionId).toList();
  }
}
