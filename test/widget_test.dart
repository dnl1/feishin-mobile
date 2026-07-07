import 'package:feishin_mobile/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FeishinApp renders the placeholder home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FeishinApp()));

    expect(find.text('Feishin'), findsOneWidget);
  });
}
