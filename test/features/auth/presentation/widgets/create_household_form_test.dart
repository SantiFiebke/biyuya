import 'package:biyuya/src/features/auth/presentation/widgets/create_household_form.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('CreateHouseholdForm validation', () {
    testWidgets('shows error for empty name', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: CreateHouseholdForm(onSubmit: (_) {}, isLoading: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Crear'));
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresá un nombre'), findsOneWidget);
    });

    testWidgets('shows error for 1 char name', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: CreateHouseholdForm(onSubmit: (_) {}, isLoading: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'a');
      await tester.ensureVisible(find.text('Crear'));
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(find.text('Mínimo 2 caracteres'), findsOneWidget);
    });

    testWidgets('name field maxLength is 100', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: CreateHouseholdForm(onSubmit: (_) {}, isLoading: false),
        ),
      );
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.maxLength, 100);
    });
  });
}
