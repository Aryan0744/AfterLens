import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../mood_engine/domain/app_regret_checkin.dart';
import '../domain/app_transaction.dart';

final transactionCheckinProvider = FutureProvider.autoDispose
    .family<AppRegretCheckin?, String>((ref, transactionId) {
      return ref
          .watch(regretCheckinRepositoryProvider)
          .getCheckinForTransaction(transactionId: transactionId);
    });

final transactionsProvider =
    StreamProvider.family<List<AppTransaction>, String>((ref, profileId) {
      final repository = ref.watch(transactionRepositoryProvider);

      return repository.watchTransactions(profileId: profileId);
    });
