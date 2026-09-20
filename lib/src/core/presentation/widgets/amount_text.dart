import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Monto con el símbolo `$` más chico/atenuado y el número con peso.
class AmountText extends StatelessWidget {
  const AmountText({
    required this.amount,
    this.style,
    this.color,
    this.showSign = false,
    super.key,
  });

  final double amount;
  final TextStyle? style;
  final Color? color;
  final bool showSign;

  static final NumberFormat _format = NumberFormat.currency(
    locale: 'es_AR',
    symbol: '',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final base = (style ?? Theme.of(context).textTheme.titleMedium)?.copyWith(
      color: color,
      fontWeight: FontWeight.w700,
    );
    final symbolStyle = base?.copyWith(
      fontSize: (base.fontSize ?? 16) * 0.75,
      color: (color ?? base.color)?.withValues(alpha: 0.8),
      fontWeight: FontWeight.w600,
    );
    final sign = showSign ? (amount < 0 ? '-' : '+') : '';
    final value = _format.format(amount.abs()).trim();
    return RichText(
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: '$sign\$ ', style: symbolStyle),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
