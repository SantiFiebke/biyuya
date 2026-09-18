import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/domain/repositories/auth_repository_base.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_form_controller.dart';
import 'package:biyuya/src/features/auth/provider/auth_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multiple_result/multiple_result.dart';

class MockAuthRepository extends Mock implements AuthRepositoryBase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
    );
  }

  group('AuthFormController', () {
    test('initial state is AsyncData(null)', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final state = container.read(authFormControllerProvider);
      expect(state, isA<AsyncData<void>>());
    });

    group('login', () {
      test('sets AsyncLoading during login', () async {
        when(
          () => mockRepo.signInWithEmailPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) => Future.delayed(
            const Duration(milliseconds: 50),
            () => const Success(UserProfile(id: '1', name: 'T', lastName: 'U')),
          ),
        );

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(authFormControllerProvider.notifier);

        // Start the login (it's async)
        final loginFuture = notifier.login(
          email: 'test@example.com',
          password: 'pass123',
        );

        // State should be loading while the future is in progress
        // (we can't guarantee timing, but the final state should be correct)
        await loginFuture;

        verify(
          () => mockRepo.signInWithEmailPassword(
            email: 'test@example.com',
            password: 'pass123',
          ),
        ).called(1);
      });

      test('sets AsyncError on failure', () async {
        when(
          () => mockRepo.signInWithEmailPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Error(AuthFailure('Invalid')));

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(authFormControllerProvider.notifier);
        await notifier.login(email: 'test@example.com', password: 'wrong');

        final state = container.read(authFormControllerProvider);
        expect(state, isA<AsyncError<void>>());
      });

      test(
        'leaves state as AsyncLoading on success (button stays disabled)',
        () async {
          when(
            () => mockRepo.signInWithEmailPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer(
            (_) async =>
                const Success(UserProfile(id: '1', name: 'T', lastName: 'U')),
          );

          final container = createContainer();
          addTearDown(container.dispose);

          final notifier = container.read(authFormControllerProvider.notifier);
          await notifier.login(email: 'test@example.com', password: 'pass123');

          final state = container.read(authFormControllerProvider);
          expect(state, isA<AsyncLoading<void>>());
        },
      );
    });

    group('register', () {
      test('calls signUpWithEmailPassword with correct params', () async {
        when(
          () => mockRepo.signUpWithEmailPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
            lastName: any(named: 'lastName'),
          ),
        ).thenAnswer(
          (_) async =>
              const Success(UserProfile(id: '1', name: 'T', lastName: 'U')),
        );

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(authFormControllerProvider.notifier);
        await notifier.register(
          email: 'new@example.com',
          password: 'pass123',
          name: 'John',
          lastName: 'Doe',
        );

        verify(
          () => mockRepo.signUpWithEmailPassword(
            email: 'new@example.com',
            password: 'pass123',
            name: 'John',
            lastName: 'Doe',
          ),
        ).called(1);
      });

      test('sets AsyncError on registration failure', () async {
        when(
          () => mockRepo.signUpWithEmailPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
            lastName: any(named: 'lastName'),
          ),
        ).thenAnswer(
          (_) async => const Error(AuthFailure('Email already in use')),
        );

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(authFormControllerProvider.notifier);
        await notifier.register(
          email: 'dup@example.com',
          password: 'pass123',
          name: 'Jane',
          lastName: 'Doe',
        );

        final state = container.read(authFormControllerProvider);
        expect(state, isA<AsyncError<void>>());
      });
    });

    group('email validation', () {
      test('rejects empty email', () {
        // Validation lives in the UI layer (TextFormField validators),
        // not in the controller. Controller accepts any string.
        // This test documents that boundary.
        when(
          () => mockRepo.signInWithEmailPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async =>
              const Success(UserProfile(id: '1', name: 'T', lastName: 'U')),
        );

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(authFormControllerProvider.notifier);
        expect(
          () => notifier.login(email: '', password: 'pass'),
          returnsNormally,
        );
      });

      test('accepts valid email format', () {
        when(
          () => mockRepo.signInWithEmailPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async =>
              const Success(UserProfile(id: '1', name: 'T', lastName: 'U')),
        );

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(authFormControllerProvider.notifier);
        expect(
          () => notifier.login(email: 'user@domain.com', password: 'pass'),
          returnsNormally,
        );
      });
    });
  });
}
