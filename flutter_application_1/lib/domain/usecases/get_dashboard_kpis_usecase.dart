import '../models/dashboard_kpis.dart';
import '../models/daily_bucket.dart';
import '../repositories/i_transaccion_repository.dart';
import '../repositories/i_cuenta_repository.dart';
import '../../data/repositories/fondo_repository.dart';

class GetDashboardKpisUseCase {
  final ITransaccionRepository transRepo;
  final ICuentaRepository cuentaRepo;
  final FondoRepository fondoRepo;

  GetDashboardKpisUseCase(this.transRepo, this.cuentaRepo, this.fondoRepo);

  Future<DashboardKpis> execute({required DateTime from, required DateTime to}) async {
    final all = await transRepo.getAllTransacciones();
    double ingresos = 0.0;
    double egresos = 0.0;

    for (final t in all) {
      try {
        final fecha = DateTime.parse(t.fecha);
        if (fecha.isBefore(from) || fecha.isAfter(to)) continue;
        if (t.tipo.toLowerCase() == 'ingreso') ingresos += t.monto;
        else egresos += t.monto;
      } catch (_) {
        continue;
      }
    }

    final cuentas = await cuentaRepo.getAllCuentas();
    final totalBalance = cuentas.fold<double>(0.0, (s, c) => s + c.saldoInicial);

    final fondos = await fondoRepo.getAllFondos();
    double ahorroAsignado = 0.0;
    double totalMeta = 0.0;
    for (final f in fondos) {
      totalMeta += f.metaMonto;
      final asigns = await fondoRepo.getAsignacionesByFondo(f.id!);
      ahorroAsignado += asigns.fold<double>(0.0, (s, a) => s + a.montoAsignado);
    }

    return DashboardKpis(totalIngresos: ingresos, totalEgresos: egresos, totalBalance: totalBalance, ahorroAsignado: ahorroAsignado, totalMetaFondos: totalMeta);
  }

  Future<List<DailyBucket>> getDailySeries({required DateTime from, required DateTime to}) async {
    final all = await transRepo.getAllTransacciones();
    // Build map keyed by date (YYYY-MM-DD)
    final Map<String, DailyBucket> map = {};
    DateTime cur = DateTime(from.year, from.month, from.day);
    while (!cur.isAfter(to)) {
      final key = '${cur.year}-${cur.month.toString().padLeft(2,'0')}-${cur.day.toString().padLeft(2,'0')}';
      map[key] = DailyBucket(date: cur, ingresos: 0.0, egresos: 0.0);
      cur = cur.add(const Duration(days: 1));
    }

    for (final t in all) {
      DateTime? fecha;
      try {
        fecha = DateTime.parse(t.fecha);
      } catch (_) {
        continue;
      }
      final normalized = DateTime(fecha.year, fecha.month, fecha.day);
      if (normalized.isBefore(from) || normalized.isAfter(to)) continue;
      final key = '${normalized.year}-${normalized.month.toString().padLeft(2,'0')}-${normalized.day.toString().padLeft(2,'0')}';
      final prev = map[key];
      if (prev == null) continue;
      if (t.tipo.toLowerCase() == 'ingreso') {
        map[key] = DailyBucket(date: prev.date, ingresos: prev.ingresos + t.monto, egresos: prev.egresos);
      } else {
        map[key] = DailyBucket(date: prev.date, ingresos: prev.ingresos, egresos: prev.egresos + t.monto);
      }
    }

    return map.values.toList();
  }
}
