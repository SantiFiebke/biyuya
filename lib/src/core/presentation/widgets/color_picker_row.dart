import 'package:material_ui/material_ui.dart';

/// Preset hex colors offered when creating or editing a category.
const presetCategoryColors = <String>[
  '#F44336',
  '#E91E63',
  '#9C27B0',
  '#673AB7',
  '#3F51B5',
  '#2196F3',
  '#4CAF50',
  '#FF9800',
  '#795548',
  '#607D8B',
];

/// A row of selectable color circles.
///
/// Dumb widget: colors and selection are provided by the caller.
class ColorPickerRow extends StatelessWidget {
  const ColorPickerRow({
    required this.colors,
    required this.selectedColor,
    required this.onSelected,
    super.key,
  });

  final List<Color> colors;
  final Color? selectedColor;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final color in colors)
          _ColorCircle(
            color: color,
            isSelected: selectedColor == color,
            onTap: () => onSelected(color),
          ),
      ],
    );
  }
}

class _ColorCircle extends StatelessWidget {
  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 3,
                )
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}
