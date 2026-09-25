import 'package:material_ui/material_ui.dart';

/// Shows a confirmation dialog and returns true if confirmed, false otherwise.
Future<bool> showConfirmActionDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content, style: Theme.of(context).textTheme.bodyLarge),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmLabel,
            style: isDestructive
                ? TextStyle(color: Theme.of(context).colorScheme.error)
                : null,
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
