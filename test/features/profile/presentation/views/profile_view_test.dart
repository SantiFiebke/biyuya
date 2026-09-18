import 'package:biyuya/src/features/auth/domain/entities/household_data.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/auth/provider/household_provider.dart';
import 'package:biyuya/src/features/profile/presentation/views/profile_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../../../helpers/test_helpers.dart';

class FakeHouseholdName extends HouseholdName {
  HouseholdData? data;

  @override
  Future<HouseholdData?> build() async => data;
}

List<Override> _baseOverrides({
  HouseholdData? householdData = const HouseholdData(name: 'Mi Hogar'),
}) {
  final fakeNotifier = FakeHouseholdName()..data = householdData;
  return [
    authSessionControllerProvider.overrideWith(FakeAuthSessionController.new),
    householdNameProvider.overrideWith(() => fakeNotifier),
  ];
}

void main() {
  group('ProfileView', () {
    testWidgets('renders user name', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const ProfileView(), overrides: _baseOverrides()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('shows household info', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const ProfileView(), overrides: _baseOverrides()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Mi Hogar'), findsOneWidget);
    });

    testWidgets('logout button exists', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const ProfileView(), overrides: _baseOverrides()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });
  });
}
