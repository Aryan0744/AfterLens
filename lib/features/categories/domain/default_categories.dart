class DefaultCategoryDefinition {
  const DefaultCategoryDefinition({
    required this.systemKey,
    required this.name,
  });

  final String systemKey;
  final String name;
}

const defaultCategories = <DefaultCategoryDefinition>[
  DefaultCategoryDefinition(systemKey: 'housing', name: 'Housing'),
  DefaultCategoryDefinition(systemKey: 'groceries', name: 'Groceries'),
  DefaultCategoryDefinition(systemKey: 'dining', name: 'Dining'),
  DefaultCategoryDefinition(
    systemKey: 'transportation',
    name: 'Transportation',
  ),
  DefaultCategoryDefinition(systemKey: 'shopping', name: 'Shopping'),
  DefaultCategoryDefinition(systemKey: 'entertainment', name: 'Entertainment'),
  DefaultCategoryDefinition(systemKey: 'health', name: 'Health'),
  DefaultCategoryDefinition(systemKey: 'bills', name: 'Bills'),
  DefaultCategoryDefinition(systemKey: 'subscriptions', name: 'Subscriptions'),
  DefaultCategoryDefinition(systemKey: 'travel', name: 'Travel'),
  DefaultCategoryDefinition(systemKey: 'other', name: 'Other'),
];
