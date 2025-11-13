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
      version: 1,
      onCreate: _onCreate,
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
        tipo_moneda TEXT
      );
    ''');

    // Seed some default cuentas
    await db.insert('cuentas', {'nombre': 'Efectivo', 'saldo_inicial': 500.0, 'tipo_moneda': 'BOB'});
    await db.insert('cuentas', {'nombre': 'Cuenta Banco', 'saldo_inicial': 1200.0, 'tipo_moneda': 'BOB'});

    await db.execute('''
      CREATE TABLE categorias (
        categoria_id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        tipo TEXT NOT NULL CHECK(tipo IN ('Ingreso','Egreso'))
      );
    ''');

    // Seed some default categorias
    await db.insert('categorias', {'nombre': 'Salario', 'tipo': 'Ingreso'});
    await db.insert('categorias', {'nombre': 'Alimentos', 'tipo': 'Egreso'});
    await db.insert('categorias', {'nombre': 'Transporte', 'tipo': 'Egreso'});

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
        descripcion TEXT,
        cuenta_id INTEGER NOT NULL REFERENCES cuentas(cuenta_id),
        subcategoria_id INTEGER REFERENCES subcategorias(subcategoria_id),
        miembro_id INTEGER REFERENCES miembros(miembro_id),
        tipo TEXT NOT NULL CHECK(tipo IN ('Ingreso','Egreso'))
      );
    ''');

    await db.execute('''
      CREATE TABLE fondos (
        fondo_id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        meta_monto REAL DEFAULT 0,
        fecha_meta TEXT,
        icono_id INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE asignaciones_ahorro (
        asignacion_id INTEGER PRIMARY KEY AUTOINCREMENT,
        monto_asignado REAL NOT NULL,
        transaccion_id INTEGER NOT NULL REFERENCES transacciones(transaccion_id) ON DELETE CASCADE,
        fondo_id INTEGER NOT NULL REFERENCES fondos(fondo_id)
      );
    ''');

    await db.execute('CREATE INDEX idx_transacciones_fecha ON transacciones(fecha);');
    await db.execute('CREATE INDEX idx_transacciones_cuenta ON transacciones(cuenta_id);');
    await db.execute('CREATE INDEX idx_transacciones_subcategoria ON transacciones(subcategoria_id);');
  }

  static Future<Database> get database async => await init();
}
