import '../../data/models/transaccion_model.dart';
import '../../data/repositories/transaccion_repository.dart';
import '../../data/repositories/cuenta_repository.dart';

class CreateTransaccionUseCase {
  final TransaccionRepository repository;
  final CuentaRepository cuentaRepository;

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
