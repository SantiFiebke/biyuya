import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('haptic completes', (tester) async {
    var done = false;
    await HapticFeedback.selectionClick().then((_) => done = true);
    debugPrint('haptic done: $done');
    expect(done, isTrue);
  });
}
