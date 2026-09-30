import 'dart:async';

import 'package:biyuya/src/core/utils/request_guard.dart';
import 'package:flutter_test/flutter_test.dart';

class _Guarded with RequestGuard {}

void main() {
  group('RequestGuard', () {
    late _Guarded guard;

    setUp(() {
      guard = _Guarded();
    });

    group('startRequest / isStale', () {
      test('startRequest returns increasing tokens', () {
        final first = guard.startRequest();
        final second = guard.startRequest();
        final third = guard.startRequest();

        expect(second, greaterThan(first));
        expect(third, greaterThan(second));
      });

      test(
        'isStale is false for the current token, true for a previous one',
        () {
          final first = guard.startRequest();
          expect(guard.isStale(first), isFalse);

          final second = guard.startRequest();
          expect(guard.isStale(first), isTrue);
          expect(guard.isStale(second), isFalse);
        },
      );
    });

    group('currentRequest / invalidateRequests', () {
      test('reading currentRequest does not start a new load', () {
        final token = guard.startRequest();

        expect(guard.currentRequest, token);
        expect(guard.currentRequest, token);
        expect(guard.isStale(token), isFalse);
      });

      test(
        'invalidateRequests makes a prior token stale without a new load',
        () {
          final token = guard.startRequest();

          guard.invalidateRequests();

          expect(guard.isStale(token), isTrue);
          // No new load started: currentRequest advanced by one only.
          expect(guard.currentRequest, token + 1);
        },
      );
    });

    group('runLatest', () {
      test('returns the value when no newer request starts', () async {
        final result = await guard.runLatest(() async => 'value');

        expect(result, 'value');
      });

      test('latest wins: pending older request resolves to null', () async {
        final first = Completer<String>();
        final second = Completer<String>();

        final firstRun = guard.runLatest(() => first.future);
        final secondRun = guard.runLatest(() => second.future);

        // Newer request finishes first → its value is kept.
        second.complete('latest');
        expect(await secondRun, 'latest');

        // Older request finishes afterwards → discarded as stale.
        first.complete('stale');
        expect(await firstRun, isNull);
      });
    });
  });
}
