import 'dart:async';

import 'package:biyuya/src/core/presentation/extensions/context_extensions.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class InviteCodeSheet extends StatelessWidget {
  const InviteCodeSheet({required this.inviteCode, super.key});

  final String inviteCode;

  static void show(BuildContext context, {required String inviteCode}) {
    unawaited(
      showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        builder: (_) => InviteCodeSheet(inviteCode: inviteCode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Invitar a tu hogar',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Steps
            const _Step(
              number: 1,
              text: 'Compartí este código con quien quieras invitar',
            ),
            const SizedBox(height: 12),
            const _Step(
              number: 2,
              text: 'Que abra la app y seleccione "Unirme"',
            ),
            const SizedBox(height: 12),
            const _Step(number: 3, text: 'Que ingrese el código y listo'),
            const SizedBox(height: 24),
            // Code display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                inviteCode,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      unawaited(
                        Clipboard.setData(ClipboardData(text: inviteCode)),
                      );
                      context.showSuccessSnackBar('Código copiado');
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      // In real app, would use share_plus
                      unawaited(
                        Clipboard.setData(ClipboardData(text: inviteCode)),
                      );
                      context.showSuccessSnackBar(
                        'Código copiado para compartir',
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Compartir'),
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

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
