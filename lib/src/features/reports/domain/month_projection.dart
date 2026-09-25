/// ponytail: burn rate lineal — asume gasto uniforme; suficiente para señal de cierre de mes.
double projectMonthEnd({
  required double spentSoFar,
  required DateTime referenceDate,
}) {
  if (spentSoFar <= 0) {
    return 0;
  }
  final daysInMonth = DateTime(
    referenceDate.year,
    referenceDate.month + 1,
    0,
  ).day;
  return spentSoFar / referenceDate.day * daysInMonth;
}
