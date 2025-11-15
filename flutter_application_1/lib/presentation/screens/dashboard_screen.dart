import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../domain/models/dashboard_kpis.dart';
import '../../domain/models/daily_bucket.dart';
import '../../domain/usecases/get_dashboard_kpis_usecase.dart';
import '../../app_providers.dart';

final dashboardKpisProvider = FutureProvider.autoDispose<DashboardKpis>((ref) async {
  final transRepo = ref.read(transaccionRepositoryProvider);
  final cuentaRepo = ref.read(cuentaRepositoryProvider);
  final fondoRepo = ref.read(fondoRepositoryProvider);
  final usecase = GetDashboardKpisUseCase(transRepo, cuentaRepo, fondoRepo);
  final to = DateTime.now();
  final from = to.subtract(const Duration(days: 30));
  return usecase.execute(from: from, to: to);
});

final dashboardSeriesProvider = FutureProvider.autoDispose<List<DailyBucket>>((ref) async {
  final transRepo = ref.read(transaccionRepositoryProvider);
  final cuentaRepo = ref.read(cuentaRepositoryProvider);
  final fondoRepo = ref.read(fondoRepositoryProvider);
  final usecase = GetDashboardKpisUseCase(transRepo, cuentaRepo, fondoRepo);
  final to = DateTime.now();
  final from = to.subtract(const Duration(days: 30));
  return usecase.getDailySeries(from: from, to: to);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(dashboardKpisProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: kpisAsync.when(
        data: (k) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(child: _KpiCard(title: 'Ingresos', value: k.totalIngresos, color: Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _KpiCard(title: 'Egresos', value: k.totalEgresos, color: Colors.red)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _KpiCard(title: 'Balance', value: k.totalBalance, color: Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _KpiCard(title: 'Ahorro', value: k.ahorroAsignado, color: Colors.orange)),
              ]),
              const SizedBox(height: 18),
              const SizedBox(height: 12),
              SizedBox(height: 240, child: _IncomeExpenseBarChart()),
              const SizedBox(height: 12),
              Center(child: _AhorroIndicator()),
              const SizedBox(height: 8),
              Expanded(child: Center(child: Text('Detalles y lista de cuentas (próximamente)', style: Theme.of(context).textTheme.titleMedium))),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error cargando KPIs')),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  const _KpiCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(value.toStringAsFixed(2), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _IncomeExpenseBarChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(dashboardSeriesProvider);
    return seriesAsync.when(
      data: (series) {
        if (series.isEmpty) return const Center(child: Text('No hay datos'));
        // Simple custom stacked bar chart using Containers for compatibility in tests.
        final maxValue = series.fold<double>(0.0, (s, d) => s > (d.ingresos + d.egresos) ? s : (d.ingresos + d.egresos));
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: LayoutBuilder(builder: (context, constraints) {
            // Use available height to compute pixel heights and avoid multiplying
            // Infinity by 0.0 (which produces NaN). Provide a safe fallback.
            final availableHeight = (constraints.maxHeight.isFinite && constraints.maxHeight > 0)
                ? constraints.maxHeight
                : 200.0;
            // Build legend + chart + x-axis labels inside a constrained box
            const legendHeight = 20.0;
            const labelsHeight = 18.0;
            final barsAreaHeight = (availableHeight - legendHeight - labelsHeight - 8.0).clamp(0.0, availableHeight);

            return SizedBox(
              height: availableHeight,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Legend (fixed height)
                  SizedBox(
                    height: legendHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(children: [Container(width: 12, height: 12, color: Colors.green.shade600), const SizedBox(width: 6), const Text('Ingresos')]),
                          const SizedBox(width: 16),
                          Row(children: [Container(width: 12, height: 12, color: Colors.red.shade400), const SizedBox(width: 6), const Text('Egresos')]),
                        ],
                      ),
                    ),
                  ),

                  // Chart bars (expand to remaining space)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: series.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final d = entry.value;
                        final total = d.ingresos + d.egresos;
                        final totalFactor = maxValue > 0 ? total / maxValue : 0.0;
                        final egFactor = maxValue > 0 ? (d.egresos / maxValue) : 0.0;
                        final ingFactor = maxValue > 0 ? (d.ingresos / maxValue) : 0.0;
                        final barTotalHeight = (totalFactor * barsAreaHeight).clamp(0.0, barsAreaHeight);
                        final ingHeightPx = (ingFactor * barsAreaHeight).clamp(0.0, barsAreaHeight);
                        final egHeightPx = (egFactor * barsAreaHeight).clamp(0.0, barsAreaHeight);

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: barTotalHeight),
                                  duration: Duration(milliseconds: 400 + (idx * 20)),
                                  builder: (context, animatedHeight, child) {
                                    final ingAnimated = (barTotalHeight > 0) ? (ingHeightPx / barTotalHeight) * animatedHeight : 0.0;
                                    final egAnimated = (barTotalHeight > 0) ? (egHeightPx / barTotalHeight) * animatedHeight : 0.0;
                                    return SizedBox(
                                      height: animatedHeight,
                                      width: double.infinity,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          SizedBox(height: ingAnimated, width: double.infinity, child: Container(color: Colors.green.shade600)),
                                          SizedBox(height: egAnimated, width: double.infinity, child: Container(color: Colors.red.shade400)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // X-axis labels (fixed height)
                  SizedBox(
                    height: labelsHeight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Row(
                        children: series.map((d) {
                          return Expanded(child: Text('${d.date.day}/${d.date.month}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)));
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error cargando series')),
    );
  }
}

class _AhorroIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(dashboardKpisProvider);
    return kpisAsync.when(
      data: (k) {
        final percent = k.totalMetaFondos > 0 ? (k.ahorroAsignado / k.totalMetaFondos).clamp(0.0, 1.0) : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: LinearPercentIndicator(
            lineHeight: 14.0,
            percent: percent,
            center: Text('${(percent * 100).toStringAsFixed(0)}% Ahorro'),
            progressColor: Colors.orange,
            backgroundColor: Colors.orange.shade100,
            barRadius: const Radius.circular(8),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
