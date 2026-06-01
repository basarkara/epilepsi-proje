import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:epilepsi_proje/main.dart';

void main() {
  testWidgets('first launch shows role based setup', (
    WidgetTester tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    await tester.pumpWidget(const MyApp(enableEmergencyProtection: false));
    await tester.pumpAndSettle();

    expect(find.text('Epilepsi Takip'), findsOneWidget);
    expect(find.text('Rolünü seç'), findsOneWidget);
    expect(find.text('Başla'), findsOneWidget);
  });
}
