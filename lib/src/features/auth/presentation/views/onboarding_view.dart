import 'package:biyuya/src/core/presentation/extensions/context_extensions.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/onboarding_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  int _selectedIndex = 0; // 0 = crear, 1 = unirme
  bool _showingInviteCode = false;

  Future<void> _createHousehold(String name) async {
    await ref
        .read(onboardingControllerProvider.notifier)
        .createNewHousehold(name);

    final household = ref
        .read(onboardingControllerProvider.notifier)
        .createdHousehold;
    if (household?.inviteCode != null && mounted) {
      setState(() => _showingInviteCode = true);
    }
  }

  Future<void> _joinHousehold(String inviteCode) async {
    await ref
        .read(onboardingControllerProvider.notifier)
        .joinExistingHousehold(inviteCode);
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingControllerProvider);
    final isLoading = onboardingState.isLoading;
    final household = ref
        .read(onboardingControllerProvider.notifier)
        .createdHousehold;

    ref.listen<AsyncValue<void>>(onboardingControllerProvider, (_, state) {
      state.whenOrNull(
        error: (error, _) {
          context.showErrorSnackBar(error.toString());
        },
      );
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Configurar Hogar',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Creá un hogar nuevo o unite a uno existente',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              if (_showingInviteCode && household?.inviteCode != null)
                _InviteCodeDisplay(
                  householdName: household!.name,
                  inviteCode: household.inviteCode!,
                  onContinue: () => context.go('/home'),
                )
              else ...[
                _OnboardingOptions(
                  selectedIndex: _selectedIndex,
                  isLoading: isLoading,
                  onSelected: (index) => setState(() => _selectedIndex = index),
                ),
                const SizedBox(height: 24),
                if (_selectedIndex == 0)
                  _CreateHouseholdForm(
                    onSubmit: _createHousehold,
                    isLoading: isLoading,
                  )
                else
                  _JoinHouseholdForm(
                    onSubmit: _joinHousehold,
                    isLoading: isLoading,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteCodeDisplay extends StatelessWidget {
  const _InviteCodeDisplay({
    required this.householdName,
    required this.inviteCode,
    required this.onContinue,
  });

  final String householdName;
  final String inviteCode;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '¡Hogar creado!',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              householdName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Compartí este código con tu pareja:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                inviteCode,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: inviteCode));
                    if (context.mounted) {
                      context.showSuccessSnackBar('Código copiado');
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar código'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    // ponytail: clipboard for now, share_plus when needed
                    await Clipboard.setData(ClipboardData(text: inviteCode));
                    if (context.mounted) {
                      context.showSuccessSnackBar(
                        'Código copiado para compartir',
                      );
                    }
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingOptions extends StatelessWidget {
  const _OnboardingOptions({
    required this.selectedIndex,
    required this.isLoading,
    required this.onSelected,
  });

  final int selectedIndex;
  final bool isLoading;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(
          value: 0,
          label: Text('Crear Hogar'),
          icon: Icon(Icons.add_home),
        ),
        ButtonSegment(
          value: 1,
          label: Text('Unirme'),
          icon: Icon(Icons.group_add),
        ),
      ],
      selected: {selectedIndex},
      onSelectionChanged: isLoading
          ? null
          : (values) => onSelected(values.first),
    );
  }
}

class _CreateHouseholdForm extends StatefulWidget {
  const _CreateHouseholdForm({required this.onSubmit, required this.isLoading});

  final ValueChanged<String> onSubmit;
  final bool isLoading;

  @override
  State<_CreateHouseholdForm> createState() => _CreateHouseholdFormState();
}

class _CreateHouseholdFormState extends State<_CreateHouseholdForm> {
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

class _JoinHouseholdForm extends StatefulWidget {
  const _JoinHouseholdForm({required this.onSubmit, required this.isLoading});

  final ValueChanged<String> onSubmit;
  final bool isLoading;

  @override
  State<_JoinHouseholdForm> createState() => _JoinHouseholdFormState();
}

class _JoinHouseholdFormState extends State<_JoinHouseholdForm> {
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
