import 'package:biyuya/src/features/home/presentation/widgets/first_steps_checklist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/test_helpers.dart';

List<FirstStepItem> _items({
  required VoidCallback onFirst,
  required VoidCallback onSecond,
  bool firstDone = false,
  bool secondDone = false,
}) => [
  FirstStepItem(
    label: 'Registrá tu primer gasto',
    done: firstDone,
    onTap: onFirst,
  ),
  FirstStepItem(label: 'Invitá a alguien', done: secondDone, onTap: onSecond),
];

Future<void> _pumpChecklist(
  WidgetTester tester, {
  required List<FirstStepItem> items,
  required VoidCallback onDismiss,
}) async {
  await tester.pumpWidget(
    wrapTest(
      child: FirstStepsChecklist(items: items, onDismiss: onDismiss),
    ),
  );
  await tester.pump();
}

void main() {
  group('FirstStepsChecklist', () {
    testWidgets('renders title and all item labels', (tester) async {
      var taps = 0;
      await _pumpChecklist(
        tester,
        items: _items(onFirst: () => taps++, onSecond: () => taps++),
        onDismiss: () {},
      );

      expect(find.text('Primeros pasos'), findsOneWidget);
      expect(find.text('Registrá tu primer gasto'), findsOneWidget);
      expect(find.text('Invitá a alguien'), findsOneWidget);
    });

    testWidgets('shows check icon for done and unchecked for pending', (
      tester,
    ) async {
      await _pumpChecklist(
        tester,
        items: _items(firstDone: true, onFirst: () {}, onSecond: () {}),
        onDismiss: () {},
      );

      final tiles = find.byType(ListTile);
      expect(tiles, findsNWidgets(2));
      expect(
        find.descendant(
          of: tiles.at(0),
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: tiles.at(1),
          matching: find.byIcon(Icons.radio_button_unchecked),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping an item calls its onTap', (tester) async {
      var taps = 0;
      await _pumpChecklist(
        tester,
        items: _items(onFirst: () => taps++, onSecond: () => taps++),
        onDismiss: () {},
      );

      await tester.tap(find.byType(ListTile).at(1));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('tapping X calls onDismiss', (tester) async {
      var dismissed = false;
      await _pumpChecklist(
        tester,
        items: _items(onFirst: () {}, onSecond: () {}),
        onDismiss: () => dismissed = true,
      );

      await tester.tap(find.byTooltip('Ocultar'));
      await tester.pump();

      expect(dismissed, isTrue);
    });

    testWidgets('done item uses line-through decoration', (tester) async {
      await _pumpChecklist(
        tester,
        items: _items(firstDone: true, onFirst: () {}, onSecond: () {}),
        onDismiss: () {},
      );

      final doneText = tester.widget<Text>(
        find.text('Registrá tu primer gasto'),
      );
      expect(doneText.style?.decoration, TextDecoration.lineThrough);

      final pendingText = tester.widget<Text>(find.text('Invitá a alguien'));
      expect(pendingText.style?.decoration, isNot(TextDecoration.lineThrough));
    });
  });
}
