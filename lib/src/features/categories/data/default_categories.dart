import 'package:material_ui/material_ui.dart';

/// Categorías por defecto sembradas al crear un hogar.
///
/// Los iconos se resuelven desde la clase Icons de Flutter para que los
/// codePoints sean siempre correctos; se envían al RPC `create_household`
/// como strings decimales.
class DefaultCategory {
  const DefaultCategory({
    required this.name,
    required this.color,
    required this.icon,
  });

  final String name;
  final String color;
  final int icon;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'color': color,
    'icon': icon.toString(),
  };
}

final List<DefaultCategory> defaultCategories = <DefaultCategory>[
  DefaultCategory(
    name: 'Alimentos',
    color: '#F44336',
    icon: Icons.restaurant.codePoint,
  ),
  DefaultCategory(
    name: 'Transporte',
    color: '#2196F3',
    icon: Icons.directions_bus.codePoint,
  ),
  DefaultCategory(
    name: 'Vivienda',
    color: '#9C27B0',
    icon: Icons.home.codePoint,
  ),
  DefaultCategory(
    name: 'Servicios',
    color: '#FF9800',
    icon: Icons.bolt.codePoint,
  ),
  DefaultCategory(
    name: 'Salud',
    color: '#4CAF50',
    icon: Icons.local_hospital.codePoint,
  ),
  DefaultCategory(
    name: 'Ocio',
    color: '#E91E63',
    icon: Icons.sports_esports.codePoint,
  ),
  DefaultCategory(
    name: 'Educación',
    color: '#3F51B5',
    icon: Icons.school.codePoint,
  ),
  DefaultCategory(
    name: 'Otros',
    color: '#607D8B',
    icon: Icons.category.codePoint,
  ),
];
