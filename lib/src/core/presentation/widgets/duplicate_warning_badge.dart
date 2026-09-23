import 'package:material_ui/material_ui.dart';

/// Small pill warning about a possible duplicate expense.
class DuplicateWarningBadge extends StatelessWidget {
  const DuplicateWarningBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.tertiaryContainer;
    final fg = theme.colorScheme.onTertiaryContainer;

    return Tooltip(
      message: 'Posible duplicado',
      child: Semantics(
        container: true,
        label: 'Posible duplicado',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 12, color: fg),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'posible duplicado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
