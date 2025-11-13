Elemento,Descripción
Nombre del Proyecto,EkekoCash 💰🇧🇴
Público Objetivo,Familias en Bolivia.

# EkekoCash — Documentación técnica y plan de implementación

EkekoCash es una aplicación de finanzas personales pensada para familias en Bolivia. Su objetivo principal es ofrecer control total offline de ingresos y gastos, con soporte para múltiples fondos de ahorro y un registro extremadamente rápido y cómodo.

## Resumen rápido
- Stack: Flutter (Dart), SQLite (`sqflite`), Riverpod, Fl Chart
- Arquitectura: Repository pattern + Riverpod para estado
- Enfoque: 100% offline, UI optimizada para registro rápido (teclado numérico auto-open, selector de miembro, asignación de fondos)

## Estructura propuesta (alto nivel)
- data/
    - db_provider.dart (inicialización y migraciones)
    - models/ (modelos DB)
    - repositories/ (CRUD y transacciones atómicas)
- domain/
    - notifiers/ (Riverpod state notifiers)
    - usecases/ (opcional)
- presentation/
    - screens/
    - widgets/
    - styles/

## Arquitectura de código (detallada)
Se sigue el patrón Repository + UseCases + Notifiers (Riverpod). La idea es mantener la UI sin lógica, delegando reglas de negocio a los usecases y la persistencia a los repositorios.

1) Capas y responsabilidades
- data/: implementación concreta de acceso a datos (SQLite). Contiene `db_provider.dart`, modelos y repositorios concretos que implementan interfaces en `domain/repositories`.
- domain/: contratos y lógica de negocio. Aquí se colocan las interfaces de repositorio (`ITransaccionRepository`), los casos de uso (ej: `CreateTransaccionUseCase`) y los notifiers (StateNotifier) que exponen estado a la UI.
- presentation/: UI (screens + widgets). Consume notifiers a través de providers y ejecuta usecases cuando se requiere lógica.

2) Flujo típico al crear una transacción
- La UI (ej. `registro_rapido_screen.dart`) recoge los datos y llama al `transaccionNotifier` o directamente a un UseCase.
- `TransaccionNotifier` (StateNotifier) orquesta el llamado al UseCase `CreateTransaccionUseCase`.
- `CreateTransaccionUseCase` valida reglas y llama a `ITransaccionRepository.insert`.
- La implementación concreta `TransaccionRepository` (en data/repositories) inserta la fila en SQLite usando `DBProvider` y retorna el id.
- El Notifier actualiza el estado y la UI se re-renderiza.

3) Contratos y ejemplos
- Interfaz: `lib/domain/repositories/i_transaccion_repository.dart` (métodos: insert, update, delete, getAll, getBalanceByCuenta)
- UseCase: `lib/domain/usecases/create_transaccion_usecase.dart` (valida monto > 0, reglas de negocio)
- Notifier: `lib/domain/notifiers/transaccion_notifier.dart` (expone lista de transacciones y métodos add/remove)

4) Integración con Riverpod
- Registrar `TransaccionRepository` como provider concreto en el `ProviderScope` principal (o en un archivo de wiring). Ejemplo rápido:

```dart
final transaccionRepositoryProvider = Provider<ITransaccionRepository>((ref) => TransaccionRepository());
final transaccionNotifierProvider = StateNotifierProvider<TransaccionNotifier, List<Transaccion>>((ref) {
  final repo = ref.read(transaccionRepositoryProvider);
  return TransaccionNotifier(repo);
});
```

5) Tests
- Testear UseCases (reglas de negocio) con repositorios mock.
- Testear Repositorios con una base de datos en memoria (sqflite supports in-memory DB) o usando SQL file provider.

6) Siguientes acciones recomendadas (implementación inmediata)
- Añadir wiring/Providers en `main.dart` con `ProviderScope` y registrar `TransaccionRepository`.
- Implementar migración `onCreate` en `DBProvider` con DDL del README.
- Escribir tests unitarios para `CreateTransaccionUseCase` y `TransaccionRepository`.

