import 'package:afterlens/core/database/database_provider.dart';
import 'package:afterlens/features/categories/data/drift_category_repository.dart';
import 'package:afterlens/features/categories/presentation/category_management_screen.dart';
import 'package:afterlens/features/mood_engine/domain/regret_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mood_engine/regret_test_fixture.dart';

void main() {
  late RegretTestFixture f;
  late DriftCategoryRepository categories;
  setUp(() async {
    f = RegretTestFixture();
    await f.initialize();
    categories = DriftCategoryRepository(f.database);
  });
  tearDown(() => f.database.close());

  test(
    'rename protects ownership, active uniqueness and saved reflection names',
    () async {
      await f.expense();
      final prompt = (await f.select()).prompt!;
      await f.service.answerPrompt(
        profileId: f.profile.id,
        checkinId: prompt.checkin.id,
        response: RegretResponse.worthIt,
        asOf: f.now,
      );
      await categories.renameCategory(
        profileId: f.profile.id,
        categoryId: f.categoryId,
        name: '  Purchases  ',
      );
      expect(
        (await categories.getCategoryById(categoryId: f.categoryId))!.name,
        'Purchases',
      );
      expect(
        (await f.checkins.getCheckinById(checkinId: prompt.checkin.id))!
            .snapshot!
            .categoryName,
        'Shopping',
      );
      await expectLater(
        categories.renameCategory(
          profileId: 'wrong-profile',
          categoryId: f.categoryId,
          name: 'Changed',
        ),
        throwsStateError,
      );
      final dining = await categories.createCustomCategory(
        profileId: f.profile.id,
        name: 'Dining',
      );
      await expectLater(
        categories.renameCategory(
          profileId: f.profile.id,
          categoryId: dining.id,
          name: 'purchases',
        ),
        throwsStateError,
      );
      await expectLater(
        categories.renameCategory(
          profileId: f.profile.id,
          categoryId: dining.id,
          name: ' ',
        ),
        throwsArgumentError,
      );
      await categories.archiveCategory(
        profileId: f.profile.id,
        categoryId: dining.id,
      );
      await categories.renameCategory(
        profileId: f.profile.id,
        categoryId: dining.id,
        name: 'Purchases',
      );
      await expectLater(
        categories.restoreCategory(
          profileId: f.profile.id,
          categoryId: dining.id,
        ),
        throwsStateError,
      );
    },
  );

  test(
    'concurrent create calls cannot introduce duplicate active names',
    () async {
      final results = await Future.wait([
        for (final name in ['Travel', ' travel '])
          categories
              .createCustomCategory(profileId: f.profile.id, name: name)
              .then<Object>((value) => value, onError: (Object error) => error),
      ]);
      expect(results.whereType<StateError>(), hasLength(1));
      expect(
        (await categories.getActiveCategories(profileId: f.profile.id))
            .where((c) => c.name.toLowerCase() == 'travel'),
        hasLength(1),
      );
    },
  );

  test('system category keeps its key and archive through bootstrap', () async {
    final system = await categories.ensureSystemCategory(
      profileId: f.profile.id,
      systemKey: 'dining',
      name: 'Dining',
    );
    await categories.renameCategory(
      profileId: f.profile.id,
      categoryId: system.id,
      name: 'Meals',
    );
    await categories.archiveCategory(
      profileId: f.profile.id,
      categoryId: system.id,
    );
    final again = await categories.ensureSystemCategory(
      profileId: f.profile.id,
      systemKey: 'dining',
      name: 'Dining',
    );
    expect(again.name, 'Meals');
    expect(again.isArchived, isTrue);
    expect(again.systemKey, 'dining');
  });

  testWidgets(
    'create, rename, archive and restore from the management screen',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(f.database)],
          child: MaterialApp(
            home: CategoryManagementScreen(profile: f.profile),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('category_create')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('category_name')), 'Travel');
      await tester.tap(find.byKey(const Key('category_name_save')));
      await tester.pumpAndSettle();
      final category = (await categories.getActiveCategories(
        profileId: f.profile.id,
      )).firstWhere((c) => c.name == 'Travel');
      Future<void> action(String text) async {
        final menu = find.byKey(ValueKey('category_actions_${category.id}'));
        await tester.ensureVisible(menu);
        await tester.tap(menu);
        await tester.pumpAndSettle();
        await tester.tap(find.text(text).last);
        await tester.pumpAndSettle();
      }

      await action('Rename');
      await tester.enterText(find.byKey(const Key('category_name')), 'Trips');
      await tester.tap(find.byKey(const Key('category_name_save')));
      await tester.pumpAndSettle();
      expect(find.text('Trips'), findsOneWidget);
      await action('Archive');
      expect(
        (await categories.getCategoryById(categoryId: category.id))!.isArchived,
        isTrue,
      );
      await action('Restore');
      expect(
        (await categories.getCategoryById(categoryId: category.id))!.isArchived,
        isFalse,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}
