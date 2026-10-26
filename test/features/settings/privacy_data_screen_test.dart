import 'package:afterlens/features/settings/presentation/privacy_data_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows privacy and data information', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyDataScreen()));

    expect(find.text('Privacy & data'), findsOneWidget);

    expect(find.text('Stored locally'), findsOneWidget);

    expect(find.text('No cloud sync'), findsOneWidget);

    expect(find.text('No analytics tracking'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Exporting your data'), 300);

    expect(find.text('Exporting your data'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Deleting your data'), 300);

    expect(find.text('Deleting your data'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('does not currently claim encrypted local storage'),
      300,
    );

    expect(
      find.textContaining('does not currently claim encrypted local storage'),
      findsOneWidget,
    );
  });
}
