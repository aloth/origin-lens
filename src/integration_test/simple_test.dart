import 'package:flutter_test/flutter_test.dart';
import 'package:origin_lens/main.dart';
import 'package:origin_lens/src/rust/frb_generated.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());
  testWidgets('Can call rust function', (WidgetTester tester) async {
    await tester.pumpWidget(const OriginLensApp());
    await tester.pumpAndSettle();
    // Basic test that app loads
    expect(find.text('Origin Lens'), findsWidgets);
  });
}
