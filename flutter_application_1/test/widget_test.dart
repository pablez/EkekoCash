// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Registro rápido screen shows monto field', (WidgetTester tester) async {
    // Inicializar sqflite ffi para que DBProvider funcione durante el test de widget
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Esperamos que el campo 'Monto' y el botón 'Guardar' estén presentes
    expect(find.text('Monto'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
  });
}
