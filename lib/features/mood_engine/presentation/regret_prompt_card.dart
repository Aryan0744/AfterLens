import 'package:flutter/material.dart';

import '../application/regret_prompt_result.dart';
import 'regret_purchase_details.dart';

class RegretPromptCard extends StatelessWidget {
  const RegretPromptCard({
    required this.prompt,
    required this.currencyCode,
    required this.onReflect,
    super.key,
  });

  final RegretPrompt prompt;
  final String currencyCode;
  final VoidCallback onReflect;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('regret_prompt_card'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.chat_bubble_outline),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reflection ready',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Take a moment to reflect on this purchase.'),
            const SizedBox(height: 20),
            RegretPurchaseDetails(
              transaction: prompt.transaction,
              currencyCode: currencyCode,
            ),
            const SizedBox(height: 20),
            const Text('Was it worth it?'),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('regret_reflect_now'),
              onPressed: onReflect,
              child: const Text('Reflect now'),
            ),
          ],
        ),
      ),
    );
  }
}
