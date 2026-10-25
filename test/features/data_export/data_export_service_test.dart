import 'dart:convert';

import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/features/data_export/application/data_export_service.dart';
import 'package:afterlens/features/mood_engine/domain/regret_response.dart';
import 'package:afterlens/features/transactions/domain/transaction_types.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DataExportService service;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());

    service = DataExportService(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'exports profile, categories, transactions and reflection snapshots',
    () async {
      final now = DateTime.utc(2026, 10, 25, 12);

      await database
          .into(database.profiles)
          .insert(
            ProfilesCompanion.insert(
              id: 'profile-1',
              currencyCode: 'CAD',
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      await database
          .into(database.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'category-1',
              profileId: 'profile-1',
              name: 'Shopping',
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      await database
          .into(database.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: 'transaction-1',
              profileId: const Value('profile-1'),
              categoryId: const Value('category-1'),
              amountCents: 8000,
              description: const Value('Shoes'),
              moodTag: const Value(MoodTag.want),
              transactionDate: now,
              createdAt: Value(now),
              updatedAt: Value(now),
              deletedAt: Value(now.add(const Duration(days: 5))),
            ),
          );

      await database
          .into(database.regretCheckins)
          .insert(
            RegretCheckinsCompanion.insert(
              id: 'checkin-1',
              transactionId: 'transaction-1',
              dueAt: now.add(const Duration(days: 2)),
              promptedAt: Value(now.add(const Duration(days: 2))),
              answeredAt: Value(now.add(const Duration(days: 2))),
              response: const Value(RegretResponse.regret),
              snapshotAmountCents: const Value(8000),
              snapshotCategoryId: const Value('category-1'),
              snapshotCategoryName: const Value('Shopping'),
              snapshotMoodTag: const Value(MoodTag.want),
              snapshotDescription: const Value('Shoes'),
              snapshotTransactionDate: Value(now),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      final jsonString = await service.exportProfileData(
        profileId: 'profile-1',
      );

      final export = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(export['exportVersion'], 1);

      expect(export['databaseSchemaVersion'], 8);

      final profile = export['profile'] as Map<String, dynamic>;

      expect(profile['currencyCode'], 'CAD');

      expect(profile.containsKey('authUserId'), isFalse);

      final categories = export['categories'] as List<dynamic>;

      expect(categories.length, 1);

      final transactions = export['transactions'] as List<dynamic>;

      expect(transactions.length, 1);

      final transaction = transactions.single as Map<String, dynamic>;

      expect(transaction['amountCents'], 8000);

      expect(transaction['deletedAt'], isNotNull);

      final checkins = export['regretCheckins'] as List<dynamic>;

      expect(checkins.length, 1);

      final checkin = checkins.single as Map<String, dynamic>;

      expect(checkin['response'], 'regret');

      final snapshot = checkin['snapshot'] as Map<String, dynamic>;

      expect(snapshot['amountCents'], 8000);

      expect(snapshot['categoryName'], 'Shopping');

      expect(snapshot['moodTag'], 'want');
    },
  );

  test('throws when profile does not exist', () async {
    expect(
      () => service.exportProfileData(profileId: 'missing-profile'),
      throwsA(isA<StateError>()),
    );
  });
}
