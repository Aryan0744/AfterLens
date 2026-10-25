import 'package:afterlens/core/validation/transaction_description.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeTransactionDescription', () {
    test('returns null for null description', () {
      expect(normalizeTransactionDescription(null), isNull);
    });

    test('returns null for empty description', () {
      expect(normalizeTransactionDescription(''), isNull);
    });

    test('returns null for whitespace-only description', () {
      expect(normalizeTransactionDescription('   '), isNull);
    });

    test('trims description', () {
      expect(normalizeTransactionDescription('  Coffee  '), 'Coffee');
    });

    test('accepts exactly 200 normal characters', () {
      final description = 'a' * 200;

      expect(normalizeTransactionDescription(description), description);
    });

    test('rejects 201 normal characters', () {
      final description = 'a' * 201;

      expect(
        () => normalizeTransactionDescription(description),
        throwsArgumentError,
      );
    });

    test('accepts exactly 200 emoji', () {
      final description = List.filled(200, '😀').join();

      expect(normalizeTransactionDescription(description), description);
    });

    test('rejects 201 emoji', () {
      final description = List.filled(201, '😀').join();

      expect(
        () => normalizeTransactionDescription(description),
        throwsArgumentError,
      );
    });

    test('compound family emoji counts as one visible character', () {
      final description = List.filled(200, '👨‍👩‍👧‍👦').join();

      expect(normalizeTransactionDescription(description), description);
    });

    test('rejects 201 compound family emoji', () {
      final description = List.filled(201, '👨‍👩‍👧‍👦').join();

      expect(
        () => normalizeTransactionDescription(description),
        throwsArgumentError,
      );
    });
  });

  group('validateTransactionDescription', () {
    test('accepts valid description', () {
      expect(validateTransactionDescription('Coffee'), isNull);
    });

    test('accepts empty description', () {
      expect(validateTransactionDescription(''), isNull);
    });

    test('accepts exactly 200 visible characters', () {
      final description = List.filled(200, '😀').join();

      expect(validateTransactionDescription(description), isNull);
    });

    test('rejects more than 200 visible characters', () {
      final description = List.filled(201, '😀').join();

      expect(
        validateTransactionDescription(description),
        'Description cannot exceed 200 characters.',
      );
    });
  });
}
