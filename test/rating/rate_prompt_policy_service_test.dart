import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/rating/rate_prompt_policy_service.dart';
import 'package:flymap/rating/rate_prompt_repository.dart';
import 'package:flymap/rating/rate_prompt_trigger.dart';

void main() {
  group('DefaultRatePromptPolicyService', () {
    test(
      'does not show until download count and first-seen age are satisfied',
      () async {
        final repository = _InMemoryRatePromptRepository();
        final service = DefaultRatePromptPolicyService(
          repository: repository,
          nowProvider: () => DateTime.utc(2026, 4, 9),
        );

        await service.registerTrigger(
          RatePromptTrigger.flightMapDownloadSuccess,
        );
        expect(await service.getPromptState(), isNull);

        await service.registerTrigger(
          RatePromptTrigger.flightMapDownloadSuccess,
        );
        expect(await service.getPromptState(), isNull);

        repository.firstSeenAt = DateTime.utc(2026, 4, 1);
        final state = await service.getPromptState();
        expect(state, isNotNull);
        expect(state!.requiresSentimentAnswer, isTrue);
      },
    );

    test('decline snoozes prompts for 90 days', () async {
      var now = DateTime.utc(2026, 4, 9);
      final repository = _InMemoryRatePromptRepository();
      final service = DefaultRatePromptPolicyService(
        repository: repository,
        nowProvider: () => now,
        firstSeenMinAge: Duration.zero,
      );

      expect(await service.getPromptState(), isNull);
      for (var i = 0; i < 2; i++) {
        await service.registerTrigger(
          RatePromptTrigger.flightMapDownloadSuccess,
        );
      }
      expect(await service.getPromptState(), isNotNull);
      await service.recordDeclined();

      expect(await service.getPromptState(), isNull);

      now = now.add(const Duration(days: 89));
      expect(await service.getPromptState(), isNull);

      now = now.add(const Duration(days: 2));
      expect(await service.getPromptState(), isNotNull);
    });

    test('review attempt leaves only sharing after prompt snooze', () async {
      var now = DateTime.utc(2026, 4, 9);
      final repository = _InMemoryRatePromptRepository();
      final service = DefaultRatePromptPolicyService(
        repository: repository,
        nowProvider: () => now,
        firstSeenMinAge: Duration.zero,
      );

      expect(await service.getPromptState(), isNull);
      for (var i = 0; i < 2; i++) {
        await service.registerTrigger(
          RatePromptTrigger.flightMapDownloadSuccess,
        );
      }
      expect(await service.getPromptState(), isNotNull);
      await service.recordAccepted();
      await service.recordReviewRequested();

      expect(await service.getPromptState(), isNull);

      now = now.add(const Duration(days: 15));
      final shareOnly = await service.getPromptState();
      expect(shareOnly, isNotNull);
      expect(shareOnly!.requiresSentimentAnswer, isFalse);
      expect(shareOnly.canRequestReview, isFalse);
      expect(shareOnly.canShare, isTrue);

      now = now.add(const Duration(days: 166));
      final bothActions = await service.getPromptState();
      expect(bothActions, isNotNull);
      expect(bothActions!.canRequestReview, isTrue);
      expect(bothActions.canShare, isTrue);
    });

    test(
      'completed share leaves only native review after prompt snooze',
      () async {
        var now = DateTime.utc(2026, 4, 9);
        final repository = _InMemoryRatePromptRepository();
        final service = DefaultRatePromptPolicyService(
          repository: repository,
          nowProvider: () => now,
          firstSeenMinAge: Duration.zero,
        );

        await service.getPromptState();
        for (var i = 0; i < 2; i++) {
          await service.registerTrigger(
            RatePromptTrigger.flightMapDownloadSuccess,
          );
        }
        await service.recordAccepted();
        await service.recordAppShared();

        now = now.add(const Duration(days: 15));
        final reviewOnly = await service.getPromptState();
        expect(reviewOnly, isNotNull);
        expect(reviewOnly!.requiresSentimentAnswer, isFalse);
        expect(reviewOnly.canRequestReview, isTrue);
        expect(reviewOnly.canShare, isFalse);
      },
    );

    test('legacy completed users are migrated to a 180-day snooze', () async {
      var now = DateTime.utc(2026, 4, 9);
      final repository = _InMemoryRatePromptRepository()
        .._completed = true
        ..firstSeenAt = DateTime.utc(2026, 4, 1);
      repository._counts[RatePromptTrigger.flightMapDownloadSuccess] = 2;
      final service = DefaultRatePromptPolicyService(
        repository: repository,
        nowProvider: () => now,
      );

      expect(await service.getPromptState(), isNull);
      expect(repository._completed, isFalse);
      expect(await service.getPromptState(), isNull);

      now = now.add(const Duration(days: 181));
      expect(await service.getPromptState(), isNotNull);
    });
  });
}

class _InMemoryRatePromptRepository implements RatePromptRepository {
  bool _completed = false;
  bool _hasPositiveResponse = false;
  DateTime? _snoozedUntil;
  DateTime? _reviewSnoozedUntil;
  DateTime? _shareSnoozedUntil;
  DateTime? firstSeenAt;
  final Map<RatePromptTrigger, int> _counts = {};

  @override
  Future<int> getTriggerCount(RatePromptTrigger trigger) async {
    return _counts[trigger] ?? 0;
  }

  @override
  Future<void> setTriggerCount(RatePromptTrigger trigger, int count) async {
    _counts[trigger] = count;
  }

  @override
  Future<bool> isCompleted() async => _completed;

  @override
  Future<void> setCompleted(bool completed) async {
    _completed = completed;
  }

  @override
  Future<DateTime?> getSnoozedUntil() async => _snoozedUntil;

  @override
  Future<void> setSnoozedUntil(DateTime? value) async {
    _snoozedUntil = value;
  }

  @override
  Future<bool> hasPositiveResponse() async => _hasPositiveResponse;

  @override
  Future<void> setHasPositiveResponse(bool value) async {
    _hasPositiveResponse = value;
  }

  @override
  Future<DateTime?> getReviewSnoozedUntil() async => _reviewSnoozedUntil;

  @override
  Future<void> setReviewSnoozedUntil(DateTime? value) async {
    _reviewSnoozedUntil = value;
  }

  @override
  Future<DateTime?> getShareSnoozedUntil() async => _shareSnoozedUntil;

  @override
  Future<void> setShareSnoozedUntil(DateTime? value) async {
    _shareSnoozedUntil = value;
  }

  @override
  Future<DateTime?> getFirstSeenAt() async => firstSeenAt;

  @override
  Future<void> setFirstSeenAt(DateTime value) async {
    firstSeenAt = value;
  }
}
