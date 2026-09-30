import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/core/database/database_provider.dart';
import 'package:afterlens/features/home/presentation/home_screen.dart';
import 'package:afterlens/features/insights/presentation/insights_screen.dart';
import 'package:afterlens/features/profile/data/drift_profile_repository.dart';
import 'package:afterlens/features/profile/domain/app_profile.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftProfileRepository profileRepository;
  late AppProfile profile;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());

    profileRepository = DriftProfileRepository(database);

    profile = await profileRepository.createLocalProfile(currencyCode: 'CAD');
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> disposeTestApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());

    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('View Insights opens InsightsScreen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          home: HomeScreen(profile: profile, categoryCount: 0),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final insightsButton = find.byKey(const Key('home_view_insights'));

    expect(insightsButton, findsOneWidget);

    await tester.tap(insightsButton);

    await tester.pumpAndSettle();

    expect(find.byType(InsightsScreen), findsOneWidget);

    expect(find.text('Insights'), findsOneWidget);

    expect(find.text('Your insights will grow as you reflect'), findsOneWidget);

    await disposeTestApp(tester);
  });
}
