import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBProvider {
  DBProvider._();

  static Database? _database;

  /// Inicializa la base de datos. Si inMemory = true usa una DB en memoria (útil para tests).
  static Future<Database> init({bool inMemory = false}) async {
    if (_database != null) return _database!;

    final String path;
    if (inMemory) {
      path = inMemoryDatabasePath;
    } else {
      final databasesPath = await getDatabasesPath();
      path = join(databasesPath, 'ekeko_cash.db');
    }

    _database = await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add new column to store amounts as integer cents and migrate existing REAL values
          await db.execute('ALTER TABLE transacciones ADD COLUMN monto_cents INTEGER');
          // Convert existing monto (REAL) to monto_cents = ROUND(monto * 100)
          await db.execute('UPDATE transacciones SET monto_cents = CAST(ROUND(monto * 100) AS INTEGER) WHERE monto IS NOT NULL');

          // Migrate cuentas: add saldo_cents and populate from saldo_inicial
          await db.execute('ALTER TABLE cuentas ADD COLUMN saldo_cents INTEGER');
          await db.execute('UPDATE cuentas SET saldo_cents = CAST(ROUND(saldo_inicial * 100) AS INTEGER) WHERE saldo_inicial IS NOT NULL');

          // Migrate fondos: add meta_monto_cents and populate
          await db.execute('ALTER TABLE fondos ADD COLUMN meta_monto_cents INTEGER');
          await db.execute('UPDATE fondos SET meta_monto_cents = CAST(ROUND(meta_monto * 100) AS INTEGER) WHERE meta_monto IS NOT NULL');

          // Migrate asignaciones_ahorro: add monto_asignado_cents and populate
          await db.execute('ALTER TABLE asignaciones_ahorro ADD COLUMN monto_asignado_cents INTEGER');
          await db.execute('UPDATE asignaciones_ahorro SET monto_asignado_cents = CAST(ROUND(monto_asignado * 100) AS INTEGER) WHERE monto_asignado IS NOT NULL');
        }

        if (oldVersion < 3) {
          // Add categorias table and subcategorias table if they don't exist
          await db.execute('''CREATE TABLE IF NOT EXISTS categorias (
            categoria_id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            tipo TEXT NOT NULL CHECK(tipo IN ('Ingreso','Egreso')),
            color_hex TEXT,
            icon_name TEXT,
            created_at TEXT
          );''');

          await db.execute('''CREATE TABLE IF NOT EXISTS subcategorias (
            subcategoria_id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            categoria_id INTEGER NOT NULL REFERENCES categorias(categoria_id) ON DELETE CASCADE
          );''');

          // Seed some default categorias (if table empty)
          final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM categorias')) ?? 0;
          if (count == 0) {
            await db.insert('categorias', {'nombre': 'Salario', 'tipo': 'Ingreso', 'icon_name': 'money', 'created_at': DateTime.now().toIso8601String()});
            await db.insert('categorias', {'nombre': 'Alimentos', 'tipo': 'Egreso', 'icon_name': 'food', 'created_at': DateTime.now().toIso8601String()});
            await db.insert('categorias', {'nombre': 'Transporte', 'tipo': 'Egreso', 'icon_name': 'transport', 'created_at': DateTime.now().toIso8601String()});
          }

          // Ensure categorias table has new columns (color_hex, created_at) when upgrading
          final pragmaCat = await db.rawQuery('PRAGMA table_info(categorias)');
          final hasColor = pragmaCat.any((row) => row['name'] == 'color_hex');
          final hasIcon = pragmaCat.any((row) => row['name'] == 'icon_name');
          final hasCreatedAt = pragmaCat.any((row) => row['name'] == 'created_at');
          if (!hasColor) {
            await db.execute('ALTER TABLE categorias ADD COLUMN color_hex TEXT');
          }
          if (!hasIcon) {
            await db.execute('ALTER TABLE categorias ADD COLUMN icon_name TEXT');
          }
          if (!hasCreatedAt) {
            await db.execute('ALTER TABLE categorias ADD COLUMN created_at TEXT');
            // Optionally populate created_at for existing rows
            await db.execute("UPDATE categorias SET created_at = ? WHERE created_at IS NULL", [DateTime.now().toIso8601String()]);
          }

          // Add categoria_id column to transacciones (nullable for migration)
          final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='transacciones'");
          if (tables.isNotEmpty) {
            // Only add if column doesn't exist
            final pragma = await db.rawQuery('PRAGMA table_info(transacciones)');
            final hasCategoria = pragma.any((row) => row['name'] == 'categoria_id');
            if (!hasCategoria) {
              await db.execute('ALTER TABLE transacciones ADD COLUMN categoria_id INTEGER');
            }
          }

          // Create index for categoria lookup
          await db.execute('CREATE INDEX IF NOT EXISTS idx_transacciones_categoria ON transacciones(categoria_id);');
        }

        if (oldVersion < 4) {
          // Ensure categorias table has icon_name column (sometimes missing in v3 upgrade)
          final pragmaCat = await db.rawQuery('PRAGMA table_info(categorias)');
          final hasIcon = pragmaCat.any((row) => row['name'] == 'icon_name');
          if (!hasIcon) {
            await db.execute('ALTER TABLE categorias ADD COLUMN icon_name TEXT');
          }
        }
      },
    );

    return _database!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE miembros (
        miembro_id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        color_perfil TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE cuentas (
        cuenta_id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        saldo_inicial REAL DEFAULT 0,
        saldo_cents INTEGER,
        tipo_moneda TEXT
      );
    ''');

    // Seed some default cuentas (store both legacy REAL and cents)
    await db.insert('cuentas', {'nombre': 'Efectivo', 'saldo_inicial': 500.0, 'saldo_cents': 50000, 'tipo_moneda': 'BOB'});
    await db.insert('cuentas', {'nombre': 'Cuenta Banco', 'saldo_inicial': 1200.0, 'saldo_cents': 120000, 'tipo_moneda': 'BOB'});

    await db.execute('''
      CREATE TABLE categorias (
        categoria_id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        tipo TEXT NOT NULL CHECK(tipo IN ('Ingreso','Egreso')),
        color_hex TEXT,
        icon_name TEXT,
        created_at TEXT
      );
    ''');

    // Seed some default categorias
    await db.insert('categorias', {'nombre': 'Salario', 'tipo': 'Ingreso', 'icon_name': 'money', 'color_hex': '#4CAF50', 'created_at': DateTime.now().toIso8601String()});
    await db.insert('categorias', {'nombre': 'Alimentos', 'tipo': 'Egreso', 'icon_name': 'food', 'color_hex': '#FF5722', 'created_at': DateTime.now().toIso8601String()});
    await db.insert('categorias', {'nombre': 'Transporte', 'tipo': 'Egreso', 'icon_name': 'car', 'color_hex': '#2196F3', 'created_at': DateTime.now().toIso8601String()});

    await db.execute('''
      CREATE TABLE subcategorias (
        subcategoria_id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        categoria_id INTEGER NOT NULL REFERENCES categorias(categoria_id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE transacciones (
        transaccion_id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        monto REAL NOT NULL,
        monto_cents INTEGER,
        descripcion TEXT,
        cuenta_id INTEGER NOT NULL REFERENCES cuentas(cuenta_id),
        subcategoria_id INTEGER REFERENCES subcategorias(subcategoria_id),
        categoria_id INTEGER REFERENCES categorias(categoria_id),
        miembro_id INTEGER REFERENCES miembros(miembro_id),
        tipo TEXT NOT NULL CHECK(tipo IN ('Ingreso','Egreso'))
      );
    ''');

    await db.execute('''
      CREATE TABLE fondos (
        fondo_id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        meta_monto REAL DEFAULT 0,
        meta_monto_cents INTEGER,
        fecha_meta TEXT,
        icono_id INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE asignaciones_ahorro (
        asignacion_id INTEGER PRIMARY KEY AUTOINCREMENT,
        monto_asignado REAL NOT NULL,
        monto_asignado_cents INTEGER,
        transaccion_id INTEGER NOT NULL REFERENCES transacciones(transaccion_id) ON DELETE CASCADE,
        fondo_id INTEGER NOT NULL REFERENCES fondos(fondo_id)
      );
    ''');

    await db.execute('CREATE INDEX idx_transacciones_fecha ON transacciones(fecha);');
    await db.execute('CREATE INDEX idx_transacciones_cuenta ON transacciones(cuenta_id);');
    await db.execute('CREATE INDEX idx_transacciones_subcategoria ON transacciones(subcategoria_id);');
    await db.execute('CREATE INDEX idx_transacciones_categoria ON transacciones(categoria_id);');
  }

  static Future<Database> get database async => await init();
}
