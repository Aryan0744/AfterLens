const int maxTransactionWholeUnits = 999999999;

const int maxTransactionAmountCents = (maxTransactionWholeUnits * 100) + 99;

int? parseMoneyInputToCents(String? input) {
  if (input == null) {
    return null;
  }

  final value = input.trim();

  final match = RegExp(r'^(\d{1,9})(?:\.(\d{1,2}))?$').firstMatch(value);

  if (match == null) {
    return null;
  }

  final wholeUnits = int.tryParse(match.group(1)!);

  if (wholeUnits == null) {
    return null;
  }

  final decimalPart = match.group(2);

  final fractionalUnits = decimalPart == null
      ? 0
      : decimalPart.length == 1
      ? int.tryParse(decimalPart)! * 10
      : int.tryParse(decimalPart)!;

  final cents = (wholeUnits * 100) + fractionalUnits;

  if (cents <= 0 || cents > maxTransactionAmountCents) {
    return null;
  }

  return cents;
}

String? validateMoneyInput(String? input) {
  if (parseMoneyInputToCents(input) == null) {
    return 'Enter an amount between 0.01 and 999,999,999.99.';
  }

  return null;
}

String formatCentsForInput(int cents) {
  final wholeUnits = cents ~/ 100;
  final remainder = cents % 100;

  return '$wholeUnits.${remainder.toString().padLeft(2, '0')}';
}
