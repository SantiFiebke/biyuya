import 'package:biyuya/src/features/settings/data/models/user_settings_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserSettingsModel', () {
    test('fromJson maps debt_settlement_enabled=false to enabled false', () {
      final model = UserSettingsModel.fromJson(const {
        'debt_settlement_enabled': false,
      });

      expect(model.debtSettlementEnabled, isFalse);
    });

    test('toJson roundtrip preserves value', () {
      const model = UserSettingsModel(debtSettlementEnabled: false);

      final json = model.toJson();
      expect(json, {'debt_settlement_enabled': false});

      final restored = UserSettingsModel.fromJson(json);
      expect(restored.debtSettlementEnabled, isFalse);
    });

    test('missing key defaults to enabled true', () {
      final model = UserSettingsModel.fromJson(const {});

      expect(model.debtSettlementEnabled, isTrue);
    });

    test('defaults() enables debt settlement', () {
      expect(UserSettingsModel.defaults().debtSettlementEnabled, isTrue);
    });

    test('copyWith changes value and keeps it without argument', () {
      const model = UserSettingsModel();

      expect(
        model.copyWith(debtSettlementEnabled: false).debtSettlementEnabled,
        isFalse,
      );
      expect(model.copyWith().debtSettlementEnabled, isTrue);
    });
  });
}
