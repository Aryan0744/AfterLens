import 'package:afterlens/core/formatting/money_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatMoneyCents', () {
    test('formats minor amounts correctly', () {
      expect(formatMoneyCents(1, currencyCode: 'CAD'), '0.01');

      expect(formatMoneyCents(10, currencyCode: 'CAD'), '0.10');

      expect(formatMoneyCents(1050, currencyCode: 'CAD'), '10.50');
    });

    test('groups large values', () {
      expect(formatMoneyCents(123456, currencyCode: 'CAD'), '1,234.56');

      expect(formatMoneyCents(123456789, currencyCode: 'CAD'), '1,234,567.89');
    });

    test('formats maximum transaction amount', () {
      expect(
        formatMoneyCents(99999999999, currencyCode: 'CAD'),
        '999,999,999.99',
      );
    });

    test('formats zero', () {
      expect(formatMoneyCents(0, currencyCode: 'CAD'), '0.00');
    });

    test('formats negative values', () {
      expect(formatMoneyCents(-123456, currencyCode: 'CAD'), '-1,234.56');
    });

    test('accepts different supported currencies', () {
      expect(formatMoneyCents(1050, currencyCode: 'USD'), '10.50');

      expect(formatMoneyCents(1050, currencyCode: 'INR'), '10.50');
    });

    test('rejects unsupported currencies', () {
      expect(
        () => formatMoneyCents(1050, currencyCode: 'JPY'),
        throwsArgumentError,
      );
    });
  });
}
