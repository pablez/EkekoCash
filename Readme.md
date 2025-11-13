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
- Selección de categoría: GridView con botones (icon + label)
- Subcategorias: Chips horizontales que cambian según la categoría
- Selector de miembro: Row de CircleAvatar
- Selector de cuenta: DropdownButton o fila de botones con saldo
- Botón de guardado grande; implementación del botón flotante con onTap (rápido) y onLongPress (avanzado)
- Asignación a fondos (si ingreso): modal con slider de porcentaje y tarjetas por fondo

Validaciones: monto > 0, cuenta seleccionada; manejar errores DB con snackbars; usar transacciones DB al insertar transacción + asignaciones.

## Backlog técnico inicial (tareas y estimación)
1. Init `db_provider.dart` + migraciones (1 día)
2. Implementar modelos y `transaccion_repository.dart` + tests (1-2 días)
3. `transaccion_notifier.dart` + `registro_rapido_screen.dart` minimal (2 días)
4. Fondos + asignaciones + UI slider (2 días)
5. Dashboard con gráfico básico (2 días)

## Checklist inmediato (próxima sesión)
- [ ] Crear carpetas `data/models`, `data/repositories`, `domain/notifiers`, `presentation/screens`, `presentation/widgets`
- [ ] Implementar `db_provider.dart` con SQL de arriba y version = 1
- [ ] Implementar `transaccion_model.dart` y `transaccion_repository.dart`
- [ ] Implementar `transaccion_notifier.dart` y `registro_rapido_screen.dart` con autofocus
- [ ] Añadir tests unitarios básicos para repositorio y notifier

## Próximos pasos (elige una)
- A) Genero scaffold de carpetas y archivos base (firmas/plantillas Dart)
- B) Genero ejemplo funcional mínimo (db_provider, modelo, repo, test)
- C) Hago wireframes UI (descripciones + mockups en texto / PlantUML)

Si quieres que reemplace el `Readme.md` original por esta versión (ya lo hice), puedo además crear el scaffold o el ejemplo funcional ahora. Indica A, B o C.


Categoría,Componente,Librería/Tecnología,Razón
Framework,Front-end,Flutter (Dart),Máximo rendimiento y fluidez en Android para una UI agradable.
Base de Datos,Almacenamiento Local,SQLite (sqflite),Base de datos relacional y robusta para funcionalidad offline.
Gestión de Estado,Lógica de Negocio,Riverpod,"Gestor de estado seguro, limpio y moderno para el manejo de saldos y cálculos."
Visualización,Gráficos,Fl Chart,Herramienta gratuita para los reportes visuales y agradables.
Arquitectura,Patrón de Diseño,Patrón Repository,"Separa la lógica de la base de datos de la UI, haciendo el código escalable."


La estructura sigue el Patrón Repository con Riverpod como el gestor de estado.

data/ (Acceso a SQLite): Contiene los models/ (las clases Dart que representan las tablas), el db_provider.dart (inicialización de la DB) y los repositories/ (la lógica CRUD con sqflite).

domain/ (Lógica de Negocio/Riverpod): Contiene los notifiers/ que manejan el estado de la aplicación (Ej: saldo_notifier.dart, reporte_notifier.dart).

presentation/ (Interfaz de Usuario): Contiene screens/ (las pantallas), widgets/ (componentes reutilizables) y styles/ (temas y colores).


