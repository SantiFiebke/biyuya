import 'package:material_ui/material_ui.dart';

class JoinHouseholdForm extends StatefulWidget {
  const JoinHouseholdForm({
    required this.onSubmit,
    required this.isLoading,
    super.key,
  });

  final ValueChanged<String> onSubmit;
  final bool isLoading;

  @override
  State<JoinHouseholdForm> createState() => JoinHouseholdFormState();
}

class JoinHouseholdFormState extends State<JoinHouseholdForm> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    widget.onSubmit(_codeController.text.trim().toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Código de invitación',
              hintText: 'Ej: ABC123',
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            enabled: !widget.isLoading,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor, ingresa el código';
              }
              if (value.trim().length != 6) {
                return 'El código debe tener 6 caracteres';
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
                : const Text('Unirme'),
          ),
        ],
      ),
    );
  }
}
