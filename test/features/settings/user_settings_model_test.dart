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

    test('fromJson with missing columns defaults all flags to false', () {
      final model = UserSettingsModel.fromJson(const {});

      expect(model.debtSettlementEnabled, isFalse);
      expect(model.monthProjectionEnabled, isFalse);
      expect(model.debtSettlementExplainerSeen, isFalse);
      expect(model.monthProjectionExplainerSeen, isFalse);
      expect(model.firstStepsDismissed, isFalse);
    });

    test('fromJson maps first_steps_dismissed', () {
      final model = UserSettingsModel.fromJson(const {
        'first_steps_dismissed': true,
      });

      expect(model.firstStepsDismissed, isTrue);
    });

    test('fromJson maps explicit true values', () {
      final model = UserSettingsModel.fromJson(const {
        'debt_settlement_enabled': true,
        'month_projection_enabled': true,
        'debt_settlement_explainer_seen': true,
        'month_projection_explainer_seen': true,
      });

      expect(model.debtSettlementEnabled, isTrue);
      expect(model.monthProjectionEnabled, isTrue);
      expect(model.debtSettlementExplainerSeen, isTrue);
      expect(model.monthProjectionExplainerSeen, isTrue);
    });

    test('toJson round-trip includes all 5 keys', () {
      const model = UserSettingsModel(
        debtSettlementEnabled: true,
        monthProjectionEnabled: true,
        debtSettlementExplainerSeen: true,
        monthProjectionExplainerSeen: true,
        firstStepsDismissed: true,
      );

      final json = model.toJson();
      expect(json, {
        'debt_settlement_enabled': true,
        'month_projection_enabled': true,
        'debt_settlement_explainer_seen': true,
        'month_projection_explainer_seen': true,
        'first_steps_dismissed': true,
      });

      final restored = UserSettingsModel.fromJson(json);
      expect(restored, model);
    });

    test('toJson round-trip preserves all-false values', () {
      const model = UserSettingsModel();

      final json = model.toJson();
      expect(json, {
        'debt_settlement_enabled': false,
        'month_projection_enabled': false,
        'debt_settlement_explainer_seen': false,
        'month_projection_explainer_seen': false,
        'first_steps_dismissed': false,
      });

      final restored = UserSettingsModel.fromJson(json);
      expect(restored, model);
    });

    test('defaults() leaves every flag off', () {
      final defaults = UserSettingsModel.defaults();

      expect(defaults.debtSettlementEnabled, isFalse);
      expect(defaults.monthProjectionEnabled, isFalse);
      expect(defaults.debtSettlementExplainerSeen, isFalse);
      expect(defaults.monthProjectionExplainerSeen, isFalse);
      expect(defaults.firstStepsDismissed, isFalse);
    });

    test('copyWith changes value and keeps it without argument', () {
      const model = UserSettingsModel();

      expect(
        model.copyWith(debtSettlementEnabled: true).debtSettlementEnabled,
        isTrue,
      );
      expect(model.copyWith().debtSettlementEnabled, isFalse);
      expect(
        model.copyWith(monthProjectionEnabled: true).monthProjectionEnabled,
        isTrue,
      );
      expect(model.copyWith().monthProjectionEnabled, isFalse);
    });
  });
}
