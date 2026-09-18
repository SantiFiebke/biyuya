# Guía de Testing — Biyuya

## Estructura

```
test/
├── core/
│   ├── data/               # test de sync de datos (SharedPreferences, bridges)
│   └── presentation/
│       └── utils/          # helpers de presentación (categorías, formato)
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── controllers/
│   │       └── views/
│   ├── categories/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── controllers/
│   │       └── views/
│   ├── expenses/
│   │   ├── domain/
│   │   │   └── models/
│   │   └── presentation/
│   │       ├── controllers/
│   │       └── views/
│   ├── home/
│   │   └── presentation/
│   │       └── views/
│   ├── profile/
│   │   └── presentation/
│   │       └── views/
│   └── reports/
│       ├── domain/
│       │   └── entities/
│       └── presentation/
│           ├── controllers/
│           ├── views/
│           └── widgets/
└── helpers/                # helpers compartidos (test_helpers.dart)
```

La carpeta `test/` espeja `lib/src/`. Cada feature tiene `domain/` y `presentation/`.

---

## Tipos de Test

| Tipo | Cuándo | Velocidad |
|------|--------|-----------|
| **Unit** | Lógica pura: modelos, utils, helpers, repos con mocks | <1s |
| **Widget** | UI: vistas, componentes, interacción de usuario | 1-5s |
| **Integration (no configurado)** | Flujos completos con backend real | >5s |

---

## Convenciones de Nombre

### Archivos
```
{nombre_del_archivo}_test.dart
expense_controller_test.dart
expense_list_view_test.dart
```

### Grupos y tests
```dart
group('ExpenseController', () {          // nombre de la clase/widget
  test('build returns empty list', () {});  // acción + resultado
  testWidgets('shows app bar with title', (tester) async {});  // widget tests
});
```

- `group()` → nombre de la clase o widget bajo test
- `test()` / `testWidgets()` → descripción en inglés, claro y directo

---

## Mocking con mocktail

### Mocks básicos
```dart
import 'package:mocktail/mocktail.dart';

class MockExpenseRepository extends Mock implements ExpenseRepositoryImpl {}
```

### When / Verify
```dart
// Configurar retorno
when(() => mockRepo.getExpenses(householdId: 1))
    .thenAnswer((_) async => const Success([]));

// Verificar llamada
verify(() => mockRepo.deleteExpense(id: 1)).called(1);

// Argumentos flexibles
when(() => mockRepo.createExpense(
  amount: any(named: 'amount'),
  date: any(named: 'date'),
  // ...
)).thenAnswer((_) async => Success(expense));
```

### Fakes (cuando el mock es demasiado)
```dart
class FakeExpenseRepo extends Fake implements ExpenseRepositoryBase {
  @override
  Future<Result<List<Expense>, ExpenseFailure>> getExpenses({
    required int householdId,
  }) async => const Success([]);
}
```

**Regla:** usar `Mock` para interfaces/ clases que no controlas. `Fake` para implementaciones simples que no quieres configurar con `when()`.

---

## Patrones Riverpod en Tests

### ProviderContainer con overrides
```dart
late ProviderContainer container;

setUp(() {
  final mockRepo = MockExpenseRepository();
  when(() => mockRepo.getExpenses(householdId: 1))
      .thenAnswer((_) async => const Success([]));

  container = ProviderContainer(
    overrides: [
      expenseRepositoryProvider.overrideWithValue(mockRepo),
      authSessionControllerProvider.overrideWith(FakeAuthSessionController.new),
    ],
  );
});

tearDown(() => container.dispose());
```

### Leyendo estado
```dart
final state = container.read(expenseControllerProvider);
expect(state.value, isEmpty);

final notifier = container.read(expenseControllerProvider.notifier);
await notifier.createExpense(amount: 100, date: DateTime.now(), categoryId: 1);
```

### Fake para controllers async
```dart
class FakeAuthSession extends AuthSessionController {
  @override
  FutureOr<UserProfile?> build() => const UserProfile(
    id: 'test-user-id', name: 'Test', lastName: 'User', householdId: '1',
  );
}
```

### Esperar carga async
Los controllers con `Future.microtask` en `build()` necesitan dos delays:
```dart
// Usar waitForLoad() de test_helpers.dart
await waitForLoad();
```

---

## Widget Tests

### Wrapper con ProviderScope
Usar `wrapTest()` de `test_helpers.dart` (ver sección Helpers Compartidos).

### Test básico
```dart
import 'package:biyuya/test/helpers/test_helpers.dart';

testWidgets('shows expense items in list', (tester) async {
  await tester.pumpWidget(wrapTest(
    child: const ExpenseListView(),
  ));
  await tester.pumpAndSettle();

  expect(find.text('Groceries'), findsOneWidget);
});
```

### pumpAndSettle vs pump
- `pumpAndSettle()` → esperar todas las animaciones. Usar por defecto.
- `pump()` → un frame. Usar para: timers, animaciones controladas, testing de estados intermedios.

