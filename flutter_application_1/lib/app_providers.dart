import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/repositories/transaccion_repository.dart';
import 'domain/repositories/i_transaccion_repository.dart';
import 'domain/usecases/create_transaccion_usecase.dart';
import 'domain/notifiers/transaccion_notifier.dart';
import 'data/models/transaccion_model.dart';
import 'data/repositories/cuenta_repository.dart';
import 'domain/repositories/i_cuenta_repository.dart';
import 'data/models/cuenta_model.dart';
import 'data/models/categoria_model.dart';
import 'data/repositories/categoria_repository.dart';
import 'domain/notifiers/categorias_notifier.dart';
import 'domain/usecases/create_categoria_usecase.dart';
import 'domain/usecases/update_categoria_usecase.dart';
import 'domain/usecases/delete_categoria_usecase.dart';
import 'domain/usecases/get_categorias_usecase.dart';
import 'data/repositories/fondo_repository.dart';
import 'domain/notifiers/fondos_notifier.dart';
import 'domain/usecases/create_asignacion_usecase.dart';
import 'data/models/fondo_model.dart';


final transaccionRepositoryProvider = Provider<ITransaccionRepository>((ref) => TransaccionRepository());

final cuentaRepositoryProvider = Provider<ICuentaRepository>((ref) => CuentaRepository());

final categoriaRepositoryProvider = Provider<CategoriaRepository>((ref) => CategoriaRepository());

final cuentasListProvider = FutureProvider<List<Cuenta>>((ref) async {
  final repo = ref.read(cuentaRepositoryProvider);
  return repo.getAllCuentas();
});

final categoriasListProvider = FutureProvider<List<Categoria>>((ref) async {
  final repo = ref.read(categoriaRepositoryProvider);
  return repo.getAllCategorias();
});

final categoriasNotifierProvider = StateNotifierProvider<CategoriasNotifier, List<Categoria>>((ref) {
  final repo = ref.read(categoriaRepositoryProvider);
  return CategoriasNotifier(repo);
});

final fondoRepositoryProvider = Provider<FondoRepository>((ref) => FondoRepository());

final fondosNotifierProvider = StateNotifierProvider<FondosNotifier, List<Fondo>>((ref) {
  final repo = ref.read(fondoRepositoryProvider);
  return FondosNotifier(repo);
});

final createAsignacionUseCaseProvider = Provider<CreateAsignacionUseCase>((ref) {
  final repo = ref.read(fondoRepositoryProvider);
  return CreateAsignacionUseCase(repo);
});

final createTransaccionUseCaseProvider = Provider<CreateTransaccionUseCase>((ref) {
  final repo = ref.read(transaccionRepositoryProvider);
  final cuentaRepo = ref.read(cuentaRepositoryProvider);
  return CreateTransaccionUseCase(repo, cuentaRepo);
});

final transaccionNotifierProvider = StateNotifierProvider<TransaccionNotifier, List<Transaccion>>((ref) {
  final repo = ref.read(transaccionRepositoryProvider);
  final usecase = ref.read(createTransaccionUseCaseProvider);
  return TransaccionNotifier(usecase, repo);
});
