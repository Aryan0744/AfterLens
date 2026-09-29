import 'package:flutter/material.dart';

import '../../transactions/domain/app_transaction.dart';
import '../../transactions/domain/transaction_types.dart';

class RegretPurchaseDetails extends StatelessWidget {
  const RegretPurchaseDetails({
    required this.transaction,
    required this.currencyCode,
    super.key,
  });

  final AppTransaction transaction;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final description = transaction.description?.trim();
    final amount = transaction.amountCents;
    final money =
        '${amount ~/ 100}.${(amount % 100).toString().padLeft(2, '0')}';
    final mood = switch (transaction.moodTag) {
      MoodTag.want => 'Want',
      MoodTag.impulse => 'Impulse',
      MoodTag.need => 'Need',
      MoodTag.social => 'Social',
      MoodTag.subscription => 'Subscription',
      MoodTag.emergency => 'Emergency',
      null => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description == null || description.isEmpty ? 'Purchase' : description,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          '$currencyCode $money',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          [
            ?mood,
            MaterialLocalizations.of(context)
                .formatShortDate(transaction.transactionDate.toLocal()),
          ].join(' • '),
        ),
      ],
    );
  }
}