## Entidades y relaciones (ER) — resumen
- Miembros (miembro_id, nombre, color_perfil)
- Cuentas (cuenta_id, nombre, saldo_inicial, tipo_moneda)
- Categorias (categoria_id, nombre, tipo: Ingreso/Egreso)
- Subcategorias (subcategoria_id, nombre, categoria_id)
- Transacciones (transaccion_id, fecha, monto, descripcion, cuenta_id, subcategoria_id, miembro_id, tipo)
- Fondos (fondo_id, nombre, meta_monto, fecha_meta, icono_id)
- Asignaciones_Ahorro (asignacion_id, monto_asignado, transaccion_id, fondo_id)

Relaciones clave: Miembros -> Transacciones, Cuentas -> Transacciones, Categorias -> Subcategorias -> Transacciones, Transacciones -> Asignaciones_Ahorro -> Fondos

## Esquema SQLite (DDL aproximado)
-- Tabla `miembros`
CREATE TABLE miembros (
    miembro_id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    color_perfil TEXT
);

-- Tabla `cuentas`
CREATE TABLE cuentas (
    cuenta_id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    saldo_inicial REAL DEFAULT 0,
    tipo_moneda TEXT
);

-- Tabla `categorias`
CREATE TABLE categorias (
    categoria_id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    tipo TEXT NOT NULL CHECK(tipo IN ('Ingreso','Egreso'))
);

-- Tabla `subcategorias`
CREATE TABLE subcategorias (
    subcategoria_id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    categoria_id INTEGER NOT NULL REFERENCES categorias(categoria_id) ON DELETE CASCADE
);

-- Tabla `transacciones`
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

-- Tabla `fondos`
CREATE TABLE fondos (
    fondo_id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    meta_monto REAL DEFAULT 0,
    fecha_meta TEXT,
    icono_id INTEGER
);

-- Tabla `asignaciones_ahorro`
CREATE TABLE asignaciones_ahorro (
    asignacion_id INTEGER PRIMARY KEY AUTOINCREMENT,
    monto_asignado REAL NOT NULL,
    transaccion_id INTEGER NOT NULL REFERENCES transacciones(transaccion_id) ON DELETE CASCADE,
    fondo_id INTEGER NOT NULL REFERENCES fondos(fondo_id)
);

-- Índices sugeridos
CREATE INDEX idx_transacciones_fecha ON transacciones(fecha);
CREATE INDEX idx_transacciones_cuenta ON transacciones(cuenta_id);
CREATE INDEX idx_transacciones_subcategoria ON transacciones(subcategoria_id);

## MVP sugerido (prioridad)
Nivel 0 (MVP mínimo):
- DB + modelos: Miembros, Cuentas, Categorias, Subcategorias, Transacciones
- CRUD de Transacciones y listado
- Cálculo de saldo por cuenta
- Pantalla de registro rápido (autofocus, teclado numérico)
- Riverpod notifiers para transacciones y saldos

Nivel 1:
- Fondos y Asignaciones_Ahorro
- Reporte simple mensual + gráficos con Fl Chart
- Selector de miembro con avatar/initials

Nivel 2:
- Simulador de hipótesis, transacciones recurrentes, reparto avanzado entre fondos

## Registro rápido — especificación técnica (UI)
- Abrir con `showModalBottomSheet` o nueva Page con `autofocus: true` en el campo de monto
- `TextFormField` para monto: `keyboardType: TextInputType.numberWithOptions(decimal: true)`
Elemento,Descripción
Nombre del Proyecto,EkekoCash 💰🇧🇴
Público objetivo,Familias en Bolivia

## EkekoCash — Resumen técnico y plan de implementación

EkekoCash es una aplicación de finanzas personales diseñada para familias en Bolivia. Su objetivo es ofrecer control total offline de ingresos y gastos, con soporte para múltiples fondos de ahorro y un registro rápido y cómodo.

### Resumen rápido
- Stack: Flutter (Dart), SQLite (`sqflite`), Riverpod, Fl_Chart
- Arquitectura: Repository pattern + Riverpod para gestión de estado
- Enfoque: 100% offline; UI optimizada para registro rápido (autofocus en monto, teclado numérico, selector de miembro, asignación a fondos)

### Estructura propuesta (alto nivel)
- data/
    - `db_provider.dart` (inicialización y migraciones)
    - models/ (modelos DB)
    - repositories/ (CRUD y transacciones atómicas)
