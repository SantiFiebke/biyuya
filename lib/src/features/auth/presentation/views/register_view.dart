import 'package:biyuya/src/core/config/legal_config.dart';
import 'package:biyuya/src/core/presentation/extensions/context_extensions.dart';
import 'package:biyuya/src/core/presentation/utils/form_validators.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_form_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _openLegalUrl(BuildContext context, String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } on Exception {
    if (context.mounted) {
      context.showErrorSnackBar('No se pudo abrir el enlace');
    }
  }
}

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool showPassword = false;
  // Never pre-checked: GDPR consent must be explicit.
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_acceptedTerms) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(authFormControllerProvider.notifier)
        .register(
          name: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          acceptedTerms: _acceptedTerms,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authFormState = ref.watch(authFormControllerProvider);
    final isLoading = authFormState.isLoading;

    ref.listen<AsyncValue<void>>(authFormControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        final error = next.error;
        context.showErrorSnackBar(error.toString());
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: isLoading ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Crear Cuenta',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unite para gestionar las finanzas de tu hogar en tiempo real',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  // Campo Nombre
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                    maxLength: FormValidators.nameMaxLength,
                    enabled: !isLoading,
                    validator: FormValidators.name,
                  ),
                  const SizedBox(height: 16),

                  // Campo Apellido
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Apellido',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                    maxLength: FormValidators.nameMaxLength,
                    enabled: !isLoading,
                    validator: FormValidators.name,
                  ),
                  const SizedBox(height: 16),

                  // Campo Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    validator: FormValidators.email,
                  ),
                  const SizedBox(height: 16),

                  // Campo Contraseña
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: showPassword
                            ? const Icon(Icons.visibility)
                            : const Icon(Icons.visibility_off),
                        onPressed: () => setState(() {
                          showPassword = !showPassword;
                        }),
                      ),
                    ),
                    obscureText: !showPassword,
                    enabled: !isLoading,
                    validator: FormValidators.password,
                  ),
                  const SizedBox(height: 16),

                  // Campo Confirmar Contraseña
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      prefixIcon: const Icon(Icons.lock_clock_outlined),
                      suffixIcon: IconButton(
                        icon: showPassword
                            ? const Icon(Icons.visibility)
                            : const Icon(Icons.visibility_off),
                        onPressed: () => setState(() {
                          showPassword = !showPassword;
                        }),
                      ),
                    ),
                    obscureText: !showPassword,
                    enabled: !isLoading,
                    validator: (v) => FormValidators.confirmPassword(
                      v,
                      _passwordController.text,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Consentimiento explícito (GDPR)
                  TermsConsentCheckbox(
                    value: _acceptedTerms,
                    onChanged: isLoading
                        ? null
                        : (v) => setState(() => _acceptedTerms = v ?? false),
                  ),
                  const SizedBox(height: 16),

                  // Botón de Envío
                  ElevatedButton(
                    onPressed: isLoading || !_acceptedTerms ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Registrarme'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Consentimiento GDPR: checkbox sin pre-seleccionar con enlaces legales.
/// Dumb widget — el estado vive en [RegisterView].
class TermsConsentCheckbox extends StatelessWidget {
  const TermsConsentCheckbox({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final linkStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Acepto los '),
          InkWell(
            onTap: () => _openLegalUrl(context, LegalConfig.termsUrl),
            child: Text('Términos y Condiciones', style: linkStyle),
          ),
          const Text(' y la '),
          InkWell(
            onTap: () => _openLegalUrl(context, LegalConfig.privacyPolicyUrl),
            child: Text('Política de Privacidad', style: linkStyle),
          ),
        ],
      ),
    );
  }
}
