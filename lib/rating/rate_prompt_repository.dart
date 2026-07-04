import 'package:flymap/rating/rate_prompt_trigger.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class RatePromptRepository {
  Future<int> getTriggerCount(RatePromptTrigger trigger);

  Future<void> setTriggerCount(RatePromptTrigger trigger, int count);

  Future<bool> isCompleted();

  Future<void> setCompleted(bool completed);

  Future<DateTime?> getSnoozedUntil();

  Future<void> setSnoozedUntil(DateTime? value);

  Future<bool> hasPositiveResponse();

  Future<void> setHasPositiveResponse(bool value);

  Future<DateTime?> getReviewSnoozedUntil();

  Future<void> setReviewSnoozedUntil(DateTime? value);

  Future<DateTime?> getShareSnoozedUntil();

  Future<void> setShareSnoozedUntil(DateTime? value);

  Future<DateTime?> getFirstSeenAt();

  Future<void> setFirstSeenAt(DateTime value);
}

class SharedPrefsRatePromptRepository implements RatePromptRepository {
  static const _kCompleted = 'rate_prompt.completed';
  static const _kSnoozedUntil = 'rate_prompt.snoozed_until';
  static const _kHasPositiveResponse = 'rate_prompt.has_positive_response';
  static const _kReviewSnoozedUntil = 'rate_prompt.review_snoozed_until';
  static const _kShareSnoozedUntil = 'rate_prompt.share_snoozed_until';
  static const _kFirstSeenAt = 'rate_prompt.first_seen_at';
  static const _kTriggerCountPrefix = 'rate_prompt.trigger_count';

  @override
  Future<int> getTriggerCount(RatePromptTrigger trigger) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_triggerCountKey(trigger)) ?? 0;
  }

  @override
  Future<void> setTriggerCount(RatePromptTrigger trigger, int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_triggerCountKey(trigger), count < 0 ? 0 : count);
  }

  @override
  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kCompleted) ?? false;
  }

  @override
  Future<void> setCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCompleted, completed);
  }

  @override
  Future<DateTime?> getSnoozedUntil() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSnoozedUntil);
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  @override
  Future<void> setSnoozedUntil(DateTime? value) async {
    await _setDateTime(_kSnoozedUntil, value);
  }

  @override
  Future<bool> hasPositiveResponse() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHasPositiveResponse) ?? false;
  }

  @override
  Future<void> setHasPositiveResponse(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasPositiveResponse, value);
  }

  @override
  Future<DateTime?> getReviewSnoozedUntil() =>
      _getDateTime(_kReviewSnoozedUntil);

  @override
  Future<void> setReviewSnoozedUntil(DateTime? value) =>
      _setDateTime(_kReviewSnoozedUntil, value);

  @override
  Future<DateTime?> getShareSnoozedUntil() => _getDateTime(_kShareSnoozedUntil);

  @override
  Future<void> setShareSnoozedUntil(DateTime? value) =>
      _setDateTime(_kShareSnoozedUntil, value);

  @override
  Future<DateTime?> getFirstSeenAt() => _getDateTime(_kFirstSeenAt);

  @override
  Future<void> setFirstSeenAt(DateTime value) =>
      _setDateTime(_kFirstSeenAt, value);

  Future<DateTime?> _getDateTime(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _setDateTime(String key, DateTime? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, value.toUtc().toIso8601String());
  }

  String _triggerCountKey(RatePromptTrigger trigger) =>
      '$_kTriggerCountPrefix.${trigger.storageKey}';
}
