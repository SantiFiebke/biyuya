import 'package:material_ui/material_ui.dart';

/// Single checklist entry — data only, callback owned by parent.
class FirstStepItem {
  const FirstStepItem({
    required this.label,
    required this.done,
    required this.onTap,
  });

  final String label;
  final bool done;
  final VoidCallback onTap;
}

/// "Primeros pasos" checklist. Dumb: no providers, all state injected.
class FirstStepsChecklist extends StatelessWidget {
  const FirstStepsChecklist({
    required this.items,
    required this.onDismiss,
    super.key,
  });

  final List<FirstStepItem> items;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Primeros pasos',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Ocultar',
                  onPressed: onDismiss,
                ),
              ],
            ),
            for (final item in items)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  item.done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: item.done ? cs.primary : cs.outline,
                ),
                title: Text(
                  item.label,
                  style: item.done
                      ? theme.textTheme.bodyMedium?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: cs.onSurfaceVariant,
                        )
                      : theme.textTheme.bodyMedium,
                ),
                onTap: item.onTap,
              ),
          ],
        ),
      ),
    );
  }
}
