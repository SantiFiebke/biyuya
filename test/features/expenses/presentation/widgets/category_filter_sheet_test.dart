import 'package:biyuya/src/core/presentation/widgets/category_avatar.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/presentation/widgets/category_filter_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../../../helpers/test_helpers.dart';

final _categories = [
  Category(
    id: 1,
    name: 'Food',
    householdId: 1,
    createdAt: DateTime(2025),
    color: '#4CAF50',
    icon: '63046',
  ),
  Category(
    id: 2,
    name: 'Transport',
    householdId: 1,
    createdAt: DateTime(2025),
    color: '#2196F3',
    icon: '57681',
  ),
  Category(
    id: 3,
    name: 'Fun',
    householdId: 1,
    createdAt: DateTime(2025),
    color: '#FF9800',
    icon: '59581',
  ),
];

List<Override> _overrides() => [
  categoryControllerProvider.overrideWithValue(
    AsyncData<List<Category>>(_categories),
  ),
];

/// Opens the category filter sheet; reports the selection via [onSelected].
class _SheetHarness extends ConsumerWidget {
  const _SheetHarness({
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final int? selectedCategoryId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => showCategoryFilterSheet(
        context,
        ref,
        selectedCategoryId: selectedCategoryId,
        onSelected: onSelected,
      ),
      child: const Text('open-sheet'),
    );
  }
}

Future<void> _openSheet(
  WidgetTester tester, {
  required ValueChanged<int?> onSelected,
  int? selectedCategoryId,
}) async {
  await tester.pumpWidget(
    wrapTest(
      child: _SheetHarness(
        selectedCategoryId: selectedCategoryId,
        onSelected: onSelected,
      ),
      overrides: _overrides(),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('open-sheet'));
  await tester.pumpAndSettle();
}

void main() {
  group('showCategoryFilterSheet', () {
    testWidgets('renders "Todas" row plus every category with avatars', (
      tester,
    ) async {
      await _openSheet(tester, onSelected: (_) {});

      expect(find.text('Filtrar por categoría'), findsOneWidget);
      expect(find.text('Todas las categorías'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Fun'), findsOneWidget);
      // One avatar per row: "Todas" + 3 categories.
      expect(find.byType(CategoryAvatar), findsNWidgets(4));
    });

    testWidgets('sheet is scrollable via the DraggableScrollableSheet', (
      tester,
    ) async {
      await _openSheet(tester, onSelected: (_) {});

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      // The list is wired to the sheet's scroll controller, not free-floating.
      final list = tester.widget<ListView>(find.byType(ListView));
      expect(list.controller, isNotNull);

      // Scrolling does not throw.
      await tester.drag(find.byType(ListTile).last, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows check on the selectedCategoryId row only', (
      tester,
    ) async {
      await _openSheet(tester, selectedCategoryId: 2, onSelected: (_) {});

      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Transport'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Food'),
          matching: find.byIcon(Icons.check),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Todas las categorías'),
          matching: find.byIcon(Icons.check),
        ),
        findsNothing,
      );
    });

    testWidgets('null selectedCategoryId checks the "Todas" row only', (
      tester,
    ) async {
      await _openSheet(tester, onSelected: (_) {});

      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Todas las categorías'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Food'),
          matching: find.byIcon(Icons.check),
        ),
        findsNothing,
      );
    });

    testWidgets('tapping a category calls onSelected and closes the sheet', (
      tester,
    ) async {
      int? selected;
      var called = false;
      await _openSheet(
        tester,
        selectedCategoryId: 2,
        onSelected: (id) {
          called = true;
          selected = id;
        },
      );

      await tester.tap(find.widgetWithText(ListTile, 'Food'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(selected, 1);
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      expect(find.text('Filtrar por categoría'), findsNothing);
    });

    testWidgets('tapping "Todas las categorías" calls onSelected(null) and '
        'closes the sheet', (tester) async {
      int? selected = 99;
      var called = false;
      await _openSheet(
        tester,
        selectedCategoryId: 2,
        onSelected: (id) {
          called = true;
          selected = id;
        },
      );

      await tester.tap(find.widgetWithText(ListTile, 'Todas las categorías'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(selected, isNull);
      expect(find.byType(DraggableScrollableSheet), findsNothing);
    });
  });
}