### Simular tap
```dart
await tester.tap(find.text('Categoría'));
await tester.pumpAndSettle();
expect(find.byType(BottomSheet), findsOneWidget);
```

---

## Helpers Compartidos

Archivo: `test/helpers/test_helpers.dart`

Import:
```dart
import 'package:biyuya/test/helpers/test_helpers.dart';
```

### Símbolos exportados

| Símbolo | Tipo | Descripción |
|---------|------|-------------|
| `wrapTest({required Widget child, List<Override> overrides})` | `Widget` | Wrapper con `ProviderScope`, `MaterialApp`, localización es_AR y `Scaffold` |
| `waitForLoad()` | `Future<void>` | Dos `Future.delayed(Duration.zero)` para asentar controllers con microtask |
| `makeCategory({id, name, householdId})` | `Category` | Factory con valores por defecto razonables |
| `makeExpense({id, amount, description, householdId, categoryId})` | `Expense` | Factory con valores por defecto razonables |
| `makeReport({total, previousTotal, variation, year, month})` | `MonthlyReport` | Factory con valores por defecto razonables |
| `FakeAuthSessionController` | `AuthSessionController` | Fake que retorna un `UserProfile` fijo para tests |
| `MockReportRepository` | `Mock` | Mock de `ReportRepositoryImpl` para tests de reports |

### Ejemplo de uso
```dart
import 'package:biyuya/test/helpers/test_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows empty state', (tester) async {
    await tester.pumpWidget(wrapTest(
      child: const ExpenseListView(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('No hay gastos'), findsOneWidget);
  });
}
```

---

## Errores Comunes

### 1. `TestWidgetsFlutterBinding` no inicializado
```dart
// Solo necesario si usas SharedPreferences, servicios nativos, etc.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // tests...
}
```

### 2. Flakiness por `Duration.zero`
```dart
// ❌ Flaky
await Future.delayed(Duration.zero);

// ✅ Más estable (dos delays para controllers con microtask)
await waitForLoad();
```

### 3. Strings hardcodeados
Si el widget usa `AppLocalizations`, hardcodear el string en español en el test. La app está en español, los tests también.

### 4. Olvidar `container.dispose()`
Siempre limpiar en `tearDown`:
```dart
tearDown(() => container.dispose());
```

### 5. Mock sin `when` para `build()`
Si el controller tiene dependencias en `build()`, siempre mockearlas antes de leer el provider.

---

## Reglas para Nuevos Tests

### Qué testear
- Modelos: constructor, `==`, `props`, factory methods, parseos
- Controllers: carga, éxito, error, edge cases (lista vacía, null)
- Repos (con mocks): respuesta exitosa, error, timeout
- Widgets: renderizado, interacción, estados vacíos, estados con datos

### Qué NO testear
- Código generado (`.g.dart`)
- Widgets trivial (`SizedBox`, `Padding` sin lógica)
- Getters/setters simples
- Imports
- Integraciones de Supabase (validar manualmente; futuros integration tests)

### Prioridad de coverage
1. Lógica de negocio (models, controllers, repos)
2. Widgets con interacción de usuario
3. Widgets de presentación pura (solo render)

---

## Integration Tests (no implementados aún)

Actualmente NO existe el directorio `integration_test/` ni la dependencia `integration_test` en `dev_dependencies`. Los flujos end-to-end con backend real se validan manualmente por ahora.

Cuando se implementen:
- `flutter pub add dev:integration_test --sdk=flutter`
- crear `integration_test/app_test.dart`
- ejecutar `flutter test integration_test/`

---

## Snippets Mínimos

### Unit test (modelo)
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';

void main() {
  group('Expense', () {
    test('equality works correctly', () {
      final a = Expense(id: 1, amount: 100, date: DateTime(2025),
          householdId: 1, categoryId: 1, userUuid: 'u', createdAt: DateTime(2025));
      final b = Expense(id: 1, amount: 100, date: DateTime(2025),
          householdId: 1, categoryId: 1, userUuid: 'u', createdAt: DateTime(2025));
      expect(a, equals(b));
    });
  });
}
```

### Widget test con ProviderScope
```dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biyuya/src/features/expenses/presentation/views/expense_list_view.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/test/helpers/test_helpers.dart';

void main() {
  testWidgets('shows empty state', (tester) async {
    await tester.pumpWidget(wrapTest(
      child: const ExpenseListView(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('No hay gastos'), findsOneWidget);
  });
}
```

---

## Comandos

```bash
# Todos los tests
flutter test

# Archivo específico
flutter test test/features/expenses/presentation/controllers/expense_controller_test.dart

# Con coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html   # ver reporte HTML
```

---

## Coverage

### Ejecutar tests
```bash
flutter test                    # Ejecuta todos los tests
flutter test --coverage         # Genera coverage/lcov.info
```

### Umbrales
- **MVP:** 60% mínimo
- **Objetivo:** 80%

### Ver reporte HTML
```bash
genhtml coverage/lcov.info -o coverage/html
# Abrir coverage/html/index.html
```

**Requisito:** `lcov` instalado (`apt install lcov` en Ubuntu/Debian).
