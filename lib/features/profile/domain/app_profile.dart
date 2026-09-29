class AppProfile {
  const AppProfile({
    required this.id,
    required this.currencyCode,
    required this.createdAt,
    required this.updatedAt,
    this.authUserId,
  });

  final String id;
  final String? authUserId;
  final String currencyCode;
  final DateTime createdAt;
  final DateTime updatedAt;
}
