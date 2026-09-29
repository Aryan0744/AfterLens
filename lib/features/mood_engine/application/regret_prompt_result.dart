import '../../transactions/domain/app_transaction.dart';
import '../domain/app_regret_checkin.dart';

class RegretPrompt {
  const RegretPrompt({required this.checkin, required this.transaction});

  final AppRegretCheckin checkin;
  final AppTransaction transaction;
}

enum RegretPromptStatus { available, noDueCheckins, dailyLimitReached }

class RegretPromptResult {
  const RegretPromptResult.available(RegretPrompt this.prompt)
    : status = RegretPromptStatus.available;

  const RegretPromptResult.noDueCheckins()
    : status = RegretPromptStatus.noDueCheckins,
      prompt = null;

  const RegretPromptResult.dailyLimitReached()
    : status = RegretPromptStatus.dailyLimitReached,
      prompt = null;

  final RegretPromptStatus status;
  final RegretPrompt? prompt;
}
