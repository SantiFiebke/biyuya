import 'package:biyuya/src/features/auth/domain/entities/household_data.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/auth/provider/household_provider.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/home/presentation/views/home_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../../../helpers/test_helpers.dart';

class FakeHouseholdName extends HouseholdName {
  HouseholdData? data;

  @override
  Future<HouseholdData?> build() async => data;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<Override> _baseOverrides({
  HouseholdData? householdData = const HouseholdData(name: 'Mi Hogar'),
  List<Expense> expenses = const [],
  List<Category> categories = const [],
}) {
  final fakeNotifier = FakeHouseholdName()..data = householdData;
  return [
    authSessionControllerProvider.overrideWith(FakeAuthSessionController.new),
    expenseControllerProvider.overrideWithValue(
      AsyncData<List<Expense>>(expenses),
    ),
    categoryControllerProvider.overrideWithValue(
      AsyncData<List<Category>>(categories),
    ),
    householdNameProvider.overrideWith(() => fakeNotifier),
  ];
}

Future<void> _pumpHome(WidgetTester tester, {List<Override>? overrides}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    wrapTest(child: const HomeView(), overrides: overrides ?? _baseOverrides()),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('HomeView', () {
    testWidgets('renders app bar title', (tester) async {
      await _pumpHome(tester);

      expect(find.text('Cuentas claras'), findsOneWidget);
    });

    testWidgets('balance card shows monthly label and amount', (tester) async {
      final expenses = [makeExpense(date: DateTime.now())];

      await _pumpHome(tester, overrides: _baseOverrides(expenses: expenses));

      expect(find.text('Gastado este mes'), findsOneWidget);
      expect(find.textContaining('100,00', findRichText: true), findsWidgets);
    });

    testWidgets('renders quick actions', (tester) async {
      await _pumpHome(tester);

      expect(find.text('Nuevo gasto'), findsOneWidget);
      expect(find.text('Reportes'), findsOneWidget);
      expect(find.text('Categorías'), findsOneWidget);
    });

    testWidgets('shows recent movements when there are expenses', (
      tester,
    ) async {
      final expenses = [
        makeExpense(description: 'Groceries'),
        makeExpense(id: 2, description: 'Bus ticket'),
      ];

      await _pumpHome(tester, overrides: _baseOverrides(expenses: expenses));

      expect(find.text('Últimos movimientos'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Bus ticket'), findsOneWidget);
    });

    testWidgets('shows empty state when there are no expenses', (tester) async {
      await _pumpHome(tester);

      expect(find.text('Todavía no hay gastos'), findsOneWidget);
    });

    testWidgets('has FAB for new expense', (tester) async {
      await _pumpHome(tester);

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
