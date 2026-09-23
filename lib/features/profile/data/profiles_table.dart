import 'package:drift/drift.dart';

class Profiles extends Table {
  /// Local unique identifier for the profile
  ///
  /// We will use UUID strings rather than auto-increment integers
  /// because the app will eventually support cloud synchronization.
  TextColumn get id => text()();

  /// ID of the authenticated cloud user
  ///
  /// This is the nullable because AfterLens will be able to create/use
  /// a local profile before authentication or cloud sync is configured.
  TextColumn get authUserId => text().nullable()();
  /// ISO 4217 currency code by this profile
  ///
  /// Examples:
  /// CAD
  /// INR
  /// USD
  TextColumn get currencyCode =>
      text().withLength(min: 3, max: 3)();
  /// When the profile was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  /// When the profile was last modified
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
