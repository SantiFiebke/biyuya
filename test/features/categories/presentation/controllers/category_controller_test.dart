import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/categories/data/repositories/category_repository_impl.dart';
import 'package:biyuya/src/features/categories/domain/repositories/category_repository_base.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/categories/provider/category_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../helpers/test_helpers.dart';

class MockCategoryRepository extends Mock implements CategoryRepositoryImpl {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCategoryRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockCategoryRepository();
    // Default: auto-load returns empty (individual tests can override)
    when(
      () => mockRepo.getCategories(householdId: 1),
    ).thenAnswer((_) async => const Success([]));

    container = ProviderContainer(
      // No container-level `retry` override: categoriesProvider declares its
      // own `retry: _noRetry`, so a repository failure surfaces promptly.
      overrides: [
        categoryRepositoryProvider.overrideWithValue(mockRepo),
        authSessionControllerProvider.overrideWith(
          FakeAuthSessionController.new,
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('CategoryController', () {
    test('build returns empty list initially', () async {
      final state = container.read(categoryControllerProvider);
      expect(state.value, isEmpty);
      // Drain the unawaited _loadCategories microtask before teardown.
      await waitForLoad();
    });

    test('build auto-loads categories from repository', () async {
      final categories = [
        makeCategory(name: 'Food'),
        makeCategory(id: 2, name: 'Transport'),
      ];
      when(
        () => mockRepo.getCategories(householdId: 1),
      ).thenAnswer((_) async => Success(categories));

      container.read(categoryControllerProvider);
      await waitForLoad();

      final state = container.read(categoryControllerProvider);
      expect(state.value, hasLength(2));
      expect(state.value![0].name, 'Food');
    });

    test('build sets AsyncError on load failure', () async {
      when(
        () => mockRepo.getCategories(householdId: 1),
      ).thenAnswer((_) async => const Error(CategoryFailure('db error')));

      container.read(categoryControllerProvider);
      await waitForLoad();

      expect(container.read(categoryControllerProvider).hasError, isTrue);
    });

    test('createCategory adds category to state and returns true', () async {
      final newCat = makeCategory(id: 3, name: 'New');
      when(
        () => mockRepo.createCategory(name: 'New', householdId: 1),
      ).thenAnswer((_) async => Success(newCat));

      container.read(categoryControllerProvider);
      await waitForLoad();

      final notifier = container.read(categoryControllerProvider.notifier);
      final result = await notifier.createCategory(name: 'New');

      expect(result, isTrue);
      final state = container.read(categoryControllerProvider);
      expect(state.value, hasLength(1));
      expect(state.value![0].name, 'New');
    });

    test('createCategory sets AsyncError on failure', () async {
      when(
        () => mockRepo.createCategory(name: 'Fail', householdId: 1),
      ).thenAnswer((_) async => const Error(CategoryFailure('fail')));

      container.read(categoryControllerProvider);
      await waitForLoad();

      final notifier = container.read(categoryControllerProvider.notifier);
      final result = await notifier.createCategory(name: 'Fail');

      expect(result, isFalse);
      expect(container.read(categoryControllerProvider).hasError, isTrue);
    });

    test('updateCategory updates existing category in state', () async {
      final initial = makeCategory(id: 5, name: 'Old');
      when(
        () => mockRepo.getCategories(householdId: 1),
      ).thenAnswer((_) async => Success([initial]));

      container.read(categoryControllerProvider);
      await waitForLoad();

      final updated = makeCategory(id: 5, name: 'Updated');
      when(
        () => mockRepo.updateCategory(id: 5, name: 'Updated'),
      ).thenAnswer((_) async => Success(updated));

      final notifier = container.read(categoryControllerProvider.notifier);
      final result = await notifier.updateCategory(id: 5, name: 'Updated');

      expect(result, isTrue);
      final state = container.read(categoryControllerProvider);
      expect(state.value!.first.name, 'Updated');
    });

    test('updateCategory sets AsyncError on failure', () async {
      when(
        () => mockRepo.updateCategory(id: 5, name: 'X'),
      ).thenAnswer((_) async => const Error(CategoryFailure('err')));

      container.read(categoryControllerProvider);
      await waitForLoad();

      final notifier = container.read(categoryControllerProvider.notifier);
      final result = await notifier.updateCategory(id: 5, name: 'X');

      expect(result, isFalse);
      expect(container.read(categoryControllerProvider).hasError, isTrue);
    });

    test('deleteCategory removes category from state', () async {
      when(() => mockRepo.getCategories(householdId: 1)).thenAnswer(
        (_) async =>
            Success([makeCategory(name: 'A'), makeCategory(id: 2, name: 'B')]),
      );

      container.read(categoryControllerProvider);
      await waitForLoad();

      when(
        () => mockRepo.deleteCategory(id: 1),
      ).thenAnswer((_) async => const Success(null));

      final notifier = container.read(categoryControllerProvider.notifier);
      final result = await notifier.deleteCategory(id: 1);

      expect(result, isTrue);
      final state = container.read(categoryControllerProvider);
      expect(state.value, hasLength(1));
      expect(state.value![0].id, 2);
    });

    test('deleteCategory sets AsyncError on failure', () async {
      when(
        () => mockRepo.deleteCategory(id: 99),
      ).thenAnswer((_) async => const Error(CategoryFailure('not found')));

      container.read(categoryControllerProvider);
      await waitForLoad();

      final notifier = container.read(categoryControllerProvider.notifier);
      final result = await notifier.deleteCategory(id: 99);

      expect(result, isFalse);
      expect(container.read(categoryControllerProvider).hasError, isTrue);
    });
  });
}
