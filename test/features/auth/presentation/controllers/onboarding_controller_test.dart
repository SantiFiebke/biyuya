import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/domain/entities/household.dart';
import 'package:biyuya/src/features/auth/domain/repositories/auth_repository_base.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/onboarding_controller.dart';
import 'package:biyuya/src/features/auth/provider/auth_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart' as mr;

class FakeAuthRepository implements AuthRepositoryBase {
  final List<String> calls = [];
  String? lastHouseholdName;
  String? lastInviteCode;
  late mr.Result<Household, AuthFailure>? _nextResult;
  late mr.Result<UserProfile, AuthFailure>? _nextJoinResult;

  set nextResult(mr.Result<Household, AuthFailure> result) {
    _nextResult = result;
  }

  mr.Result<Household, AuthFailure>? get nextResult => _nextResult;

  set nextJoinResult(mr.Result<UserProfile, AuthFailure> result) {
    _nextJoinResult = result;
  }

  mr.Result<UserProfile, AuthFailure>? get nextJoinResult => _nextJoinResult;

  @override
  Future<mr.Result<Household, AuthFailure>> createHousehold({
    required String householdName,
  }) async {
    calls.add('createHousehold');
    lastHouseholdName = householdName;
    return _nextResult!;
  }

  @override
  Future<mr.Result<UserProfile, AuthFailure>> joinHousehold({
    required String inviteCode,
  }) async {
    calls.add('joinHousehold');
    lastInviteCode = inviteCode;
    return _nextJoinResult!;
  }

  // -- Unimplemented stubs (should never be called) --

  @override
  Stream<UserProfile?> get onAuthStateChanged => throw UnimplementedError();

  @override
  Stream<UserProfile?> onProfileChanged({required String userId}) =>
      throw UnimplementedError();

  @override
  Future<mr.Result<UserProfile, AuthFailure>> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String lastName,
    required bool acceptedTerms,
  }) => throw UnimplementedError();

  @override
  Future<mr.Result<UserProfile, AuthFailure>> signInWithEmailPassword({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<mr.Result<void, AuthFailure>> signOut() => throw UnimplementedError();

  @override
  Future<mr.Result<UserProfile, AuthFailure>> getUserProfile(String userId) =>
      throw UnimplementedError();

  @override
  Future<mr.Result<List<UserProfile>, AuthFailure>> getHouseholdMembers({
    required int householdId,
  }) => throw UnimplementedError();

  @override
  Future<mr.Result<void, AuthFailure>> leaveHousehold() =>
      throw UnimplementedError();

  @override
  Future<mr.Result<void, AuthFailure>> deleteHousehold() =>
      throw UnimplementedError();

  @override
  Future<mr.Result<void, AuthFailure>> deleteAccount() =>
      throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository fake;

  setUp(() {
    fake = FakeAuthRepository();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
    );
  }

  group('OnboardingController.createNewHousehold', () {
    test(
      'success: sets AsyncData, stores household, calls repo once',
      () async {
        final household = Household(
          id: 'h-1',
          name: 'Casa',
          createdAt: DateTime(2025),
        );
        fake.nextResult = mr.Success(household);

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(onboardingControllerProvider.notifier);
        await notifier.createNewHousehold('Casa');

        // State should be AsyncData(null) after success
        final state = container.read(onboardingControllerProvider);
        expect(state, isA<AsyncData<void>>());

        // Household stored on notifier
        expect(notifier.createdHousehold?.name, 'Casa');

        // Repo called exactly once with correct name
        expect(fake.calls.length, 1);
        expect(fake.lastHouseholdName, 'Casa');
      },
    );

    test('error: sets AsyncError when repo returns AuthFailure', () async {
      fake.nextResult = const mr.Error(AuthFailure('boom'));

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(onboardingControllerProvider.notifier);
      await notifier.createNewHousehold('Casa');

      final state = container.read(onboardingControllerProvider);
      expect(state, isA<AsyncError<void>>());

      // No household stored
      expect(notifier.createdHousehold, isNull);
    });
  });

  group('OnboardingController.joinExistingHousehold', () {
    test(
      'success: sets AsyncData, calls repo once with correct inviteCode',
      () async {
        const profile = UserProfile(
          id: 'u-1',
          name: 'Ada',
          lastName: 'Lovelace',
          householdId: 'h-42',
        );
        fake.nextJoinResult = const mr.Success(profile);

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(onboardingControllerProvider.notifier);
        await notifier.joinExistingHousehold('ABC123');

        final state = container.read(onboardingControllerProvider);
        expect(state, isA<AsyncData<void>>());

        expect(fake.calls, contains('joinHousehold'));
        expect(fake.lastInviteCode, 'ABC123');
      },
    );

    test(
      'error: sets AsyncError when repo returns invalid code failure',
      () async {
        fake.nextJoinResult = const mr.Error(
          AuthFailure('Código de invitación no válido.'),
        );

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(onboardingControllerProvider.notifier);
        await notifier.joinExistingHousehold('BAD');

        final state = container.read(onboardingControllerProvider);
        expect(state, isA<AsyncError<void>>());
      },
    );
  });
}
