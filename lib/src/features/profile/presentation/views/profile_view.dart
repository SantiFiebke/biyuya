import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/core/presentation/dialogs/confirm_action_dialog.dart';
import 'package:biyuya/src/core/presentation/extensions/context_extensions.dart';
import 'package:biyuya/src/core/provider/theme_provider.dart';
import 'package:biyuya/src/features/auth/domain/entities/household_data.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/auth/provider/household_provider.dart';
import 'package:biyuya/src/features/profile/presentation/widgets/delete_household_dialog.dart';
import 'package:biyuya/src/features/settings/presentation/controllers/settings_controller.dart';
import 'package:biyuya/src/navigation/routes/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionControllerProvider);
    final householdName = ref.watch(householdNameProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: session.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (userProfile) {
          if (userProfile == null) {
            return const Center(child: Text('No hay sesión activa'));
          }
          return ProfileContent(
            userProfile: userProfile,
            householdName: householdName,
          );
        },
      ),
    );
  }
}

class ProfileContent extends StatelessWidget {
  const ProfileContent({
    required this.userProfile,
    required this.householdName,
    super.key,
  });

  final UserProfile userProfile;
  final AsyncValue<HouseholdData?> householdName;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UserInfoCard(userProfile: userProfile),
          const SizedBox(height: 16),
          _HouseholdInfoCard(householdName: householdName),
          const SizedBox(height: 16),
          const _MenuItems(),
          const SizedBox(height: 16),
          const _HouseholdActionsCard(),
          const SizedBox(height: 24),
          const _LogoutButton(),
        ],
      ),
    );
  }
}

