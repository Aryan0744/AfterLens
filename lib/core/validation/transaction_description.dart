import 'package:characters/characters.dart';

const int maxTransactionDescriptionLength = 200;

String? normalizeTransactionDescription(String? description) {
  if (description == null) {
    return null;
  }

  final value = description.trim();

  if (value.isEmpty) {
    return null;
  }

  if (value.characters.length > maxTransactionDescriptionLength) {
    throw ArgumentError.value(
      description,
      'description',
      'Description cannot exceed '
          '$maxTransactionDescriptionLength characters.',
    );
  }

  return value;
}

String? validateTransactionDescription(String? description) {
  if (description == null || description.trim().isEmpty) {
    return null;
  }

  if (description.trim().characters.length > maxTransactionDescriptionLength) {
    return 'Description cannot exceed '
        '$maxTransactionDescriptionLength characters.';
  }

  return null;
}
