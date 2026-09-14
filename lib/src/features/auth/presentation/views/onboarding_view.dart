import 'package:biyuya/src/core/presentation/dialogs/confirm_action_dialog.dart';
import 'package:biyuya/src/core/presentation/extensions/context_extensions.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/onboarding_controller.dart';
import 'package:biyuya/src/features/auth/presentation/widgets/create_household_form.dart';
import 'package:biyuya/src/features/auth/presentation/widgets/join_household_form.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  int _selectedIndex = 0; // 0 = crear, 1 = unirme

  Future<void> _createHousehold(String name) async {
    await ref
        .read(onboardingControllerProvider.notifier)
        .createNewHousehold(name);
  }

  Future<void> _joinHousehold(String inviteCode) async {
    await ref
        .read(onboardingControllerProvider.notifier)
        .joinExistingHousehold(inviteCode);
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showConfirmActionDialog(
      context: context,
      title: 'Cerrar sesión',
      content: '¿Seguro que deseas cerrar sesión?',
      confirmLabel: 'Cerrar sesión',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      await ref.read(authSessionControllerProvider.notifier).signOut();
    } on Exception catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingControllerProvider);
    final isLoading = onboardingState.isLoading;

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
          onPressed: isLoading ? null : () => _showLogoutDialog(context),
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

              _OnboardingOptions(
                selectedIndex: _selectedIndex,
                isLoading: isLoading,
                onSelected: (index) => setState(() => _selectedIndex = index),
              ),
              const SizedBox(height: 24),
              if (_selectedIndex == 0)
                CreateHouseholdForm(
                  onSubmit: _createHousehold,
                  isLoading: isLoading,
                )
              else
                JoinHouseholdForm(
                  onSubmit: _joinHousehold,
                  isLoading: isLoading,
                ),
            ],
          ),
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
