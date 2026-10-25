import 'dart:convert';

import '../../../core/database/app_database.dart';

class DataExportService {
  const DataExportService(this._database);

  final AppDatabase _database;

  Future<String> exportProfileData({required String profileId}) async {
    final profile = await (_database.select(
      _database.profiles,
    )..where((row) => row.id.equals(profileId))).getSingleOrNull();

    if (profile == null) {
      throw StateError('Profile $profileId does not exist.');
    }

    final categories = await (_database.select(
      _database.categories,
    )..where((row) => row.profileId.equals(profileId))).get();

    // Intentionally query the table directly instead of using the
    // normal ledger repository because an export must also contain
    // soft-deleted transactions.
    final transactions = await (_database.select(
      _database.transactions,
    )..where((row) => row.profileId.equals(profileId))).get();

    final transactionIds = transactions.map((row) => row.id).toList();

    final regretCheckins = transactionIds.isEmpty
        ? <RegretCheckin>[]
        : await (_database.select(
            _database.regretCheckins,
          )..where((row) => row.transactionId.isIn(transactionIds))).get();

    final export = <String, Object?>{
      'exportVersion': 1,
      'databaseSchemaVersion': _database.schemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),

      'profile': {
        'id': profile.id,
        'currencyCode': profile.currencyCode,
        'createdAt': _date(profile.createdAt),
        'updatedAt': _date(profile.updatedAt),
      },

      'categories': categories
          .map(
            (category) => {
              'id': category.id,
              'profileId': category.profileId,
              'name': category.name,
              'systemKey': category.systemKey,
              'isArchived': category.isArchived,
              'createdAt': _date(category.createdAt),
              'updatedAt': _date(category.updatedAt),
            },
          )
          .toList(),

      'transactions': transactions
          .map(
            (transaction) => {
              'id': transaction.id,
              'profileId': transaction.profileId,
              'categoryId': transaction.categoryId,
              'transactionType': transaction.transactionType.name,

              // Stored in cents because AfterLens V1 currently supports
              // two-decimal currencies only.
              'amountCents': transaction.amountCents,

              'description': transaction.description,
              'moodTag': transaction.moodTag?.name,
              'transactionDate': _date(transaction.transactionDate),
              'createdAt': _date(transaction.createdAt),
              'updatedAt': _date(transaction.updatedAt),
              'deletedAt': _nullableDate(transaction.deletedAt),
            },
          )
          .toList(),

      'regretCheckins': regretCheckins
          .map(
            (checkin) => {
              'id': checkin.id,
              'transactionId': checkin.transactionId,

              'dueAt': _date(checkin.dueAt),
              'promptedAt': _nullableDate(checkin.promptedAt),
              'answeredAt': _nullableDate(checkin.answeredAt),
              'response': checkin.response?.name,

              // Immutable historical reflection snapshot.
              'snapshot': checkin.snapshotAmountCents == null
                  ? null
                  : {
                      'amountCents': checkin.snapshotAmountCents,
                      'categoryId': checkin.snapshotCategoryId,
                      'categoryName': checkin.snapshotCategoryName,
                      'moodTag': checkin.snapshotMoodTag?.name,
                      'description': checkin.snapshotDescription,
                      'transactionDate': _nullableDate(
                        checkin.snapshotTransactionDate,
                      ),
                    },

              'createdAt': _date(checkin.createdAt),
              'updatedAt': _date(checkin.updatedAt),
            },
          )
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(export);
  }

  String _date(DateTime value) {
    return value.toUtc().toIso8601String();
  }

  String? _nullableDate(DateTime? value) {
    return value?.toUtc().toIso8601String();
  }
}
