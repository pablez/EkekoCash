# EkekoCash — Guía de desarrollo (DEVELOPMENT)

Este documento contiene las tareas paso a paso y los comandos de PowerShell para iniciar el desarrollo del proyecto EkekoCash.

IMPORTANTE: Asume que tienes instalado Flutter y Git en tu máquina. Si no, instala Flutter desde https://flutter.dev

## 1) Comprobaciones iniciales
- Verificar Flutter y Git
```powershell
flutter --version
git --version
```

- Comprobar dispositivos/emuladores
```powershell
flutter devices
flutter emulators
# lanzar emulador (si tienes uno configurado)
flutter emulators --launch <emulatorId>
```

## 2) Inicializar repo y branch de trabajo
```powershell
# en la raíz del proyecto
git init  # si aún no hay repo
git checkout -b feat/init-project
```

## 3) Añadir dependencias (Flutter)
```powershell
# Añadir paquetes recomendados
flutter pub add sqflite
flutter pub add path
flutter pub add flutter_riverpod
flutter pub add fl_chart
flutter pub add intl
```

Si prefieres editar `pubspec.yaml` manualmente, añade las dependencias y luego:
```powershell
flutter pub get
```

## 4) Estructura de carpetas (ya creada por el scaffold)
- `lib/data` (db_provider, models, repositories)
- `lib/domain` (repositories interfaces, usecases, notifiers)
- `lib/presentation` (screens, widgets, styles)

## 5) Primera implementación (P0) — DB + insert transacción
Tareas:
- Implementar `onCreate` en `lib/data/db_provider.dart` usando el DDL del `Readme.md`.
- Añadir creación de índices.
- Implementar un test local que abra la base de datos y verifique que las tablas existen.

Comandos para ejecutar pruebas manuales:
```powershell
# desde la raíz
flutter pub get
flutter analyze
flutter test
```

## 6) Wiring y providers
- Añadir `ProviderScope` en `lib/main.dart` y registrar providers/implementaciones:
  - `transaccionRepositoryProvider` -> `TransaccionRepository()`
  - `transaccionNotifierProvider` -> `TransaccionNotifier`

Ejecutar app en emulador:
```powershell
flutter run -d <deviceId>
```

## 7) Implementación incremental (sprint pequeño)
Sprint A (3-5 días):
- DB: `onCreate` + índices
- Models: todas las entidades (Miembros, Cuentas, Categorias, Subcategorias, Transacciones)
- Repository: `TransaccionRepository` con inserción y query básica
- Domain: `CreateTransaccionUseCase` + `TransaccionNotifier`
- UI: `registro_rapido_screen` minimal (autofocus, guardar transacción)

Sprint B (3-5 días):
- Fondos y Asignaciones
- UI: modal de reparto (slider)
- Notifiers para fondos
- Tests unitarios para usecases

Sprint C (3-5 días):
- Dashboard + gráficos (Fl Chart)
- Reportes mensuales
- Mejoras UX y accesibilidad

## 8) Tests y CI
- Tests locales:
```powershell
flutter test
```
- Linter / analyzer:
```powershell
flutter analyze
```
- Sugerencia CI (GitHub Actions): correr `flutter pub get`, `flutter analyze`, `flutter test` en cada PR.

## 9) Comandos útiles (PowerShell)
```powershell
# ejecutar app en modo debug
flutter run -d <deviceId>

# listar dispositivos
flutter devices

# correr tests
flutter test

# analizar código
flutter analyze

# formatear (dartfmt / flutter format)
flutter format .
```

## 10) Checklist de tareas (desglosado por pasos)
1. [ ] Verificar Flutter/Git/Emulador
2. [ ] Crear branch de trabajo
3. [ ] Añadir dependencias (sqflite, path, riverpod, fl_chart, intl)
4. [ ] Implementar `DBProvider.onCreate` con DDL y crear índices
5. [ ] Implementar modelos Dart para tablas
6. [ ] Implementar `ITransaccionRepository` (ya creado) y `TransaccionRepository` (ya creado)
7. [ ] Implementar `CreateTransaccionUseCase` y tests unitarios
8. [ ] Implementar `TransaccionNotifier` y wiring en `main.dart`
9. [ ] Crear `registro_rapido_screen` y conectar con Notifier
10. [ ] Tests de integración con DB en memoria
11. [ ] Implementar Fondos y Asignaciones + UI de reparto
12. [ ] Dashboard y gráficos con Fl Chart
13. [ ] Preparar CI y pipeline de release

---

Si quieres, puedo ahora:
- A) Implementar `DBProvider.onCreate` con el DDL (y crear un test que abra la DB)
- B) Añadir wiring de Riverpod en `main.dart` y registrar `TransaccionRepository`
- C) Generar tests unitarios para `CreateTransaccionUseCase` (mock repo)

Indica A, B o C y lo hago en esta sesión.
