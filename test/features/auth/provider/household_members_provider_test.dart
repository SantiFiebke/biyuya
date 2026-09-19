import 'dart:async';

import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/domain/repositories/auth_repository_base.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/auth/provider/auth_repository_provider.dart';
import 'package:biyuya/src/features/auth/provider/household_members_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart' as mr;

class _FakeAuthRepository extends Fake implements AuthRepositoryBase {
  _FakeAuthRepository(this._result);

  final mr.Result<List<UserProfile>, AuthFailure> _result;
  int calls = 0;
  int? lastHouseholdId;

  @override
  Future<mr.Result<List<UserProfile>, AuthFailure>> getHouseholdMembers({
    required int householdId,
  }) async {
    calls++;
    lastHouseholdId = householdId;
    return _result;
  }
}

class _FakeSession extends AuthSessionController {
  _FakeSession(this._householdId);

  final String? _householdId;

  @override
  FutureOr<UserProfile?> build() => UserProfile(
    id: 'test-user-id',
    name: 'Test',
    lastName: 'User',
    householdId: _householdId,
  );
}

ProviderContainer _container({
  required String? householdId,
  required AuthRepositoryBase repository,
}) {
  final container = ProviderContainer(
    overrides: [
      authSessionControllerProvider.overrideWith(
        () => _FakeSession(householdId),
      ),
      authRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  const members = <UserProfile>[
    UserProfile(id: 'a', name: 'Ana', lastName: 'Perez', householdId: '1'),
    UserProfile(id: 'b', name: 'Beto', lastName: 'Gomez', householdId: '1'),
  ];

  group('householdMembersProvider', () {
    test('returns empty list when session has no householdId', () async {
      final repository = _FakeAuthRepository(
        const mr.Success<List<UserProfile>, AuthFailure>(<UserProfile>[]),
      );
      final container = _container(householdId: null, repository: repository);

      final result = await container.read(householdMembersProvider.future);

      expect(result, isEmpty);
      expect(repository.calls, 0);
    });

    test('returns members when householdId is present', () async {
      final repository = _FakeAuthRepository(
        const mr.Success<List<UserProfile>, AuthFailure>(members),
      );
      final container = _container(householdId: '1', repository: repository);

      final result = await container.read(householdMembersProvider.future);

      expect(result, members);
      expect(repository.calls, 1);
      expect(repository.lastHouseholdId, 1);
    });

    test('exposes AsyncError when repository returns a failure', () async {
      final repository = _FakeAuthRepository(
        const mr.Error<List<UserProfile>, AuthFailure>(AuthFailure('boom')),
      );
      final container = _container(householdId: '1', repository: repository)
        // Kick off the provider build and let async work settle.
        ..listen(householdMembersProvider, (_, _) {});
      await pumpEventQueue();

      final state = container.read(householdMembersProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<Exception>());
    });
  });
}
