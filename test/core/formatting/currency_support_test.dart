import 'package:afterlens/core/formatting/currency_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isSupportedCurrencyCode', () {
    test('accepts supported two-decimal ISO currencies', () {
      expect(isSupportedCurrencyCode('CAD'), isTrue);
      expect(isSupportedCurrencyCode('USD'), isTrue);
      expect(isSupportedCurrencyCode('INR'), isTrue);
      expect(isSupportedCurrencyCode('EUR'), isTrue);
    });

    test('normalizes lowercase currency codes', () {
      expect(isSupportedCurrencyCode('cad'), isTrue);
    });

    test('rejects currencies without two decimal digits', () {
      expect(isSupportedCurrencyCode('JPY'), isFalse);
      expect(isSupportedCurrencyCode('KWD'), isFalse);
    });

    test('rejects invalid currency codes', () {
      expect(isSupportedCurrencyCode(null), isFalse);
      expect(isSupportedCurrencyCode(''), isFalse);
      expect(isSupportedCurrencyCode('CA'), isFalse);
      expect(isSupportedCurrencyCode('ABC'), isFalse);
    });

    test('returns normalized ISO code', () {
      expect(normalizeSupportedCurrencyCode('cad'), 'CAD');
      expect(normalizeSupportedCurrencyCode(' usd '), 'USD');
    });

    test('rejects unknown three-letter codes', () {
      expect(normalizeSupportedCurrencyCode('ABC'), isNull);
    });
  });
}
