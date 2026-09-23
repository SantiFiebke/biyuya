import 'dart:async';

import 'package:biyuya/src/core/data/models/user_profile_model.dart';
import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/core/network/network_timeout.dart';
import 'package:biyuya/src/features/auth/data/local/profile_cache.dart';
import 'package:biyuya/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:biyuya/src/features/auth/domain/repositories/auth_repository_base.dart';
import 'package:biyuya/src/features/categories/data/local/category_cache.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class _MockSupabaseClient extends Mock implements supabase.SupabaseClient {}

class _MockAuthClient extends Mock implements supabase.GoTrueClient {}

class _MockQueryBuilder extends Mock implements supabase.SupabaseQueryBuilder {}

class _MockFilterBuilder extends Mock
    implements supabase.PostgrestFilterBuilder<supabase.PostgrestList> {}

class _MockTransformBuilder extends Mock
    implements supabase.PostgrestTransformBuilder<Map<String, dynamic>> {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // No household: round-trips through ProfileCache cleanly.
  const cachedProfile = UserProfileModel(
    id: 'user-1',
    name: 'Ada',
    lastName: 'Lovelace',
  );

  // Has a household: exposes the ProfileCache round-trip bug (see below).
  const cachedProfileWithHousehold = UserProfileModel(
    id: 'user-1',
    name: 'Ada',
    lastName: 'Lovelace',
    householdId: '42',
  );

  late _MockSupabaseClient client;
  late _MockAuthClient auth;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    client = _MockSupabaseClient();
    auth = _MockAuthClient();
    when(() => client.auth).thenReturn(auth);
  });

  AuthRepositoryImpl buildRepository() =>
      AuthRepositoryImpl(client, const ProfileCache(), const CategoryCache());

  group('AuthRepositoryImpl.getUserProfile offline fallback', () {
    test('returns cached profile when remote call throws', () async {
      // Remote throws: client.from(...) fails immediately.
      when(() => client.from(any())).thenThrow(Exception('offline'));

      await const ProfileCache().save(cachedProfile);

      final result = await buildRepository().getUserProfile('user-1');

      expect(result.isSuccess(), isTrue);
      expect(result.when((profile) => profile, (error) => null), cachedProfile);
    });

    test(
      'returns cached profile with a household when remote call throws',
      () async {
        when(() => client.from(any())).thenThrow(Exception('offline'));

        await const ProfileCache().save(cachedProfileWithHousehold);

        final result = await buildRepository().getUserProfile('user-1');

        expect(result.isSuccess(), isTrue);
        expect(
          result.when((profile) => profile, (error) => null),
          cachedProfileWithHousehold,
        );
      },
    );

    test('returns failure when remote throws and cache is empty', () async {
      when(() => client.from(any())).thenThrow(Exception('offline'));

      final result = await buildRepository().getUserProfile('user-1');

      expect(result.isError(), isTrue);
    });

    test('returns failure when cached profile id does not match', () async {
      when(() => client.from(any())).thenThrow(Exception('offline'));

      await const ProfileCache().save(cachedProfile);

      final result = await buildRepository().getUserProfile('other-user');

      expect(result.isError(), isTrue);
    });
  });

  group('AuthRepositoryImpl.getUserProfile network timeout', () {
    test('times out after kNetworkTimeout and returns the cached profile', () {
      fakeAsync((async) {
        // Seed the cache that the fallback path must return.
        unawaited(const ProfileCache().save(cachedProfile));
        async.flushMicrotasks();

        final neverCompleting = Completer<Map<String, dynamic>>().future;
        final queryBuilder = _MockQueryBuilder();
        final filterBuilder = _MockFilterBuilder();
        final transformBuilder = _MockTransformBuilder();

        when(() => client.from('profiles')).thenAnswer((_) => queryBuilder);
        when(queryBuilder.select).thenAnswer((_) => filterBuilder);
        when(
          () => filterBuilder.eq('id', 'user-1'),
        ).thenAnswer((_) => filterBuilder);
        when(filterBuilder.single).thenAnswer((_) => transformBuilder);
        // Stub only matches the production bound (kNetworkTimeout); a different
        // duration would leave the call unstubbed and fail the test.
        when(
          () => transformBuilder.timeout(kNetworkTimeout),
        ).thenAnswer((_) => neverCompleting.timeout(kNetworkTimeout));

        Result<UserProfile, AuthFailure>? result;
        unawaited(
          buildRepository().getUserProfile('user-1').then((r) => result = r),
        );

        // Still pending before the 5s bound.
        async.elapse(const Duration(seconds: 4));
        expect(result, isNull);

        // Timeout fires -> TimeoutException -> cache fallback.
        async
          ..elapse(const Duration(seconds: 2))
          ..flushMicrotasks();

        expect(result, isNotNull);
        expect(result!.isSuccess(), isTrue);
        expect(result!.when((p) => p, (_) => null), cachedProfile);
      });
    });
  });

  group('AuthRepositoryImpl.signOut', () {
    test('clears the profile cache', () async {
      await const ProfileCache().save(cachedProfile);
      await const CategoryCache().save(const []);
      when(() => auth.signOut()).thenAnswer((_) async {});

      final result = await buildRepository().signOut();

      expect(result.isSuccess(), isTrue);
      expect(await const ProfileCache().load(), isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('cached_profile'), isFalse);
      expect(prefs.containsKey('cached_categories'), isFalse);
    });
  });
}
