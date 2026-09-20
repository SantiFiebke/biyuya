/// Fecha humanizada: 'Hoy', 'Ayer' o '14 de mayo'.
String formatHumanDate(DateTime date) {
  const months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = today.difference(target).inDays;
  if (diff == 0) {
    return 'Hoy';
  }
  if (diff == 1) {
    return 'Ayer';
  }
  return '${target.day} de ${months[target.month - 1]}';
}
