class AppCategory {
  const AppCategory({
    required this.id,
    required this.profileId,
    required this.name,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.systemKey,
  });

  final String id;
  final String profileId;
  final String name;
  final String? systemKey;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isSystem => systemKey != null;
}
