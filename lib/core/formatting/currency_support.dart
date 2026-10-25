import 'package:money2/money2.dart';

Currency? findSupportedCurrency(String? currencyCode) {
  if (currencyCode == null) {
    return null;
  }

  final code = currencyCode.trim().toUpperCase();

  if (code.length != 3) {
    return null;
  }

  final currency = Currencies().find(code);

  if (currency == null) {
    return null;
  }

  if (!currency.isIso || currency.isDeprecated) {
    return null;
  }

  // AfterLens V1 stores monetary values as cents.
  // Until the database moves to generic minor units,
  // only currencies with exactly two decimal digits are safe.
  if (currency.decimalDigits != 2) {
    return null;
  }

  return currency;
}

String? normalizeSupportedCurrencyCode(String? currencyCode) {
  return findSupportedCurrency(currencyCode)?.isoCode;
}

bool isSupportedCurrencyCode(String? currencyCode) {
  return normalizeSupportedCurrencyCode(currencyCode) != null;
}
