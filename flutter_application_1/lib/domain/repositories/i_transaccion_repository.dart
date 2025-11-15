import '../../data/models/transaccion_model.dart';

abstract class ITransaccionRepository {
  Future<int> insertTransaccion(Transaccion t);
  Future<List<Transaccion>> getAllTransacciones();
  Future<void> deleteAll();
  Future<void> deleteTransaccion(int id);
}
