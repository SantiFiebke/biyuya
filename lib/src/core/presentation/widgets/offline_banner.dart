import 'package:biyuya/src/core/network/connectivity_provider.dart';
import 'package:biyuya/theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Slim banner shown while the device has no connectivity.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider).value;
    if (isOnline != false) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final tint =
        theme.extension<AppColors>()?.expense ?? theme.colorScheme.error;

    return Material(
      color: tint.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, size: 18, color: tint),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sin conexión — los gastos se guardarán y sincronizarán al reconectar',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
