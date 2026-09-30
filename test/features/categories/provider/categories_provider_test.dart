import 'dart:async';

import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/domain/repositories/category_repository_base.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/categories/provider/categories_provider.dart';
import 'package:biyuya/src/features/categories/provider/category_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../helpers/test_helpers.dart';

/// Counts `getCategories` calls so tests can prove the provider is shared.
class _FakeCategoryRepository extends CategoryRepositoryBase {
  _FakeCategoryRepository(this.result);

  final Result<List<Category>, CategoryFailure> Function() result;
  int calls = 0;
  int? lastHouseholdId;

  @override
  Future<Result<List<Category>, CategoryFailure>> getCategories({
    required int householdId,
  }) async {
    calls++;
    lastHouseholdId = householdId;
    return result();
  }

  @override
  Future<Result<Category, CategoryFailure>> createCategory({
    required String name,
    required int householdId,
    String? color,
    String? icon,
    double? budgetAmount,
    bool isExpense = true,
  }) async => throw UnimplementedError();

  @override
  Future<Result<Category, CategoryFailure>> updateCategory({
    required int id,
    required String name,
    String? color,
    String? icon,
    double? budgetAmount,
    bool isExpense = true,
  }) async => throw UnimplementedError();

  @override
  Future<Result<void, CategoryFailure>> deleteCategory({
    required int id,
  }) async => throw UnimplementedError();
}

/// Session without a household → `householdIdValue` is null.
class _NoHouseholdAuthSession extends AuthSessionController {
  @override
  FutureOr<UserProfile?> build() =>
      const UserProfile(id: 'test-user-id', name: 'Test', lastName: 'User');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerWith({
    required _FakeCategoryRepository repo,
    AuthSessionController Function() authSessionController =
        FakeAuthSessionController.new,
  }) {
    return ProviderContainer(
      // Riverpod 3 auto-retries failed providers by default; disable it so a
      // repository failure surfaces as an error instead of an endless retry.
      retry: (_, _) => null,
      overrides: [
        categoryRepositoryProvider.overrideWithValue(repo),
        authSessionControllerProvider.overrideWith(authSessionController),
      ],
    );
  }

  group('categoriesProvider', () {
    test('returns the categories from the repository', () async {
      final repo = _FakeCategoryRepository(
        () => Success([makeCategory(name: 'Comida')]),
      );
      final container = containerWith(repo: repo);
      addTearDown(container.dispose);

      final categories = await container.read(categoriesProvider.future);

      expect(categories.single.name, 'Comida');
      expect(repo.calls, 1);
      expect(repo.lastHouseholdId, 1);
    });

    test('returns const [] when the session has no household', () async {
      final repo = _FakeCategoryRepository(() => const Success(<Category>[]));
      final container = containerWith(
        repo: repo,
        authSessionController: _NoHouseholdAuthSession.new,
      );
      addTearDown(container.dispose);

      final categories = await container.read(categoriesProvider.future);

      expect(categories, isEmpty);
      expect(
        repo.calls,
        0,
        reason: 'repository must not be queried without a household',
      );
    });

    test('throws when the repository fails', () async {
      final repo = _FakeCategoryRepository(
        () => const Error(CategoryFailure('db exploded')),
      );
      final container = containerWith(repo: repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(categoriesProvider.future),
        throwsA(isA<Exception>()),
      );
      expect(repo.calls, 1);
    });

    test('is shared: reading twice calls the repository only once', () async {
      final repo = _FakeCategoryRepository(
        () => Success([makeCategory(name: 'Comida')]),
      );
      final container = containerWith(repo: repo);
      addTearDown(container.dispose);

      await container.read(categoriesProvider.future);
      await container.read(categoriesProvider.future);

      expect(
        repo.calls,
        1,
        reason: 'keepAlive provider must be memoized across reads',
      );
    });
  });

  group('categoriesProvider regression: failure is prompt, no retry', () {
    // Deliberately NO container-level retry override: the provider declares
    // `retry: _noRetry` itself, so these must pass without external help.
    ProviderContainer bareContainer(_FakeCategoryRepository repo) {
      return ProviderContainer(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(repo),
          authSessionControllerProvider.overrideWith(
            FakeAuthSessionController.new,
          ),
        ],
      );
    }

    test('repo failure throws promptly and does not retry', () async {
      final repo = _FakeCategoryRepository(
        () => const Error(CategoryFailure('db exploded')),
      );
      final container = bareContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container
            .read(categoriesProvider.future)
            .timeout(const Duration(seconds: 2)),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('db exploded'),
          ),
        ),
      );
      expect(
        repo.calls,
        1,
        reason: 'a failure must surface immediately, not trigger retries',
      );
    });

    test(
      'CategoryController load reaches AsyncError instead of hanging',
      () async {
        final repo = _FakeCategoryRepository(
          () => const Error(CategoryFailure('db exploded')),
        );
        final container = bareContainer(repo);
        addTearDown(container.dispose);

        container.read(categoryControllerProvider);
        await waitForLoad();

        final state = container.read(categoryControllerProvider);
        expect(state.hasError, isTrue);
        expect(state.isLoading, isFalse);
        expect(state, isNot(isA<AsyncLoading<List<Category>>>()));
      },
    );
  });
}
