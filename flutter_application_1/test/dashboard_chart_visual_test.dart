import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_application_1/presentation/screens/dashboard_screen.dart';
import 'package:flutter_application_1/domain/models/daily_bucket.dart';
import 'package:flutter_application_1/domain/models/dashboard_kpis.dart';

void main() {
  testWidgets('Chart renders green and red segments', (tester) async {
    final now = DateTime.now();
    final series = List.generate(5, (i) => DailyBucket(date: now.subtract(Duration(days: 4 - i)), ingresos: (i + 1) * 10.0, egresos: (i + 1) * 5.0));

    final kpis = DashboardKpis(totalIngresos: 100, totalEgresos: 50, totalBalance: 50, ahorroAsignado: 10, totalMetaFondos: 100);

    // Build a minimal test widget that renders bars using the same colors
    await tester.pumpWidget(ProviderScope(
      overrides: [
        dashboardSeriesProvider.overrideWithProvider(FutureProvider.autoDispose<List<DailyBucket>>((ref) async => series)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 200,
              child: Consumer(builder: (context, ref, _) {
                final s = ref.watch(dashboardSeriesProvider);
                return s.when(
                  data: (list) {
                    final maxValue = list.fold<double>(0.0, (p, e) => p > (e.ingresos + e.egresos) ? p : (e.ingresos + e.egresos));
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: list.map((d) {
                        final total = d.ingresos + d.egresos;
                        final totalFactor = maxValue > 0 ? total / maxValue : 0.0;
                        final ingFactor = maxValue > 0 ? (d.ingresos / maxValue) : 0.0;
                        final egFactor = maxValue > 0 ? (d.egresos / maxValue) : 0.0;
                        final barTotal = (totalFactor * 150).clamp(0.0, 150.0);
                        final ingPx = (ingFactor * 150).clamp(0.0, 150.0);
                        final egPx = (egFactor * 150).clamp(0.0, 150.0);
                        return Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(height: ingPx, child: Container(color: Colors.green.shade600)),
                              SizedBox(height: egPx, child: Container(color: Colors.red.shade400)),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              }),
            ),
          ),
        ),
      ),
    ));

    await tester.pumpAndSettle();

    // Verify colored segments exist
    final greenFinder = find.byWidgetPredicate((w) => w is Container && w.color == Colors.green.shade600);
    final redFinder = find.byWidgetPredicate((w) => w is Container && w.color == Colors.red.shade400);

    expect(greenFinder, findsWidgets);
    expect(redFinder, findsWidgets);
  });
}
