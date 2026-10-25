import 'package:money2/money2.dart';

import 'currency_support.dart';

String formatMoneyCents(int cents, {required String currencyCode}) {
  final currency = findSupportedCurrency(currencyCode);

  if (currency == null) {
    throw ArgumentError.value(
      currencyCode,
      'currencyCode',
      'Unsupported currency.',
    );
  }

  final money = Money.fromIntWithCurrency(cents, currency);

  return money.format('#,##0.00;-#,##0.00');
}
