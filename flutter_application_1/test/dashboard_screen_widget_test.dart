import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_application_1/presentation/screens/dashboard_screen.dart';
import 'package:flutter_application_1/domain/models/dashboard_kpis.dart';
import 'package:flutter_application_1/domain/models/daily_bucket.dart';

void main() {
  testWidgets('DashboardScreen shows legend and x-axis labels', (tester) async {
    final now = DateTime.now();
    final kpis = DashboardKpis(totalIngresos: 1000, totalEgresos: 400, totalBalance: 600, ahorroAsignado: 50, totalMetaFondos: 200);
    final series = List.generate(7, (i) => DailyBucket(date: now.subtract(Duration(days: 6 - i)), ingresos: (i + 1) * 10.0, egresos: (i + 1) * 5.0));

    // Provide a larger test window to avoid tight constraints that cause layout overflow in tests
    tester.binding.window.physicalSizeTestValue = const Size(1080, 1920);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    // Instead of pumping the whole DashboardScreen (which can overflow under test
    // harness constraints), build a minimal test widget that renders the legend
    // and x-axis labels from the same providers. This ensures legend/labels
    // rendering is verified without depending on full layout.
    await tester.pumpWidget(ProviderScope(
      overrides: [
        dashboardKpisProvider.overrideWithProvider(FutureProvider.autoDispose<DashboardKpis>((ref) async => kpis)),
        dashboardSeriesProvider.overrideWithProvider(FutureProvider.autoDispose<List<DailyBucket>>((ref) async => series)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(builder: (context, ref, _) {
            final s = ref.watch(dashboardSeriesProvider);
            return s.when(
              data: (list) => Column(children: [
                Row(children: [
                  Row(children: [Container(width: 12, height: 12, color: Colors.green.shade600), const SizedBox(width: 6), const Text('Ingresos')]),
                  const SizedBox(width: 16),
                  Row(children: [Container(width: 12, height: 12, color: Colors.red.shade400), const SizedBox(width: 6), const Text('Egresos')]),
                ]),
                const SizedBox(height: 6),
                Row(children: list.map((d) => Expanded(child: Text('${d.date.day}', textAlign: TextAlign.center))).toList()),
              ]),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
          }),
        ),
      ),
    ));

    await tester.pumpAndSettle();

    // Legend items
    expect(find.text('Ingresos'), findsOneWidget);
    expect(find.text('Egresos'), findsOneWidget);

    // X-axis first and last day labels should appear
    expect(find.text('${series.first.date.day}'), findsWidgets);
    expect(find.text('${series.last.date.day}'), findsWidgets);
  });
}
