import 'package:biyuya/src/core/presentation/extensions/context_extensions.dart';
import 'package:biyuya/src/core/presentation/utils/form_validators.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_form_controller.dart';
import 'package:biyuya/src/navigation/routes/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(authFormControllerProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authFormState = ref.watch(authFormControllerProvider);
    final isLoading = authFormState.isLoading;

    ref.listen<AsyncValue<void>>(authFormControllerProvider, (_, state) {
      state.whenOrNull(
        error: (error, _) {
          context.showErrorSnackBar(error.toString());
        },
      );
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'images/logo_no_background.png',
                      width: 150,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Cuentas claras',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Control de gastos transparente',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
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
                    validator: FormValidators.loginPassword,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Iniciar Sesión'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.push(AppRoute.register.path),
                    child: const Text('¿No tenés cuenta? Registrate acá'),
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
