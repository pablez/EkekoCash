import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_application_1/data/db_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database migration tests', () {
    test('should create categorias table with all required columns', () async {
      // Create fresh database
      await DBProvider.init(inMemory: true);
      final db = await DBProvider.database;

      // Check if categorias table has all expected columns
      final pragma = await db.rawQuery('PRAGMA table_info(categorias)');
      final columnNames = pragma.map((row) => row['name'] as String).toSet();

      expect(columnNames.contains('categoria_id'), isTrue);
      expect(columnNames.contains('nombre'), isTrue);
      expect(columnNames.contains('tipo'), isTrue);
      expect(columnNames.contains('color_hex'), isTrue);
      expect(columnNames.contains('icon_name'), isTrue);
      expect(columnNames.contains('created_at'), isTrue);

      print('Categorias table columns: $columnNames');
    });

    test('should create seed categorias with color and icons', () async {
      await DBProvider.init(inMemory: true);
      final db = await DBProvider.database;

      final result = await db.query('categorias');
      expect(result.length, greaterThanOrEqualTo(3));

      // Check that default categories have color and icon
      final salario = result.firstWhere((row) => row['nombre'] == 'Salario');
      expect(salario['color_hex'], isNotNull);
      expect(salario['icon_name'], isNotNull);
      expect(salario['icon_name'], equals('money'));

      print('Default categorias: $result');
    });
  });
}