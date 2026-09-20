import 'package:biyuya/src/core/presentation/utils/form_validators.dart';
import 'package:flutter/services.dart';
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
            maxLength: FormValidators.inviteCodeLength,
            enabled: !widget.isLoading,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
            ],
            validator: FormValidators.inviteCode,
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
