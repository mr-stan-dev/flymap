import 'package:flymap/rating/rate_prompt_repository.dart';
import 'package:flymap/rating/rate_prompt_trigger.dart';

abstract interface class RatePromptPolicyService {
  Future<void> registerTrigger(RatePromptTrigger trigger);

  Future<RatePromptState?> getPromptState();

  Future<void> recordAccepted();

  Future<void> recordDeclined();

  Future<void> recordDismissed();

  Future<void> recordReviewRequested();

  Future<void> recordAppShared();
}

class RatePromptState {
  const RatePromptState({
    required this.requiresSentimentAnswer,
    required this.canRequestReview,
    required this.canShare,
  });

  final bool requiresSentimentAnswer;
  final bool canRequestReview;
  final bool canShare;
}

class DefaultRatePromptPolicyService implements RatePromptPolicyService {
  DefaultRatePromptPolicyService({
    required RatePromptRepository repository,
    DateTime Function()? nowProvider,
    Duration firstSeenMinAge = const Duration(days: 7),
    Duration actionSnooze = const Duration(days: 180),
    Duration dismissSnooze = const Duration(days: 14),
    Duration declineSnooze = const Duration(days: 90),
  }) : _repository = repository,
       _nowProvider = nowProvider ?? DateTime.now,
       _firstSeenMinAge = firstSeenMinAge,
       _actionSnooze = actionSnooze,
       _dismissSnooze = dismissSnooze,
       _declineSnooze = declineSnooze;

  static const _minDownloadSuccessCountToPrompt = 2;

  final RatePromptRepository _repository;
  final DateTime Function() _nowProvider;
  final Duration _firstSeenMinAge;
  final Duration _actionSnooze;
  final Duration _dismissSnooze;
  final Duration _declineSnooze;

  @override
  Future<void> registerTrigger(RatePromptTrigger trigger) async {
    await _incrementTriggerCount(trigger);
  }

  @override
  Future<RatePromptState?> getPromptState() async {
    final now = _nowProvider().toUtc();

    if (await _repository.isCompleted()) {
      // Migrate legacy "never ask again" users to the new long-snooze model.
      await _repository.setCompleted(false);
      await _repository.setSnoozedUntil(now.add(_actionSnooze));
      return null;
    }

    var firstSeenAt = await _repository.getFirstSeenAt();
    if (firstSeenAt == null) {
      firstSeenAt = now;
      await _repository.setFirstSeenAt(now);
      return null;
    }
    if (now.isBefore(firstSeenAt.toUtc().add(_firstSeenMinAge))) {
      return null;
    }

    final downloadCount = await _repository.getTriggerCount(
      RatePromptTrigger.flightMapDownloadSuccess,
    );
    if (downloadCount < _minDownloadSuccessCountToPrompt) {
      return null;
    }

    final snoozedUntil = await _repository.getSnoozedUntil();
    if (snoozedUntil != null && now.isBefore(snoozedUntil.toUtc())) {
      return null;
    }

    final canRequestReview = _isActionAvailable(
      now,
      await _repository.getReviewSnoozedUntil(),
    );
    final canShare = _isActionAvailable(
      now,
      await _repository.getShareSnoozedUntil(),
    );
    if (!canRequestReview && !canShare) return null;

    return RatePromptState(
      requiresSentimentAnswer: !await _repository.hasPositiveResponse(),
      canRequestReview: canRequestReview,
      canShare: canShare,
    );
  }

  @override
  Future<void> recordAccepted() async {
    await _repository.setCompleted(false);
    await _repository.setHasPositiveResponse(true);
  }

  @override
  Future<void> recordDeclined() async {
    final now = _nowProvider().toUtc();
    await _repository.setHasPositiveResponse(false);
    await _repository.setSnoozedUntil(now.add(_declineSnooze));
  }

  @override
  Future<void> recordDismissed() async {
    final now = _nowProvider().toUtc();
    await _repository.setSnoozedUntil(now.add(_dismissSnooze));
  }

  @override
  Future<void> recordReviewRequested() async {
    final now = _nowProvider().toUtc();
    await _repository.setReviewSnoozedUntil(now.add(_actionSnooze));
    await _repository.setSnoozedUntil(now.add(_dismissSnooze));
  }

  @override
  Future<void> recordAppShared() async {
    final now = _nowProvider().toUtc();
    await _repository.setShareSnoozedUntil(now.add(_actionSnooze));
    await _repository.setSnoozedUntil(now.add(_dismissSnooze));
  }

  Future<int> _incrementTriggerCount(RatePromptTrigger trigger) async {
    final current = await _repository.getTriggerCount(trigger);
    final next = current + 1;
    await _repository.setTriggerCount(trigger, next);
    return next;
  }

  bool _isActionAvailable(DateTime now, DateTime? snoozedUntil) {
    return snoozedUntil == null || !now.isBefore(snoozedUntil.toUtc());
  }
}
