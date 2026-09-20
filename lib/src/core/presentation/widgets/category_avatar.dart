import 'package:material_ui/material_ui.dart';

/// Avatar circular con fondo pastel para una categoría.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    required this.icon,
    this.color,
    this.size = 40,
    super.key,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final base = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: base, size: size * 0.5),
    );
  }
}
