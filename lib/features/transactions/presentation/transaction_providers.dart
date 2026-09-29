import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../domain/app_transaction.dart';

final transactionsProvider =
    StreamProvider.family<List<AppTransaction>, String>((ref, profileId) {
      final repository = ref.watch(transactionRepositoryProvider);

      return repository.watchTransactions(profileId: profileId);
    });
