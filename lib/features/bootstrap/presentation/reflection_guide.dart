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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Record → Reflect → Learn',
          style: Theme.of(context).textTheme.titleLarge,
        ),

        const SizedBox(height: 16),

        _GuideStep(
          number: '1',
          title: 'Record',
          description: 'Add a purchase and choose the mood that best describes why you made it.',
        ),

        const SizedBox(height: 14),

        _GuideStep(
          number: '2',
          title: 'Reflect',
          description:
              'Want and Impulse purchases above '
              '$currencyCode 15.00 become ready for reflection '
              'two days after the purchase date.',
        ),

        const SizedBox(height: 14),

        const _GuideStep(
          number: '3',
          title: 'Learn',
          description:
              'Answer Worth it, I regret it, or Unsure. '
              'Your completed reflections build your '
              'Reflection History and Insights.',
        ),

        if (showMoods) ...[
          const SizedBox(height: 28),

          Text(
            'Choose what the purchase felt like',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 8),

          Text(
            'Choose the option that best describes why you made the purchase. '
            'There is no right or wrong answer.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 8),

          for (final mood in MoodTag.values)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _MoodExplanation(
                label: mood.label,
                explanation: mood.explanation,
              ),
            ),
        ],

        const SizedBox(height: 28),

        Text(
          'How reflections work',
          style: Theme.of(context).textTheme.titleLarge,
        ),

        const SizedBox(height: 8),

        const Text(
          'Unanswered reflections stay available until you answer them. '
          'You can complete more than one reflection in a day.',
        ),

        const SizedBox(height: 12),

        const Text(
          'Completed reflections are preserved in your history even if '
          'you later edit or remove the original transaction.',
        ),

        const SizedBox(height: 12),

        const Text(
          'Unsure is a valid response and is tracked separately from Regret.',
        ),

        const SizedBox(height: 28),

        Text('On this device', style: Theme.of(context).textTheme.titleLarge),

        const SizedBox(height: 8),

        const Text(
          'This version stores purchases and reflections locally on this '
          'device. It does not currently use cloud sync, bank connections, '
          'or AI processing.',
        ),
      ],
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 16, child: Text(number)),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),

              const SizedBox(height: 4),

              Text(description, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoodExplanation extends StatelessWidget {
  const _MoodExplanation({required this.label, required this.explanation});

  final String label;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.circle,
          size: 8,
          color: Theme.of(context).colorScheme.primary,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: explanation),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
