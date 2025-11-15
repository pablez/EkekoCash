import '../../data/models/transaccion_model.dart';
import '../repositories/i_transaccion_repository.dart';
import '../repositories/i_cuenta_repository.dart';

class CreateTransaccionUseCase {
  final ITransaccionRepository repository;
  final ICuentaRepository cuentaRepository;

  CreateTransaccionUseCase(this.repository, this.cuentaRepository);

  /// Valida reglas simples y crea la transacción en la DB.
  Future<int> execute(Transaccion t) async {
    if (t.monto <= 0) throw ArgumentError('El monto debe ser mayor que cero.');
    if (!(t.tipo == 'Ingreso' || t.tipo == 'Egreso')) throw ArgumentError('Tipo inválido');

    final cuenta = await cuentaRepository.getCuentaById(t.cuentaId);
    if (cuenta == null) throw StateError('Cuenta no encontrada');

    return await repository.insertTransaccion(t);
  }
}
