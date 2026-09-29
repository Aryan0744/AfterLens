import 'dart:async';

import 'package:afterlens/core/database/database_provider.dart';
import 'package:afterlens/core/providers/repository_providers.dart';
import 'package:afterlens/core/theme/app_theme.dart';
import 'package:afterlens/features/home/presentation/home_screen.dart';
import 'package:afterlens/features/mood_engine/application/regret_prompt_result.dart';
import 'package:afterlens/features/mood_engine/application/regret_prompt_service.dart';
import 'package:afterlens/features/mood_engine/domain/regret_response.dart';
import 'package:afterlens/features/mood_engine/presentation/regret_checkin_screen.dart';
import 'package:afterlens/features/mood_engine/presentation/regret_prompt_controller.dart';
import 'package:afterlens/features/transactions/presentation/expense_entry_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'regret_test_fixture.dart';

void main() {
  late RegretTestFixture f;
  late DateTime now;
  setUp(() async {
    f = RegretTestFixture();
    await f.initialize();
    now = f.now;
  });
  tearDown(() => f.database.close());

  Future<void> pumpHome(
    WidgetTester tester, {
    _ControlledService? service,
  }) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(f.database),
          regretClockProvider.overrideWithValue(() => now),
          if (service != null)
            regretPromptServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: HomeScreen(profile: f.profile, categoryCount: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> disposeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openReflection(WidgetTester tester) async {
    await tapVisible(tester, find.byKey(const Key('regret_reflect_now')));
    expect(find.byType(RegretCheckinScreen), findsOneWidget);
  }

  for (final response in RegretResponse.values) {
    testWidgets(
      '${response.name} is saved and Home hides the card without another delivery',
      (tester) async {
        await f.scheduled();
        await f.scheduled();
        await pumpHome(tester);
        expect(find.byKey(const Key('regret_prompt_card')), findsOneWidget);
        ScaffoldMessenger.of(tester.element(find.byType(HomeScreen)))
            .showSnackBar(
              const SnackBar(
                content: Text('Expense saved: CAD 25.00'),
                duration: Duration(minutes: 1),
              ),
            );
        await tester.pumpAndSettle();
        await openReflection(tester);
        expect(find.text('Was this purchase worth it?'), findsOneWidget);
        expect(find.text('Headphones'), findsOneWidget);
        expect(find.text('CAD 25.00'), findsOneWidget);
        expect(find.text('Impulse • Sep 26, 2026'), findsOneWidget);
        await tapVisible(
          tester,
          find.byKey(ValueKey('regret_response_${response.name}')),
        );
        expect(find.byType(RegretCheckinScreen), findsNothing);
        expect(find.byKey(const Key('regret_prompt_card')), findsNothing);
        expect(find.text('Reflection saved.'), findsOneWidget);
        final deliveries = await f.checkins.getCheckinsPromptedOnDate(
          profileId: f.profile.id,
          date: now,
        );
        expect(deliveries, hasLength(1));
        expect(deliveries.single.response, response);
        expect(deliveries.single.answeredAt, now);
        expect(
          deliveries.single.updatedAt.isBefore(deliveries.single.createdAt),
          isFalse,
        );
        expect((await f.select()).status, RegretPromptStatus.dailyLimitReached);
        await disposeApp(tester);
      },
    );
  }

  testWidgets(
    'backing out and rebuilding Home preserves the unanswered prompt',
    (tester) async {
      final checkin = await f.scheduled();
      await pumpHome(tester);
      await openReflection(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await pumpHome(tester);
      expect(find.byKey(const Key('regret_prompt_card')), findsOneWidget);
      final stored = (await f.checkins.getCheckinById(checkinId: checkin.id))!;
      expect(stored.answeredAt, isNull);
      expect(stored.promptedAt, now);
      expect(stored.response, isNull);
      await disposeApp(tester);
    },
  );

  testWidgets('rapid taps submit once and disable all answers while saving', (
    tester,
  ) async {
    await f.scheduled();
    final service = _ControlledService(f)..answerGate = Completer<void>();
    await pumpHome(tester, service: service);
    await openReflection(tester);
    final answer = find.byKey(const Key('regret_response_worthIt'));
    await tester.tap(answer);
    await tester.tap(answer);
    await tester.pump();
    expect(service.saveCalls, 1);
    for (final response in RegretResponse.values) {
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(ValueKey('regret_response_${response.name}')),
            )
            .onPressed,
        isNull,
      );
    }
    service.answerGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(RegretCheckinScreen), findsNothing);
    expect(service.saveCalls, 1);
    await disposeApp(tester);
  });

  testWidgets('save failure stays on the screen and allows retry', (
    tester,
  ) async {
    final checkin = await f.scheduled();
    final service = _ControlledService(f)..failSaves = true;
    await pumpHome(tester, service: service);
    await openReflection(tester);
    await tapVisible(tester, find.byKey(const Key('regret_response_regret')));
    expect(find.byType(RegretCheckinScreen), findsOneWidget);
    expect(
      find.text('Could not save your reflection. Please try again.'),
      findsOneWidget,
    );
    expect(
      (await f.checkins.getCheckinById(checkinId: checkin.id))!.answeredAt,
      isNull,
    );
    service.failSaves = false;
    await tapVisible(tester, find.byKey(const Key('regret_response_unsure')));
    expect(find.byType(RegretCheckinScreen), findsNothing);
    expect(
      (await f.checkins.getCheckinById(checkinId: checkin.id))!.response,
      RegretResponse.unsure,
    );
    await disposeApp(tester);
  });

  testWidgets('load failure leaves Home and expense entry usable', (
    tester,
  ) async {
    final service = _ControlledService(f)..failLoads = true;
    await pumpHome(tester, service: service);
    expect(find.byKey(const Key('regret_prompt_card')), findsNothing);
    await tapVisible(tester, find.byKey(const Key('home_add_expense')));
    expect(find.byType(ExpenseEntryScreen), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets(
    'future purchase stays hidden until it becomes due while Home is open',
    (tester) async {
      await f.scheduled(dueAt: now.add(const Duration(seconds: 30)));
      await pumpHome(tester);
      expect(find.byKey(const Key('regret_prompt_card')), findsNothing);
      now = now.add(const Duration(minutes: 1));
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('regret_prompt_card')), findsOneWidget);
      await disposeApp(tester);
    },
  );

  testWidgets(
    'resuming on the next day refreshes the persistent daily allowance',
    (tester) async {
      await f.scheduled();
      await pumpHome(tester);
      await openReflection(tester);
      await tapVisible(tester, find.byKey(const Key('regret_response_unsure')));
      await f.scheduled();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('regret_prompt_card')), findsNothing);
      now = now.add(const Duration(days: 1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('regret_prompt_card')), findsOneWidget);
      await disposeApp(tester);
    },
  );

  testWidgets('past-dated expense entry returns to a ready reflection', (
    tester,
  ) async {
    // The date picker uses the device date; make this full entry flow independent
    // of the date on which the test runs.
    now = DateTime.now();
    await pumpHome(tester);
    await tapVisible(tester, find.byKey(const Key('home_add_expense')));
    await tester.enterText(find.byKey(const Key('expense_amount')), '25.00');
    await tapVisible(tester, find.byKey(const Key('expense_category')));
    await tester.tap(find.text('Shopping').last);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('expense_mood_impulse')));
    await tester.enterText(
      find.byKey(const Key('expense_description')),
      'Headphones',
    );
    tester.testTextInput.hide();
    await tapVisible(tester, find.byKey(const Key('expense_date')));
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    final past = now.subtract(const Duration(days: 3));
    await tester.enterText(
      find.byType(TextField).last,
      '${past.month}/${past.day}/${past.year}',
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('expense_save')));
    expect(find.byType(ExpenseEntryScreen), findsNothing);
    expect(find.byKey(const Key('regret_prompt_card')), findsOneWidget);
    final deliveries = await f.checkins.getCheckinsPromptedOnDate(
      profileId: f.profile.id,
      date: now,
    );
    expect(deliveries, hasLength(1));
    await openReflection(tester);
    await tapVisible(tester, find.byKey(const Key('regret_response_worthIt')));
    expect(find.byKey(const Key('regret_prompt_card')), findsNothing);
    await disposeApp(tester);
  });
}

class _ControlledService extends RegretPromptService {
  _ControlledService(RegretTestFixture fixture)
    : super(
        checkinRepository: fixture.checkins,
        transactionRepository: fixture.transactions,
        runInTransaction: fixture.database.transaction,
      );

  bool failLoads = false;
  bool failSaves = false;
  int saveCalls = 0;
  Completer<void>? answerGate;

  @override
  Future<RegretPromptResult> getPrompt({
    required String profileId,
    required DateTime asOf,
  }) {
    if (failLoads) throw StateError('Simulated load failure');
    return super.getPrompt(profileId: profileId, asOf: asOf);
  }

  @override
  Future<void> answerPrompt({
    required String profileId,
    required String checkinId,
    required RegretResponse response,
    required DateTime asOf,
  }) async {
    saveCalls++;
    await answerGate?.future;
    if (failSaves) throw StateError('Simulated save failure');
    await super.answerPrompt(
      profileId: profileId,
      checkinId: checkinId,
      response: response,
      asOf: asOf,
    );
  }
}