- domain/
    - notifiers/ (Riverpod StateNotifiers)
    - usecases/ (opcional)
- presentation/
    - screens/
    - widgets/
    - styles/

### Arquitectura (contrato breve)
- Mantener la UI sin lógica: UseCases validan reglas de negocio; Repositories hacen persistencia; Notifiers exponen estado a la UI.

Flujo al crear una transacción:
1. La UI (p. ej. `registro_rapido_screen.dart`) colecta datos y llama al Notifier o a un UseCase.
2. `TransaccionNotifier` orquesta y llama a `CreateTransaccionUseCase`.
3. `CreateTransaccionUseCase` valida y llama a `ITransaccionRepository.insert`.
4. `TransaccionRepository` inserta en SQLite mediante `DBProvider` y devuelve el id.
5. El Notifier actualiza el estado; la UI se re-renderiza.

Ejemplo de wiring (Riverpod):

```dart
final transaccionRepositoryProvider = Provider<ITransaccionRepository>((ref) => TransaccionRepository());
final transaccionNotifierProvider = StateNotifierProvider<TransaccionNotifier, List<Transaccion>>((ref) {
    final repo = ref.read(transaccionRepositoryProvider);
    return TransaccionNotifier(repo);
});
```

### Tests recomendados
- Unit tests para UseCases (mock de repositorios).
- Tests de repositorio con DB en memoria (sqflite: in-memory) para validar CRUD y transacciones.

### Entidades principales (resumen ER)
- Miembros (miembro_id, nombre, color_perfil)
- Cuentas (cuenta_id, nombre, saldo_inicial, tipo_moneda)
- Categorías (categoria_id, nombre, tipo: Ingreso/Egreso)
- Subcategorías (subcategoria_id, nombre, categoria_id)
- Transacciones (transaccion_id, fecha, monto, descripcion, cuenta_id, subcategoria_id, miembro_id, tipo)
- Fondos (fondo_id, nombre, meta_monto, fecha_meta, icono_id)
- Asignaciones_Ahorro (asignacion_id, monto_asignado, transaccion_id, fondo_id)

Relaciones clave: Miembros → Transacciones; Cuentas → Transacciones; Categorías → Subcategorías → Transacciones; Transacciones → Asignaciones_Ahorro → Fondos.

### Esquema SQLite (DDL — versión inicial)
-- Tabla `miembros`
CREATE TABLE miembros (
    miembro_id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    color_perfil TEXT
);

-- Tabla `cuentas`
CREATE TABLE cuentas (
    cuenta_id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    saldo_inicial REAL DEFAULT 0,
    tipo_moneda TEXT
);

-- Tabla `categorias`
CREATE TABLE categorias (
    categoria_id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    tipo TEXT NOT NULL CHECK(tipo IN ('Ingreso','Egreso'))
);

-- Tabla `subcategorias`
CREATE TABLE subcategorias (
    subcategoria_id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    categoria_id INTEGER NOT NULL REFERENCES categorias(categoria_id) ON DELETE CASCADE
);

-- Tabla `transacciones`
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

-- Tabla `fondos`
CREATE TABLE fondos (
    fondo_id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    meta_monto REAL DEFAULT 0,
    fecha_meta TEXT,
    icono_id INTEGER
);

-- Tabla `asignaciones_ahorro`
CREATE TABLE asignaciones_ahorro (
    asignacion_id INTEGER PRIMARY KEY AUTOINCREMENT,
    monto_asignado REAL NOT NULL,
    transaccion_id INTEGER NOT NULL REFERENCES transacciones(transaccion_id) ON DELETE CASCADE,
    fondo_id INTEGER NOT NULL REFERENCES fondos(fondo_id)
);

-- Índices sugeridos
CREATE INDEX idx_transacciones_fecha ON transacciones(fecha);
CREATE INDEX idx_transacciones_cuenta ON transacciones(cuenta_id);
CREATE INDEX idx_transacciones_subcategoria ON transacciones(subcategoria_id);

