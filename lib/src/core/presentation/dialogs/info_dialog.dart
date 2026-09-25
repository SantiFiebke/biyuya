import 'package:material_ui/material_ui.dart';

/// Shows an informational dialog with a single dismiss button.
Future<void> showInfoDialog({
  required BuildContext context,
  required String title,
  required String content,
  String buttonLabel = 'Entendido',
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content, style: Theme.of(context).textTheme.bodyLarge),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonLabel),
        ),
      ],
    ),
  );
}