erDiagram
    Miembros ||--o{ Transacciones : "realizó"
    Cuentas ||--o{ Transacciones : "afecta_a"
    Categorias ||--o{ Subcategorias : "contiene"
    Subcategorias ||--o{ Transacciones : "clasifica"
    Transacciones ||--o{ Asignaciones_Ahorro : "financia"
    Fondos ||--o{ Asignaciones_Ahorro : "recibe"

    Miembros {
        int miembro_id PK
        string nombre
        string color_perfil
    }
    Cuentas {
        int cuenta_id PK
        string nombre
        real saldo_inicial
        string tipo_moneda
    }
    Categorias {
        int categoria_id PK
        string nombre
        string tipo "Ingreso/Egreso"
    }
    Subcategorias {
        int subcategoria_id PK
        string nombre
        int categoria_id FK
    }
    Transacciones {
        int transaccion_id PK
        text fecha
        real monto
        string descripcion
        int cuenta_id FK
        int subcategoria_id FK
        int miembro_id FK
    }
    Fondos {
        int fondo_id PK
        string nombre
        real meta_monto
        text fecha_meta
        int icono_id
    }
    Asignaciones_Ahorro {
        int asignacion_id PK
        real monto_asignado
        int transaccion_id FK
        int fondo_id FK
    }


Característica,Propósito
Perfiles de Miembros,Controlar quién de la familia realiza cada transacción (Miembros en DB).
Múltiples Cuentas,"Controlar el saldo en diferentes ""bolsillos"" o cuentas (Cuentas en DB)."
Fondos de Ahorro,"Vincular el ahorro a metas específicas (ej: Viaje, Educación) para mantener la motivación (Fondos en DB)."
Simulador de Hipótesis,(Offline) Permitir al usuario ver cómo un gasto o ingreso afectaría su saldo y sus metas.




Lluvia de Ideas UI/UX para Registro Rápido
El requisito de registro rápido y cómodo es clave para la UX familiar. Aquí tienes ideas específicas para la pantalla de registro en Flutter:

A. Registro de Egreso (Gasto)
Teclado Siempre Abierto: Al acceder a la pantalla de registro, el teclado numérico de Flutter debe aparecer inmediatamente para que el usuario pueda ingresar el monto sin tocar nada más.

UX Título: "Monto de Gasto Rápido".

Registro en 3 Pasos (Mínimo):

Paso 1: Monto: Ingresar el número.

Paso 2: Categoría/Subcategoría: Usar botones de íconos grandes (con colores de semáforo si ya está cerca del presupuesto).

Paso 3: Miembro: Un pequeño selector circular con la foto o inicial del miembro que gastó (ej: "Yo", "Esposa", "Hijo").

Botón Flotante Inteligente: Un botón grande de + o - que siempre esté visible. Al pulsarlo por corto tiempo, se abre el formulario rápido. Al pulsarlo por largo tiempo (mantener presionado), se abre el formulario de transacción recurrente/compleja.

B. Registro de Ingreso (con Asignación a Fondos)
Vista de Asignación Automática: Después de ingresar el monto y la categoría "Ingreso", la aplicación debe preguntar: "¿Desea asignar un porcentaje de ahorro?"

Slider de Reparto: En lugar de ingresar números, usa un slider con porcentajes que la familia pueda arrastrar para repartir el ahorro entre los Fondos de forma visual y cómoda.

Ejemplo: Slider que muestra: Fondo Viaje (50%) y Fondo Emergencia (50%).

Total Asignado Visible: Mostrar siempre el total de dinero asignado vs. el total disponible para asignar (ej: "Asignaste $150 de un total de $150 disponibles para ahorrar").



Elemento UI/UX,Implementación Flutter,Razón de ser
Apertura Rápida,Usar showModalBottomSheet o una nueva Page con autofocus: true en el campo de texto.,"Esto hace que el teclado numérico aparezca automáticamente al abrir la pantalla de registro, eliminando una pulsación."
Teclado Numérico,keyboardType: TextInputType.numberWithOptions(decimal: true),"Garantiza que solo se muestren los números y el separador decimal relevante para Bolivia (punto o coma, según la configuración local)."
Botón de Avance,"Un botón grande y vibrante ""Siguiente"" o un ícono > que solo se habilita cuando el monto es mayor que cero.",Guía visual clara de la acción a seguir.



Elemento UI/UX,Implementación Flutter,Razón de ser
Vistas de Categorías,Usar un GridView con GestureDetector o InkWell para cada Categoría.,"Permite mostrar íconos grandes y coloridos (ej: un carrito de supermercado, un surtidor de gasolina). La selección es visualmente atractiva y más rápida que una lista desplegable."
Filtro de Subcategorías,Un Wrap o lista horizontal de Chips que se actualiza dinámicamente.,"Al pulsar la Categoría (ej: ""Transporte""), aparecen inmediatamente los Chips de Subcategorías relevantes (""Bus"", ""Taxi"", ""Gasolina"") para una selección final precisa."
Indicador de Presupuesto,Usar un color de fondo ligero o un borde de ícono (ej: rojo o amarillo) en la Categoría.,¡UX Inteligente! Muestra rápidamente al usuario si ya está cerca de exceder el presupuesto de esa Categoría para el mes.




Elemento UI/UX,Implementación Flutter,Razón de ser
Selector de Miembro,Una fila horizontal de CircleAvatar con la foto o inicial de cada miembro familiar.,Permite una selección rápida con un solo toque y refuerza el concepto familiar de EkekoCash.
Selector de Cuenta,"Un DropdownButton sencillo o una fila de botones que muestren la cuenta de origen (ej: ""Efectivo"", ""BNB Débito"").",La selección de la cuenta de origen (Cuentas en la DB) es el último paso esencial antes de guardar.
Botón FINAL,"Un botón grande de ""GUARDAR"" que ejecuta la lógica de Riverpod.","Una vez pulsado, se llama al transaccion_notifier para que el TransaccionRepository inserte los datos en SQLite."



Podrías usar un widget llamado Stepper o simplemente animar la transición entre los tres grupos de widgets para simular un proceso lineal y guiado.

El mayor beneficio: El usuario solo ve los elementos necesarios para cada paso, reduciendo la distracción y acelerando el registro.