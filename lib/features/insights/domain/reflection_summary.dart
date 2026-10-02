enum PatternStage {
  insufficient('Not enough data'),
  early('Early pattern'),
  established('Pattern');

  const PatternStage(this.label);
  final String label;

  static PatternStage forCount(int count) => count < 3
      ? insufficient
      : count < 6
      ? early
      : established;
}

/// Presentation thresholds describe sample size, not statistical confidence.
mixin ReflectionSummary {
  int get answeredCount;
  int get worthItCount;
  int get regretCount;
  int get unsureCount;

  int get decisiveCount => worthItCount + regretCount;
  double? get regretRate =>
      decisiveCount == 0 ? null : regretCount / decisiveCount;
  double? get worthItRate =>
      decisiveCount == 0 ? null : worthItCount / decisiveCount;
  double? get unsureRate =>
      answeredCount == 0 ? null : unsureCount / answeredCount;

  PatternStage get patternStage => PatternStage.forCount(decisiveCount);
  PatternStage get unsureStage => PatternStage.forCount(answeredCount);

  bool hasMinimumPatternSample({int minimumSampleSize = 3}) =>
      decisiveCount >= minimumSampleSize;

  // Require three Unsure answers as well as a majority of reviewed purchases.
  bool get hasUnsurePattern =>
      unsureCount >= 3 && unsureCount * 2 > answeredCount;

  String get patternDescription {
    if (hasUnsurePattern) {
      return '${unsureStage.label}: often unsure about value '
          '($unsureCount of $answeredCount reviewed).';
    }
    if (!hasMinimumPatternSample()) {
      return 'Not enough data: $decisiveCount of 3 decisive reflections.';
    }
    final tendency = regretCount > worthItCount
        ? 'more regret than worth it'
        : worthItCount > regretCount
        ? 'mostly worth it'
        : 'mixed outcomes';
    return '${patternStage.label}: $tendency.';
  }
}
