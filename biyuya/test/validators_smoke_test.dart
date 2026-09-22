import 'package:biyuya/src/core/presentation/utils/form_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty amount', () {
    expect(FormValidators.amount(''), 'Ingresá un monto');
  });
  test('zero amount', () {
    expect(FormValidators.amount('0'), 'El monto debe ser mayor a 0');
  });
}
