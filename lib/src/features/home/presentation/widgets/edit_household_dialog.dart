import 'package:biyuya/src/features/auth/provider/household_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

Future<void> showEditHouseholdDialog(BuildContext context, WidgetRef ref) {
  final controller = TextEditingController(
    text: ref.read(householdNameProvider).value?.name ?? '',
  );

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Editar nombre del hogar'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Nombre',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            final name = controller.text.trim();
            if (name.isEmpty) {
              return;
            }
            await ref.read(householdNameProvider.notifier).updateName(name);
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}
