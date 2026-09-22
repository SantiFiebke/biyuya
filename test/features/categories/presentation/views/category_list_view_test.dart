import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/categories/presentation/views/category_list_view.dart';
import 'package:flutter/services.dart' show SystemChannels;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../../../helpers/test_helpers.dart';

final _testCategories = [
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
];

class _RecordingCategoryController extends CategoryController {
  _RecordingCategoryController(this._initial);

  final List<Category> _initial;
  final List<int> deletedIds = [];

  @override
  AsyncValue<List<Category>> build() => AsyncData(_initial);

  @override
  Future<bool> deleteCategory({required int id}) async {
    deletedIds.add(id);
    state = AsyncData((state.value ?? []).where((c) => c.id != id).toList());
    return true;
  }
}

List<Override> _dataOverrides(List<Category> categories) => [
  categoryControllerProvider.overrideWithValue(
    AsyncData<List<Category>>(categories),
  ),
];

void main() {
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform,
          (methodCall) async => null,
        );
  });

  group('CategoryListView', () {
    testWidgets('renders list of categories', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const CategoryListView(),
          overrides: _dataOverrides(_testCategories),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Categorías'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.byType(CategoryTile), findsNWidgets(2));
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('shows EmptyView when no categories', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const CategoryListView(),
          overrides: _dataOverrides(const []),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No hay categorías'), findsOneWidget);
      expect(
        find.text('Creá categorías para organizar tus gastos'),
        findsOneWidget,
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('shows ErrorView on error', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const CategoryListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncError<List<Category>>(Exception('boom'), StackTrace.empty),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No se pudieron cargar las categorías'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('shows FAB with add icon', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const CategoryListView(),
          overrides: _dataOverrides(_testCategories),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('shows edit IconButton per tile', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const CategoryListView(),
          overrides: _dataOverrides(_testCategories),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('swipe-to-delete opens confirm dialog and records delete', (
      tester,
    ) async {
      final fake = _RecordingCategoryController(_testCategories);
      await tester.pumpWidget(
        wrapTest(
          child: const CategoryListView(),
          overrides: [categoryControllerProvider.overrideWith(() => fake)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar categoría'), findsOneWidget);
      expect(
        find.text('¿Estás segura de que querés eliminar "Food"?'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(fake.deletedIds, [1]);
      expect(find.text('Food'), findsNothing);
      expect(find.text('Transport'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
