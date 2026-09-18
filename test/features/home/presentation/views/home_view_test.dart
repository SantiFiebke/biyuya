import 'package:biyuya/src/features/auth/domain/entities/household_data.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/auth/provider/household_provider.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/expenses/presentation/views/expense_list_view.dart';
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

void main() {
  group('HomeView', () {
    testWidgets('renders household name in header', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const HomeView(), overrides: _baseOverrides()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Mi Hogar'), findsOneWidget);
    });

    testWidgets('shows empty state when no expenses', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const HomeView(), overrides: _baseOverrides()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(EmptyExpenses), findsOneWidget);
      expect(find.text('No hay gastos'), findsOneWidget);
    });

    testWidgets('shows recent expenses list', (tester) async {
      final expenses = [
        makeExpense(description: 'Groceries'),
        makeExpense(id: 2, description: 'Bus ticket'),
      ];

      await tester.pumpWidget(
        wrapTest(
          child: const HomeView(),
          overrides: _baseOverrides(expenses: expenses),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Últimos gastos'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Bus ticket'), findsOneWidget);
    });

    testWidgets('FAB exists for new expense', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const HomeView(), overrides: _baseOverrides()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows invite code sheet on action', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapTest(
          child: const HomeView(),
          overrides: _baseOverrides(
            householdData: const HouseholdData(
              name: 'Mi Hogar',
              inviteCode: 'ABC123',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.person_add));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Invitar a tu hogar'), findsOneWidget);
      expect(find.text('ABC123'), findsOneWidget);
    });
  });
}
