import 'package:flymap/rating/rate_prompt_repository.dart';
import 'package:flymap/rating/rate_prompt_trigger.dart';

abstract interface class RatePromptPolicyService {
  Future<bool> registerTriggerAndShouldShow(RatePromptTrigger trigger);

  Future<void> recordAccepted();

  Future<void> recordDeclined();
}

class DefaultRatePromptPolicyService implements RatePromptPolicyService {
  DefaultRatePromptPolicyService({
    required RatePromptRepository repository,
    DateTime Function()? nowProvider,
    Duration declineSnooze = const Duration(days: 30),
  }) : _repository = repository,
       _nowProvider = nowProvider ?? DateTime.now,
       _declineSnooze = declineSnooze;

  static const _minTriggerCountToPrompt = 2;

  final RatePromptRepository _repository;
  final DateTime Function() _nowProvider;
  final Duration _declineSnooze;

  @override
  Future<bool> registerTriggerAndShouldShow(RatePromptTrigger trigger) async {
    final nextTriggerCount = await _incrementTriggerCount(trigger);
    if (nextTriggerCount < _minTriggerCountToPrompt) return false;

    if (await _repository.isCompleted()) {
      return false;
    }

    final snoozedUntil = await _repository.getSnoozedUntil();
    if (snoozedUntil == null) return true;

    final now = _nowProvider().toUtc();
    return !now.isBefore(snoozedUntil.toUtc());
  }

  @override
  Future<void> recordAccepted() async {
    await _repository.setCompleted(true);
    await _repository.setSnoozedUntil(null);
  }

  @override
  Future<void> recordDeclined() async {
    final now = _nowProvider().toUtc();
    await _repository.setSnoozedUntil(now.add(_declineSnooze));
  }

  Future<int> _incrementTriggerCount(RatePromptTrigger trigger) async {
    final current = await _repository.getTriggerCount(trigger);
    final next = current + 1;
    await _repository.setTriggerCount(trigger, next);
    return next;
  }
}
