import 'dart:async';

import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/domain/entities/household_data.dart';
import 'package:biyuya/src/features/auth/domain/repositories/auth_repository_base.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/auth/provider/household_provider.dart';
import 'package:biyuya/src/features/profile/presentation/views/profile_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:multiple_result/multiple_result.dart' as mr;
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../../../helpers/test_helpers.dart';

class _FakeSession extends AuthSessionController {
  _FakeSession(this._profile);

  final UserProfile _profile;
  int leaveCalls = 0;
  int deleteCalls = 0;

  @override
  FutureOr<UserProfile?> build() => _profile;

  @override
  Future<mr.Result<void, AuthFailure>> leaveHousehold() async {
    leaveCalls++;
    return const mr.Success(null);
  }

  @override
  Future<mr.Result<void, AuthFailure>> deleteHousehold() async {
    deleteCalls++;
    return const mr.Success(null);
  }
}

class _FakeHouseholdName extends HouseholdName {
  @override
  Future<HouseholdData?> build() async =>
      const HouseholdData(name: 'Casa', inviteCode: 'ABC123');
}

List<Override> _overrides(_FakeSession session) => [
  authSessionControllerProvider.overrideWith(() => session),
  householdNameProvider.overrideWith(_FakeHouseholdName.new),
];

void main() {
  group('ProfileView household actions', () {
    testWidgets('owner deletes household confirming by typing the name', (
      tester,
    ) async {
      final session = _FakeSession(
        const UserProfile(
          id: 'u1',
          name: 'Ana',
          lastName: 'P',
          householdId: '1',
          role: 'owner',
        ),
      );
      await tester.pumpWidget(
        wrapTest(child: const ProfileView(), overrides: _overrides(session)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Eliminar hogar'), findsOneWidget);
      expect(find.text('Salir del hogar'), findsNothing);

      await tester.tap(find.text('Eliminar hogar'));
      await tester.pumpAndSettle();

      final confirm = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Eliminar'),
      );
      expect(confirm.onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Casa');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(session.deleteCalls, 1);
    });

    testWidgets('member leaves household', (tester) async {
      final session = _FakeSession(
        const UserProfile(
          id: 'u1',
          name: 'Ana',
          lastName: 'P',
          householdId: '1',
        ),
      );
      await tester.pumpWidget(
        wrapTest(child: const ProfileView(), overrides: _overrides(session)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Salir del hogar'), findsOneWidget);
      expect(find.text('Eliminar hogar'), findsNothing);

      await tester.tap(find.text('Salir del hogar'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Salir'));
      await tester.pumpAndSettle();

      expect(session.leaveCalls, 1);
    });
  });
}
