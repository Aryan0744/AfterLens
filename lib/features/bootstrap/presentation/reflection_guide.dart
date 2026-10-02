import 'package:flutter/material.dart';

import '../../transactions/domain/transaction_types.dart';

class ReflectionGuide extends StatelessWidget {
  const ReflectionGuide({
    required this.currencyCode,
    this.showMoods = true,
    super.key,
  });
  final String currencyCode;
  final bool showMoods;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Record → return → reflect',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      const Text(
        'Record a purchase and choose the mood that best describes why you bought it. There is no right answer.',
      ),
      const SizedBox(height: 12),
      Text(
        'Want and Impulse purchases above $currencyCode 15.00 become ready for reflection two days after the purchase date. Other moods are still recorded but do not schedule reflections yet.',
      ),
      const SizedBox(height: 12),
      const Text(
        'Return to Home and answer with one tap: Worth it, I regret it, or Unsure. Unanswered reflections keep waiting, and you can answer more than one in a day.',
      ),
      const SizedBox(height: 12),
      const Text(
        'Your saved answers build Reflection History and Insights. Editing or removing a transaction later preserves completed reflections. Unsure is useful too; it is never counted as Regret.',
      ),
      if (showMoods) ...[
        const SizedBox(height: 24),
        Text('Choosing a mood', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Choose the one that fits best, even when more than one could apply.',
        ),
        for (final mood in MoodTag.values)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('${mood.label}: ${mood.explanation}'),
          ),
      ],
      const SizedBox(height: 24),
      Text('On this device', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      const Text(
        'This version stores your purchases and reflections locally. It has no cloud sync, bank connection, or AI processing. Device backups may include app data depending on your device settings.',
      ),
    ],
  );
}
