import 'package:afterlens/core/formatting/money_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseMoneyInputToCents', () {
    test('accepts valid amounts', () {
      expect(parseMoneyInputToCents('10'), 1000);
      expect(parseMoneyInputToCents('10.5'), 1050);
      expect(parseMoneyInputToCents('10.50'), 1050);
      expect(parseMoneyInputToCents('0.01'), 1);
      expect(parseMoneyInputToCents('15.00'), 1500);
      expect(parseMoneyInputToCents('15.01'), 1501);
      expect(parseMoneyInputToCents('999999999.99'), 99999999999);
    });

    test('rejects invalid amounts', () {
      expect(parseMoneyInputToCents(null), isNull);
      expect(parseMoneyInputToCents(''), isNull);
      expect(parseMoneyInputToCents('0'), isNull);
      expect(parseMoneyInputToCents('-5'), isNull);
      expect(parseMoneyInputToCents('.50'), isNull);
      expect(parseMoneyInputToCents('10.'), isNull);
      expect(parseMoneyInputToCents('1.234'), isNull);
      expect(parseMoneyInputToCents('1,5'), isNull);
      expect(parseMoneyInputToCents('1,000.00'), isNull);
      expect(parseMoneyInputToCents('\$10'), isNull);
      expect(parseMoneyInputToCents('9999999999.00'), isNull);
      expect(parseMoneyInputToCents('99999999999999999999'), isNull);
    });
  });
}
