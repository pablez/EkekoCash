import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/repositories/transaccion_repository.dart';
import 'domain/usecases/create_transaccion_usecase.dart';
import 'domain/notifiers/transaccion_notifier.dart';
import 'data/models/transaccion_model.dart';
import 'data/repositories/cuenta_repository.dart';
import 'data/models/cuenta_model.dart';
import 'data/models/categoria_model.dart';
import 'data/repositories/categoria_repository.dart';


final transaccionRepositoryProvider = Provider<TransaccionRepository>((ref) => TransaccionRepository());

final cuentaRepositoryProvider = Provider<CuentaRepository>((ref) => CuentaRepository());

final categoriaRepositoryProvider = Provider<CategoriaRepository>((ref) => CategoriaRepository());

final cuentasListProvider = FutureProvider<List<Cuenta>>((ref) async {
  final repo = ref.read(cuentaRepositoryProvider);
  return repo.getAllCuentas();
});

final categoriasListProvider = FutureProvider<List<Categoria>>((ref) async {
  final repo = ref.read(categoriaRepositoryProvider);
  return repo.getAllCategorias();
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
