import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Validadores y formatters centralizados para formularios.
class FormValidators {
  const FormValidators._();

  static const int amountMaxIntegerDigits = 8;
  static const double amountMax = 99999999.99;
  static const int descriptionMaxLength = 200;
  static const int nameMaxLength = 200;
  static const int categoryNameMaxLength = 50;
  static const int householdNameMaxLength = 100;
  static const int passwordMinLength = 6;
  static const int inviteCodeLength = 6;

  static final RegExp _amountRegExp = RegExp(r'^\d{1,8}(\.\d{1,2})?$');
  static final RegExp _emailRegExp = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final RegExp _inviteCodeRegExp = RegExp(r'^[A-Za-z0-9]{6}$');
  static final RegExp _uppercaseRegExp = RegExp('[A-Z]');
  static final RegExp _digitRegExp = RegExp(r'\d');

  static String? required(
    String? value, {
    String message = 'Este campo es obligatorio',
  }) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  /// Normaliza input de monto: elimina separadores de miles (.) y
  /// convierte decimal (,) a punto para parsing.
  /// En es_AR: punto = separador miles, coma = decimal.
  static String _normalizeAmount(String value) {
    final trimmed = value.trim();
    final hasComma = trimmed.contains(',');
    if (hasComma) {
      // Con coma decimal → último punto es decimal, el resto son miles
      final normalized = trimmed.replaceAll(',', '.');
      final lastDot = normalized.lastIndexOf('.');
      if (lastDot == -1) {
        return normalized;
      }
      final intPart = normalized.substring(0, lastDot).replaceAll('.', '');
      final decPart = normalized.substring(lastDot + 1);
      return '$intPart.$decPart';
    }
    final lastDot = trimmed.lastIndexOf('.');
    if (lastDot == -1) {
      // Sin separador → sin cambios
      return trimmed;
    }
    final trailing = trimmed.substring(lastDot + 1);
    if (trailing.isNotEmpty && trailing.length <= 2) {
      // Último punto es decimal, los anteriores son miles
      final intPart = trimmed.substring(0, lastDot).replaceAll('.', '');
      return '$intPart.$trailing';
    }
    // 3+ dígitos tras el último punto → todos los puntos son miles
    return trimmed.replaceAll('.', '');
  }

  /// Formatea un monto para prellenar inputs (locale es_AR, coma decimal).
  static String formatAmountInput(double amount) {
    return NumberFormat.currency(
      locale: 'es_AR',
      symbol: '',
      decimalDigits: 2,
    ).format(amount).trim();
  }

  /// Normaliza el separador decimal (coma -> punto) y parsea.
  static double? parseAmount(String? value) {
    if (value == null) {
      return null;
    }
    return double.tryParse(_normalizeAmount(value));
  }

  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresá un monto';
    }
    final normalized = _normalizeAmount(value);
    if (!_amountRegExp.hasMatch(normalized)) {
      return 'Ingresá un monto válido (máx. 2 decimales)';
    }
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return 'El monto debe ser mayor a 0';
    }
    if (parsed > amountMax) {
      return 'El monto máximo es 99.999.999,99';
    }
    return null;
  }

  static String? description(String? value) {
    if (value == null) {
      return null;
    }
    if (value.trim().length > descriptionMaxLength) {
      return 'Máximo $descriptionMaxLength caracteres';
    }
    return null;
  }

  static String? name(String? value, {int maxLength = nameMaxLength}) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    if (value.trim().length > maxLength) {
      return 'Máximo $maxLength caracteres';
    }
    return null;
  }

  static String? categoryName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresá un nombre';
    }
    final length = value.trim().length;
    if (length < 2) {
      return 'Mínimo 2 caracteres';
    }
    if (length > categoryNameMaxLength) {
      return 'Máximo $categoryNameMaxLength caracteres';
    }
    return null;
  }

  static String? householdName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresá un nombre';
    }
    final length = value.trim().length;
    if (length < 2) {
      return 'Mínimo 2 caracteres';
    }
    if (length > householdNameMaxLength) {
      return 'Máximo $householdNameMaxLength caracteres';
    }
    return null;
  }

  static String? inviteCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresá el código';
    }
    if (!_inviteCodeRegExp.hasMatch(value.trim())) {
      return 'El código debe tener 6 caracteres alfanuméricos';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresá tu correo';
    }
    if (!_emailRegExp.hasMatch(value.trim())) {
      return 'Ingresá un correo válido';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresá tu contraseña';
    }
    if (value.length < passwordMinLength) {
      return 'Mínimo $passwordMinLength caracteres';
    }
    if (!_uppercaseRegExp.hasMatch(value)) {
      return 'Debe incluir al menos una mayúscula';
    }
    if (!_digitRegExp.hasMatch(value)) {
      return 'Debe incluir al menos un número';
    }
    return null;
  }

  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresá tu contraseña';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Confirmá tu contraseña';
    }
    if (value != original) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }
}

/// Permite solo dígitos con un separador decimal (coma o punto),
/// hasta [decimalRange] decimales y [maxIntegerDigits] dígitos enteros.
class DecimalTextInputFormatter extends TextInputFormatter {
  const DecimalTextInputFormatter({
    this.decimalRange = 2,
    this.maxIntegerDigits = FormValidators.amountMaxIntegerDigits,
  });

  final int decimalRange;
  final int maxIntegerDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }
    final regex = RegExp(
      '^\\d{0,$maxIntegerDigits}([.,]\\d{0,$decimalRange})?\$',
    );
    return regex.hasMatch(text) ? newValue : oldValue;
  }
}

/// Formatea el input con separadores de miles según locale.
/// Idempotente: re-formatea el texto ya formateado sin colapsar el valor.
/// En es_AR el punto es separador de miles y la coma es decimal.
class CurrencyTextInputFormatter extends TextInputFormatter {
  CurrencyTextInputFormatter({
    this.locale = 'es_AR',
    this.decimalDigits = 2,
    this.maxIntegerDigits = FormValidators.amountMaxIntegerDigits,
  }) : _formatter = NumberFormat.decimalPattern(locale)
         ..maximumFractionDigits = 0;

  final String locale;
  final int decimalDigits;
  final int maxIntegerDigits;
  final NumberFormat _formatter;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Solo dígitos y comas; el punto es agrupación y siempre se descarta.
    final cleaned = newValue.text.replaceAll(RegExp(r'[^\d,]'), '');

    final commaIndex = cleaned.indexOf(',');
    final intPart = commaIndex == -1
        ? cleaned
        : cleaned.substring(0, commaIndex);
    final decPart = commaIndex == -1
        ? ''
        : cleaned.substring(commaIndex + 1).replaceAll(',', '');

    if (intPart.length > maxIntegerDigits || decPart.length > decimalDigits) {
      return oldValue;
    }

    final intValue = int.tryParse(intPart.isEmpty ? '0' : intPart) ?? 0;
    final grouped = _formatter.format(intValue);

    final hasComma = newValue.text.contains(',');
    final text = hasComma ? '$grouped,$decPart' : grouped;

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
