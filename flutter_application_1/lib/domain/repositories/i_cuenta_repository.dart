import '../../data/models/cuenta_model.dart';

abstract class ICuentaRepository {
  Future<List<Cuenta>> getAllCuentas();
  Future<Cuenta?> getCuentaById(int id);
  Future<void> adjustSaldo(int cuentaId, double delta);
  Future<int> insertCuenta(Cuenta c);
}
