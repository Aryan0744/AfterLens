import 'package:afterlens/core/database/app_database.dart';
import 'package:afterlens/features/data_erasure/application/data_erasure_service.dart';
import 'package:afterlens/features/mood_engine/domain/regret_response.dart';
import 'package:afterlens/features/transactions/domain/transaction_types.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DataErasureService service;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());

    service = DataErasureService(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('permanently erases all local AfterLens data', () async {
    final now = DateTime.utc(2026, 10, 26, 12);

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
            id: 'category-active',
            profileId: 'profile-1',
            name: 'Shopping',
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    await database
        .into(database.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'category-archived',
            profileId: 'profile-1',
            name: 'Old category',
            isArchived: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    // Active transaction with a pending reflection.
    await database
        .into(database.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: 'transaction-active',
            profileId: const Value('profile-1'),
            categoryId: const Value('category-active'),
            transactionType: const Value(TransactionType.expense),
            amountCents: 3000,
            description: const Value('Headphones'),
            moodTag: const Value(MoodTag.want),
            transactionDate: now,
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    await database
        .into(database.regretCheckins)
        .insert(
          RegretCheckinsCompanion.insert(
            id: 'checkin-pending',
            transactionId: 'transaction-active',
            dueAt: now.add(const Duration(days: 2)),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    // Soft-deleted transaction with a completed immutable reflection.
    await database
        .into(database.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: 'transaction-deleted',
            profileId: const Value('profile-1'),
            categoryId: const Value('category-archived'),
            transactionType: const Value(TransactionType.expense),
            amountCents: 8000,
            description: const Value('Shoes'),
            moodTag: const Value(MoodTag.impulse),
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
            id: 'checkin-completed',
            transactionId: 'transaction-deleted',
            dueAt: now.add(const Duration(days: 2)),
            promptedAt: Value(now.add(const Duration(days: 2))),
            answeredAt: Value(now.add(const Duration(days: 2))),
            response: const Value(RegretResponse.regret),
            snapshotAmountCents: const Value(8000),
            snapshotCategoryId: const Value('category-archived'),
            snapshotCategoryName: const Value('Old category'),
            snapshotMoodTag: const Value(MoodTag.impulse),
            snapshotDescription: const Value('Shoes'),
            snapshotTransactionDate: Value(now),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    expect(await database.select(database.profiles).get(), hasLength(1));

    expect(await database.select(database.categories).get(), hasLength(2));

    expect(await database.select(database.transactions).get(), hasLength(2));

    expect(await database.select(database.regretCheckins).get(), hasLength(2));

    await service.eraseAllLocalData();

    expect(await database.select(database.regretCheckins).get(), isEmpty);

    expect(await database.select(database.transactions).get(), isEmpty);

    expect(await database.select(database.categories).get(), isEmpty);

    expect(await database.select(database.profiles).get(), isEmpty);
  });

  test('erasing an empty database is safe', () async {
    await service.eraseAllLocalData();

    expect(await database.select(database.regretCheckins).get(), isEmpty);

    expect(await database.select(database.transactions).get(), isEmpty);

    expect(await database.select(database.categories).get(), isEmpty);

    expect(await database.select(database.profiles).get(), isEmpty);
  });
}
