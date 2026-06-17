import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mom_generator/main.dart';
import 'package:mom_generator/providers/meeting_provider.dart';

void main() {
  testWidgets('MoM Generator smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MeetingProvider(),
        child: const MomGeneratorApp(),
      ),
    );

    // Verify that the app title is present on the home screen
    expect(find.text('MoM Generator'), findsOneWidget);
  });
}
