// Basic smoke test for AnaApp
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ana_app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AnaApp()));
    await tester.pump();
    // App should render without crashing
    expect(find.byType(AnaApp), findsOneWidget);
  });
}
