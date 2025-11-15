import '../../data/models/asignacion_model.dart';
import '../../data/repositories/fondo_repository.dart';

class CreateAsignacionUseCase {
  final FondoRepository repo;
  CreateAsignacionUseCase(this.repo);

  Future<int> execute(AsignacionAhorro a) async {
    if (a.montoAsignado <= 0) throw ArgumentError('Monto asignado debe ser > 0');
    return await repo.insertAsignacion(a);
  }
}
