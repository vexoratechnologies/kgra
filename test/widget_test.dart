import 'package:flutter_test/flutter_test.dart';
import 'package:kgra/app.dart';

void main() {
  testWidgets('App boots and renders splash screen placeholder', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const App());

    // Verify that our initial location loads the splash screen placeholder.
    expect(find.text('Splash Screen'), findsOneWidget);
  });
}
