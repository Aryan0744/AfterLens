import 'dart:io';

import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/core/database/database_provider.dart';
import 'package:afterlens/features/home/presentation/home_screen.dart';
import 'package:afterlens/features/mood_engine/domain/regret_response.dart';
import 'package:afterlens/features/mood_engine/presentation/regret_checkin_screen.dart';
import 'package:afterlens/features/transactions/presentation/expense_entry_screen.dart';
import 'package:afterlens/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('past-dated expenses, reflection and persistent daily cap', (
    tester,
  ) async {
    // Exercise real on-device SQLite without changing the user's normal data.
    final directory = await (await getTemporaryDirectory()).createTemp(
      'regret-qa-',
    );
    final file = File('${directory.path}/afterlens.sqlite');
    var database = AppDatabase(NativeDatabase(file));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await database.close();
      await directory.delete(recursive: true);
    });

    Future<void> launch() async {
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [appDatabaseProvider.overrideWithValue(database)],
          child: const AfterLensApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapVisible(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> addExpense(String description) async {
      await tapVisible(find.byKey(const Key('home_add_expense')));
      await tester.enterText(find.byKey(const Key('expense_amount')), '25.00');
      await tapVisible(find.byKey(const Key('expense_category')));
      await tapVisible(find.text('Shopping').last);
      await tapVisible(find.byKey(const Key('expense_mood_impulse')));
      await tester.enterText(
        find.byKey(const Key('expense_description')),
        description,
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapVisible(find.byKey(const Key('expense_date')));
      await tapVisible(find.byIcon(Icons.edit_outlined));
      final past = DateTime.now().subtract(const Duration(days: 3));
      await tester.enterText(
        find.byType(TextField).last,
        '${past.month}/${past.day}/${past.year}',
      );
      await tapVisible(find.text('OK'));
      await tapVisible(find.byKey(const Key('expense_save')));
      expect(find.byType(ExpenseEntryScreen), findsNothing);
    }

    Future<void> homeTop() async {
      await tester.drag(find.byType(ListView).first, const Offset(0, 1200));
      await tester.pumpAndSettle();
    }

    await launch();
    await tester.enterText(find.byType(TextFormField), 'CAD');
    await tapVisible(find.text('Continue'));
    expect(find.byType(HomeScreen), findsOneWidget);

    await addExpense('Headphones');
    await homeTop();
    expect(find.byKey(const Key('regret_prompt_card')), findsOneWidget);
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    await binding.takeScreenshot('regret-home-ready');

    await tapVisible(find.byKey(const Key('regret_reflect_now')));
    expect(find.text('Was this purchase worth it?'), findsOneWidget);
    await binding.takeScreenshot('regret-reflection');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('regret_prompt_card')), findsOneWidget);

    await addExpense('Second purchase');
    // Scheduling every eligible purchase remains independent of delivery.
    var checkins = await database.select(database.regretCheckins).get();
    expect(checkins, hasLength(2));
    expect(checkins.where((item) => item.promptedAt != null), hasLength(1));
    expect(checkins.every((item) => item.answeredAt == null), isTrue);

    await homeTop();
    await tapVisible(find.byKey(const Key('regret_reflect_now')));
    await tapVisible(find.byKey(const Key('regret_response_worthIt')));
    expect(find.byType(RegretCheckinScreen), findsNothing);
    expect(find.byKey(const Key('regret_prompt_card')), findsNothing);
    expect(find.text('Reflection saved.'), findsOneWidget);
    checkins = await database.select(database.regretCheckins).get();
    final answered = checkins.singleWhere((item) => item.answeredAt != null);
    expect(answered.response, RegretResponse.worthIt);
    expect(checkins.where((item) => item.promptedAt != null), hasLength(1));
    await homeTop();
    await binding.takeScreenshot('regret-home-completed');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await database.close();
    database = AppDatabase(NativeDatabase(file));
    await launch();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byKey(const Key('regret_prompt_card')), findsNothing);
    expect(
      (await database.select(database.regretCheckins).get()).where(
        (item) => item.promptedAt != null,
      ),
      hasLength(1),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
