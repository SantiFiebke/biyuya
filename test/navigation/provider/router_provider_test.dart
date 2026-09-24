import 'package:biyuya/src/navigation/provider/router_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PendingDeepLink', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('starts null', () {
      expect(container.read(pendingDeepLinkProvider), isNull);
    });

    test('consume returns target once then clears it', () {
      final notifier = container.read(pendingDeepLinkProvider.notifier)
        ..target = '/expenses/new?categoryId=2';

      expect(
        container.read(pendingDeepLinkProvider),
        '/expenses/new?categoryId=2',
      );

      expect(notifier.consume(), '/expenses/new?categoryId=2');
      expect(container.read(pendingDeepLinkProvider), isNull);
      expect(notifier.consume(), isNull);
    });
  });
}
