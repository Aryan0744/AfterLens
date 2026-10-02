enum MoodTag { need, want, impulse, social, subscription, emergency }

extension MoodTagExplanation on MoodTag {
  String get label => switch (this) {
    MoodTag.need => 'Need',
    MoodTag.want => 'Want',
    MoodTag.impulse => 'Impulse',
    MoodTag.social => 'Social',
    MoodTag.subscription => 'Subscription',
    MoodTag.emergency => 'Emergency',
  };

  String get explanation => switch (this) {
    MoodTag.need => 'An essential purchase you needed to make.',
    MoodTag.want => 'Something you chose for enjoyment or convenience.',
    MoodTag.impulse => 'An unplanned purchase made in the moment.',
    MoodTag.social => 'Spending connected to time with other people.',
    MoodTag.subscription => 'A recurring service or membership.',
    MoodTag.emergency => 'An urgent, unexpected expense.',
  };
}

enum TransactionType { expense, income }
