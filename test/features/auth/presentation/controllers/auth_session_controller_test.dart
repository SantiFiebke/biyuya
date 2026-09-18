import 'dart:async';

import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/domain/repositories/auth_repository_base.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/auth/provider/auth_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multiple_result/multiple_result.dart';

class MockAuthRepository extends Mock implements AuthRepositoryBase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockRepo;
  late StreamController<UserProfile?> authStateController;
  late StreamController<UserProfile?> profileController;

  setUp(() {
    mockRepo = MockAuthRepository();
    authStateController = StreamController<UserProfile?>();
    profileController = StreamController<UserProfile?>();

    when(
      () => mockRepo.onAuthStateChanged,
    ).thenAnswer((_) => authStateController.stream);
    when(
      () => mockRepo.onProfileChanged(userId: any(named: 'userId')),
    ).thenAnswer((_) => profileController.stream);
    when(() => mockRepo.signOut()).thenAnswer((_) async => const Success(null));
  });

  tearDown(() {
    unawaited(authStateController.close());
    unawaited(profileController.close());
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
    );
  }

  group('AuthSessionController', () {
    test('initial state is loading', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final state = container.read(authSessionControllerProvider);
      expect(state, isA<AsyncLoading<UserProfile?>>());
    });

    test('emits AsyncData when auth state changes to signed in', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      const profile = UserProfile(id: 'user-1', name: 'Test', lastName: 'User');

      // Start listening to trigger the stream subscription
      container.listen<AsyncValue<UserProfile?>>(
        authSessionControllerProvider,
        (_, _) {},
      );

      authStateController.add(profile);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(authSessionControllerProvider);
      expect(state.value, profile);
    });

    test('emits AsyncData(null) when signed out', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      container.listen<AsyncValue<UserProfile?>>(
        authSessionControllerProvider,
        (_, _) {},
      );

      authStateController.add(null);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(authSessionControllerProvider);
      expect(state.value, isNull);
    });

    test('signOut calls repository and clears profile', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      container.listen<AsyncValue<UserProfile?>>(
        authSessionControllerProvider,
        (_, _) {},
      );

      const profile = UserProfile(id: 'user-1', name: 'Test', lastName: 'User');
      authStateController.add(profile);
      await Future<void>.delayed(Duration.zero);

      final controller = container.read(authSessionControllerProvider.notifier);
      await controller.signOut();

      verify(() => mockRepo.signOut()).called(1);
    });

    test('subscribes to profile changes when user is authenticated', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      container.listen<AsyncValue<UserProfile?>>(
        authSessionControllerProvider,
        (_, _) {},
      );

      const profile = UserProfile(id: 'user-1', name: 'Test', lastName: 'User');
      authStateController.add(profile);
      await Future<void>.delayed(Duration.zero);

      verify(() => mockRepo.onProfileChanged(userId: 'user-1')).called(1);
    });
  });
}
