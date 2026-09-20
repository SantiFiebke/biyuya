import 'package:biyuya/src/core/presentation/widgets/empty_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('renders title, message and action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Sin datos',
            message: 'Nada por acá',
            actionLabel: 'Acción',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Sin datos'), findsOneWidget);
    expect(find.text('Nada por acá'), findsOneWidget);
    await tester.tap(find.text('Acción'));
    expect(tapped, isTrue);
  });
}