### MVP sugerido (prioridades)
Nivel 0 (MVP mínimo):
- DB + modelos: Miembros, Cuentas, Categorías, Subcategorías, Transacciones
- CRUD de Transacciones y listado
- Cálculo de saldo por cuenta
- Pantalla de registro rápido (autofocus en monto y teclado numérico)
- Riverpod notifiers para transacciones y saldos

Nivel 1:
- Fondos y Asignaciones_Ahorro
- Reporte mensual + gráficos con Fl_Chart
- Selector de miembro con avatar/initials

Nivel 2:
- Simulador de hipótesis, transacciones recurrentes, reparto avanzado entre fondos

### Registro rápido — especificación técnica (UI)
- Abrir con `showModalBottomSheet` o nueva Page con `autofocus: true` en el campo de monto para que el teclado numérico aparezca automáticamente.
- `TextFormField` para monto: `keyboardType: TextInputType.numberWithOptions(decimal: true)`.
- Selección de categoría: GridView con botones (icon + label).
- Subcategorías: Chips horizontales que cambian según la categoría.
- Selector de miembro: fila de `CircleAvatar`.
- Selector de cuenta: `DropdownButton` o fila de botones con saldo.
- Botón grande de guardar; `onTap` para guardado rápido, `onLongPress` para opciones avanzadas.
- Asignación a fondos (si ingreso): modal con slider de porcentaje y tarjetas por fondo.

Validaciones mínimas: monto > 0; cuenta seleccionada. Manejar errores DB con Snackbars. Usar transacciones SQLite al insertar transacción + asignaciones.

### Backlog técnico inicial (estimaciones)
1. Init `db_provider.dart` + migraciones (1 día)
2. Implementar modelos y `transaccion_repository.dart` + tests (1–2 días)
3. `transaccion_notifier.dart` + `registro_rapido_screen.dart` minimal (2 días)
4. Fondos + asignaciones + UI slider (2 días)
5. Dashboard con gráfico básico (2 días)

### Checklist inmediato
- [ ] Crear carpetas: `data/models`, `data/repositories`, `domain/notifiers`, `presentation/screens`, `presentation/widgets`
- [ ] Implementar `db_provider.dart` con DDL anterior y version = 1
- [ ] Implementar `transaccion_model.dart` y `transaccion_repository.dart`
- [ ] Implementar `transaccion_notifier.dart` y `registro_rapido_screen.dart` con autofocus
- [ ] Añadir tests unitarios básicos para repositorio y notifier

### Cómo ejecutar la app (rápido) — nota para Windows
- En Windows sólo puedes compilar y ejecutar para Android (iOS requiere macOS).
- Verifica el entorno:

```powershell
flutter doctor -v
```

- Lista dispositivos/emuladores disponibles:

```powershell
flutter devices
flutter emulators
```

- Si tienes un emulador Android creado, lánzalo:

```powershell
flutter emulators --launch <emulatorId>
```

- Ejecuta la app en un dispositivo/emulador específico:

```powershell
flutter run -d <deviceId>
```

- Si usas un dispositivo físico: activa Opciones de desarrollador → Depuración USB; confirma con `adb devices`.

### Siguientes pasos recomendados (elige una)
- A) Generar scaffold de carpetas y archivos base (plantillas Dart)
- B) Generar ejemplo funcional mínimo: `db_provider`, modelo, repo y test
- C) Crear wireframes / micro UX flows para registro rápido

Si quieres, aplico la opción A o B ahora y creo los archivos base en el proyecto.

---
Categoría,Componente,Librería/Tecnología,Razón
Framework,Front-end,Flutter (Dart),Máximo rendimiento y fluidez en Android para una UI agradable.
Base de Datos,Almacenamiento Local,SQLite (sqflite),Robusta y adecuada para uso offline.
Gestión de Estado,Lógica de Negocio,Riverpod,Gestor de estado moderno y seguro.
Visualización,Gráficos,Fl_Chart,Herramienta sólida para reportes visuales.
Arquitectura,Patrón de Diseño,Repository,Separa persistencia de lógica y UI para escalabilidad.

Notas finales:
- Corregí redacción, acentos y estructura para que el README sea más directo y accionable.
- Añadí una sección "Cómo ejecutar" adaptada a Windows/Android.
- Puedo ahora: generar el scaffold (A) o el ejemplo funcional mínimo (B). Indica qué prefieres.