class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard({required this.userProfile});

  final UserProfile userProfile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                '${userProfile.name[0]}${userProfile.lastName[0]}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${userProfile.name} ${userProfile.lastName}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HouseholdInfoCard extends StatelessWidget {
  const _HouseholdInfoCard({required this.householdName});

  final AsyncValue<HouseholdData?> householdName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hogar',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.home_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: householdName.when(
                    loading: () => const Text('Cargando...'),
                    error: (_, _) => const Text('Error al cargar'),
                    data: (data) => Text(
                      data?.name ?? 'Sin nombre',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItems extends ConsumerWidget {
  const _MenuItems();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categorías'),
            subtitle: const Text('Gestionar categorías de gastos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoute.categories.path),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Modo oscuro'),
            subtitle: const Text('Cambiar tema de la app'),
            value: ref.watch(themeProvider).isDark,
            onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.handshake_outlined),
            title: const Text('Liquidación de deudas'),
            subtitle: const Text(
              'Mostrar saldos y transfers entre miembros del hogar',
            ),
            value:
                ref
                    .watch(settingsControllerProvider)
                    .value
                    ?.debtSettlementEnabled ??
                false,
            onChanged: (v) => _toggleFlag(
              context,
              value: v,
              explainerSeen:
                  ref
                      .read(settingsControllerProvider)
                      .value
                      ?.debtSettlementExplainerSeen ??
                  false,
              explainerTitle: 'Liquidación de deudas',
              explainerContent:
                  'Si comparten gastos, acá vas a ver quién le debe a quién y cuánto. La app suma lo que pagó cada uno y calcula las transferencias para quedar a mano. ¿La activamos?',
              setEnabled: ({required enabled}) => ref
                  .read(settingsControllerProvider.notifier)
                  .setDebtSettlementEnabled(enabled: enabled),
              markSeen: () => ref
                  .read(settingsControllerProvider.notifier)
                  .markDebtSettlementExplainerSeen(),
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.trending_up),
            title: const Text('Proyección fin de mes'),
            subtitle: const Text('Estimar cuánto vas a gastar este mes'),
            value:
                ref
                    .watch(settingsControllerProvider)
                    .value
                    ?.monthProjectionEnabled ??
                false,
            onChanged: (v) => _toggleFlag(
              context,
              value: v,
              explainerSeen:
                  ref
                      .read(settingsControllerProvider)
                      .value
                      ?.monthProjectionExplainerSeen ??
                  false,
              explainerTitle: 'Proyección fin de mes',
              explainerContent:
                  'Te muestra cuánto vas a gastar al terminar el mes, siguiendo el ritmo que llevás hasta ahora. Ojo: es un cálculo simple, no distingue gastos de una sola vez (tarjetas, servicios, cuotas), así que puede variar. ¿La activamos?',
              setEnabled: ({required enabled}) => ref
                  .read(settingsControllerProvider.notifier)
                  .setMonthProjectionEnabled(enabled: enabled),
              markSeen: () => ref
                  .read(settingsControllerProvider.notifier)
                  .markMonthProjectionExplainerSeen(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Explainer-on-first-enable pattern shared by the settings switches:
/// turning ON shows a confirm dialog once, later toggles apply directly.
Future<void> _toggleFlag(
  BuildContext context, {
  required bool value,
  required bool explainerSeen,
  required String explainerTitle,
  required String explainerContent,
  required Future<void> Function({required bool enabled}) setEnabled,
  required Future<void> Function() markSeen,
}) async {
  if (!value || explainerSeen) {
    await setEnabled(enabled: value);
    return;
  }

  final confirmed = await showConfirmActionDialog(
    context: context,
    title: explainerTitle,
    content: explainerContent,
    confirmLabel: 'Activar',
  );
  if (!confirmed || !context.mounted) {
    return;
  }

  await setEnabled(enabled: true);
  await markSeen();
}

class _HouseholdActionsCard extends ConsumerWidget {
  const _HouseholdActionsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(authSessionControllerProvider).asData?.value;
    final isOwner = userProfile?.isOwner ?? false;
    final hasHousehold = userProfile?.hasHousehold ?? false;

    if (!hasHousehold) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Column(
        children: [
          if (isOwner)
            ListTile(
              leading: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Eliminar hogar'),
              subtitle: const Text('Eliminar hogar y todos sus datos'),
              onTap: () async {
                final name = ref
                    .read(householdNameProvider)
                    .asData
                    ?.value
                    ?.name;
                if (name == null) {
                  if (context.mounted) {
                    context.showErrorSnackBar(
                      'No se pudo obtener el nombre del hogar',
                    );
                  }
                  return;
                }

                final confirmed = await showDeleteHouseholdDialog(
                  context,
                  householdName: name,
                );
                if (!confirmed || !context.mounted) {
                  return;
                }

                final result = await ref
                    .read(authSessionControllerProvider.notifier)
                    .deleteHousehold();
                if (!context.mounted) {
                  return;
                }
                result.when(
                  (_) => context.showSuccessSnackBar('Hogar eliminado'),
                  (failure) => context.showErrorSnackBar(failure.message),
                );
              },
            )
          else
            ListTile(
              leading: Icon(
                Icons.logout_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Salir del hogar'),
              subtitle: const Text('Tus gastos quedarán en el hogar'),
              onTap: () async {
                final confirmed = await showConfirmActionDialog(
                  context: context,
                  title: 'Salir del hogar',
                  content:
                      '¿Seguro que querés salir de este hogar? Tus gastos quedarán en el hogar.',
                  confirmLabel: 'Salir',
                  isDestructive: true,
                );
                if (!confirmed || !context.mounted) {
                  return;
                }

                final result = await ref
                    .read(authSessionControllerProvider.notifier)
                    .leaveHousehold();
                if (!context.mounted) {
                  return;
                }
                result.when(
                  (_) => context.showSuccessSnackBar('Saliste del hogar'),
                  (failure) => context.showErrorSnackBar(failure.message),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () async {
        final confirmed = await showConfirmActionDialog(
          context: context,
          title: 'Cerrar sesión',
          content: '¿Estás seguro de que querés cerrar sesión?',
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
      },
      icon: const Icon(Icons.logout),
      label: const Text('Cerrar sesión'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
        side: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
