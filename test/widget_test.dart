// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:gps_tracker_app/main.dart';
import 'package:provider/provider.dart';
import 'package:gps_tracker_app/providers/theme_provider.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    // Build our app with Provider and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify the app builds and a root widget is present.
    expect(find.byType(MyApp), findsOneWidget);
  });
}
