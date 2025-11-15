import 'package:flutter_test/flutter_test.dart';
import 'package:haka_comic/main.dart';
import 'package:haka_comic/src/rust/frb_generated.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());
  testWidgets('Can call rust function', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.textContaining('Result: `Hello, Tom!`'), findsOneWidget);
  });
}
