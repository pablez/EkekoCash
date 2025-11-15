import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_application_1/data/db_provider.dart';
import 'package:flutter_application_1/data/repositories/categoria_repository.dart';
import 'package:flutter_application_1/data/models/categoria_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Categoria color and icon persistence', () {
    test('should save and retrieve color_hex and icon_name correctly', () async {
      // Create in-memory database
      await DBProvider.init(inMemory: true);
      final repo = CategoriaRepository();

      // Create categoria with color and icon
      final categoria = Categoria(
        nombre: 'Test Category',
        tipo: 'Egreso',
        colorHex: '#FF5722',
        iconName: 'shopping',
      );

      // Insert categoria
      final id = await repo.insertCategoria(categoria);
      expect(id, greaterThan(0));

      // Retrieve categoria
      final retrieved = await repo.getCategoriaById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.nombre, equals('Test Category'));
      expect(retrieved.colorHex, equals('#FF5722'));
      expect(retrieved.iconName, equals('shopping'));
      expect(retrieved.tipo, equals('Egreso'));

      // Update categoria with different color and icon
      final updated = Categoria(
        categoriaId: id,
        nombre: 'Updated Category',
        tipo: 'Ingreso',
        colorHex: '#4CAF50',
        iconName: 'money',
      );

      final updateResult = await repo.updateCategoria(updated);
      expect(updateResult, equals(1));

      // Retrieve updated categoria
      final retrievedUpdated = await repo.getCategoriaById(id);
      expect(retrievedUpdated, isNotNull);
      expect(retrievedUpdated!.nombre, equals('Updated Category'));
      expect(retrievedUpdated.colorHex, equals('#4CAF50'));
      expect(retrievedUpdated.iconName, equals('money'));
      expect(retrievedUpdated.tipo, equals('Ingreso'));
    });

    test('should handle null color and icon correctly', () async {
      await DBProvider.init(inMemory: true);
      final repo = CategoriaRepository();

      // Create categoria without color and icon
      final categoria = Categoria(
        nombre: 'No Color Category',
        tipo: 'Egreso',
      );

      final id = await repo.insertCategoria(categoria);
      final retrieved = await repo.getCategoriaById(id);
      
      expect(retrieved, isNotNull);
      expect(retrieved!.colorHex, isNull);
      expect(retrieved.iconName, isNull);
    });
  });
}