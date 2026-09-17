import 'package:material_ui/material_ui.dart';

class CreateHouseholdForm extends StatefulWidget {
  const CreateHouseholdForm({
    required this.onSubmit,
    required this.isLoading,
    super.key,
  });

  final ValueChanged<String> onSubmit;
  final bool isLoading;

  @override
  State<CreateHouseholdForm> createState() => CreateHouseholdFormState();
}

class CreateHouseholdFormState extends State<CreateHouseholdForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    widget.onSubmit(_nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del hogar',
              prefixIcon: Icon(Icons.home_outlined),
            ),
            textCapitalization: TextCapitalization.words,
            enabled: !widget.isLoading,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor, ingresa un nombre';
              }
              if (value.trim().length < 2) {
                return 'El nombre debe tener al menos 2 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.isLoading ? null : _submit,
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Crear'),
          ),
        ],
      ),
    );
  }
}
