import 'package:biyuya/src/core/presentation/utils/form_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String chars(int n) => List.filled(n, 'a').join();

  group('FormValidators.amount', () {
    test('rejects empty', () => expect(FormValidators.amount(''), isNotNull));
    test(
      'rejects non numeric',
      () => expect(FormValidators.amount('abc'), isNotNull),
    );
    test('rejects zero', () => expect(FormValidators.amount('0'), isNotNull));
    test(
      'rejects negative',
      () => expect(FormValidators.amount('-5'), isNotNull),
    );
    test(
      'rejects 9 integer digits',
      () => expect(FormValidators.amount('100000000'), isNotNull),
    );
    test(
      'accepts max',
      () => expect(FormValidators.amount('99999999.99'), isNull),
    );
    test(
      'rejects 3 decimals',
      () => expect(FormValidators.amount('99999999.999'), isNotNull),
    );
    test(
      'accepts comma decimal',
      () => expect(FormValidators.amount('1234,56'), isNull),
    );
    test(
      'accepts one decimal',
      () => expect(FormValidators.amount('1234.5'), isNull),
    );
    test(
      'accepts small comma',
      () => expect(FormValidators.amount('0,01'), isNull),
    );
  });

  group('FormValidators.parseAmount', () {
    test(
      'parses comma',
      () => expect(FormValidators.parseAmount('1234,56'), 1234.56),
    );
    test(
      'parses dot',
      () => expect(FormValidators.parseAmount('1234.56'), 1234.56),
    );
    test(
      'null on invalid',
      () => expect(FormValidators.parseAmount('abc'), isNull),
    );
    test(
      'null on null',
      () => expect(FormValidators.parseAmount(null), isNull),
    );
  });

  group('FormValidators.description', () {
    test('null ok', () => expect(FormValidators.description(null), isNull));
    test(
      '200 ok',
      () => expect(FormValidators.description(chars(200)), isNull),
    );
    test(
      '201 error',
      () => expect(FormValidators.description(chars(201)), isNotNull),
    );
  });

  group('FormValidators.name', () {
    test('empty error', () => expect(FormValidators.name(''), isNotNull));
    test('200 ok', () => expect(FormValidators.name(chars(200)), isNull));
    test('201 error', () => expect(FormValidators.name(chars(201)), isNotNull));
  });

  group('FormValidators.categoryName', () {
    test(
      'empty error',
      () => expect(FormValidators.categoryName(''), isNotNull),
    );
    test(
      '1 char error',
      () => expect(FormValidators.categoryName('a'), isNotNull),
    );
    test('2 ok', () => expect(FormValidators.categoryName('ab'), isNull));
    test('50 ok', () => expect(FormValidators.categoryName(chars(50)), isNull));
    test(
      '51 error',
      () => expect(FormValidators.categoryName(chars(51)), isNotNull),
    );
  });

  group('FormValidators.householdName', () {
    test(
      '1 char error',
      () => expect(FormValidators.householdName('a'), isNotNull),
    );
    test('2 ok', () => expect(FormValidators.householdName('ab'), isNull));
    test(
      '100 ok',
      () => expect(FormValidators.householdName(chars(100)), isNull),
    );
    test(
      '101 error',
      () => expect(FormValidators.householdName(chars(101)), isNotNull),
    );
  });

  group('FormValidators.inviteCode', () {
    test('empty error', () => expect(FormValidators.inviteCode(''), isNotNull));
    test(
      '3 chars error',
      () => expect(FormValidators.inviteCode('abc'), isNotNull),
    );
    test(
      '5 chars error',
      () => expect(FormValidators.inviteCode('ABC12'), isNotNull),
    );
    test(
      '6 upper ok',
      () => expect(FormValidators.inviteCode('ABC123'), isNull),
    );
    test(
      '6 lower ok',
      () => expect(FormValidators.inviteCode('abc123'), isNull),
    );
  });

  group('FormValidators.email', () {
    test('empty error', () => expect(FormValidators.email(''), isNotNull));
    test('invalid error', () => expect(FormValidators.email('foo'), isNotNull));
    test('valid ok', () => expect(FormValidators.email('a@b.com'), isNull));
  });

  group('FormValidators.password', () {
    test('empty error', () => expect(FormValidators.password(''), isNotNull));
    test(
      'short error',
      () => expect(FormValidators.password('abc'), isNotNull),
    );
    test(
      'no upper/digit error',
      () => expect(FormValidators.password('abcdefg'), isNotNull),
    );
    test(
      'no digit error',
      () => expect(FormValidators.password('Abcdefg'), isNotNull),
    );
    test(
      'no upper error',
      () => expect(FormValidators.password('abcdefg1'), isNotNull),
    );
    test('valid ok', () => expect(FormValidators.password('Abcdefg1'), isNull));
  });

  group('FormValidators.loginPassword', () {
    test(
      'empty error',
      () => expect(FormValidators.loginPassword(''), isNotNull),
    );
    test('any ok', () => expect(FormValidators.loginPassword('x'), isNull));
  });

  group('FormValidators.confirmPassword', () {
    test(
      'match ok',
      () => expect(
        FormValidators.confirmPassword('Abcdefg1', 'Abcdefg1'),
        isNull,
      ),
    );
    test(
      'mismatch error',
      () => expect(FormValidators.confirmPassword('x', 'Abcdefg1'), isNotNull),
    );
    test(
      'null error',
      () => expect(FormValidators.confirmPassword(null, 'x'), isNotNull),
    );
  });

  group('DecimalTextInputFormatter', () {
    const formatter = DecimalTextInputFormatter();

    TextEditingValue apply(String text) => formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: text),
    );

    test('accepts digits', () => expect(apply('123').text, '123'));
    test(
      'accepts comma decimals',
      () => expect(apply('123,45').text, '123,45'),
    );
    test(
      'rejects 3 decimals',
      () => expect(apply('123.456').text, isNot('123.456')),
    );
    test(
      'rejects 9 integer digits',
      () => expect(apply('123456789').text, isNot('123456789')),
    );
    test('rejects letters', () => expect(apply('abc').text, isNot('abc')));
    test('accepts empty', () => expect(apply('').text, ''));
  });

  group('FormValidators.formatAmountInput', () {
    test(
      'formats with comma decimal separator',
      () => expect(FormValidators.formatAmountInput(150.75), '150,75'),
    );
  });

  group('FormValidators.parseAmount es_AR separators', () {
    test(
      'parses grouping dot + comma decimal',
      () => expect(FormValidators.parseAmount('1.234,56'), 1234.56),
    );
    test(
      'parses grouping-only dot as thousands',
      () => expect(FormValidators.parseAmount('1.000'), 1000.0),
    );
  });

  group('CurrencyTextInputFormatter', () {
    final formatter = CurrencyTextInputFormatter();

    TextEditingValue apply(String text, {String old = ''}) =>
        formatter.formatEditUpdate(
          TextEditingValue(text: old),
          TextEditingValue(text: text),
        );

    test('appending digit to "1.000" yields "10.000"', () {
      expect(apply('1.0000', old: '1.000').text, '10.000');
    });
    test('appending digit to "1.500" yields "15.000"', () {
      expect(apply('1.5000', old: '1.500').text, '15.000');
    });
    test('groups four digits', () => expect(apply('1500').text, '1.500'));
    test(
      'formats integer + decimal',
      () => expect(apply('1234,56').text, '1.234,56'),
    );
    test(
      'strips letters and symbols',
      () => expect(apply('abc12x3').text, '123'),
    );
    test('rejects 3 decimals', () {
      expect(apply('1.234,567', old: '1.234,56').text, '1.234,56');
    });
    test('rejects 9 integer digits', () {
      expect(apply('123456789', old: '12.345.678').text, '12.345.678');
    });
    test('empty stays empty', () => expect(apply('').text, ''));
    test('zero stays zero', () => expect(apply('0').text, '0'));
    test(
      'trailing comma preserved',
      () => expect(apply('1.000,').text, '1.000,'),
    );
    test('idempotent', () {
      final once = apply('1500').text;
      expect(apply(once).text, once);
      expect(once, '1.500');
    });
  });
}
