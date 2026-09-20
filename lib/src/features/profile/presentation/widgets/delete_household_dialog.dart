import 'package:material_ui/material_ui.dart';

Future<bool> showDeleteHouseholdDialog(
  BuildContext context, {
  required String householdName,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _DeleteHouseholdDialog(householdName: householdName),
  );
  return result ?? false;
}

class _DeleteHouseholdDialog extends StatefulWidget {
  const _DeleteHouseholdDialog({required this.householdName});

  final String householdName;

  @override
  State<_DeleteHouseholdDialog> createState() => _DeleteHouseholdDialogState();
}

class _DeleteHouseholdDialogState extends State<_DeleteHouseholdDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _controller.text.trim() == widget.householdName;
    return AlertDialog(
      title: const Text('Eliminar hogar'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Esta acción es irreversible. Se eliminarán TODOS los gastos y '
            'categorías del hogar para todos sus miembros.',
          ),
          const SizedBox(height: 16),
          Text('Escribí "${widget.householdName}" para confirmar:'),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: matches ? () => Navigator.of(context).pop(true) : null,
          child: Text(
            'Eliminar',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}
