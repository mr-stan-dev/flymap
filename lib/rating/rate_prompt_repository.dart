import 'package:flymap/rating/rate_prompt_trigger.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class RatePromptRepository {
  Future<int> getTriggerCount(RatePromptTrigger trigger);

  Future<void> setTriggerCount(RatePromptTrigger trigger, int count);

  Future<bool> isCompleted();

  Future<void> setCompleted(bool completed);

  Future<DateTime?> getSnoozedUntil();

  Future<void> setSnoozedUntil(DateTime? value);
}

class SharedPrefsRatePromptRepository implements RatePromptRepository {
  static const _kCompleted = 'rate_prompt.completed';
  static const _kSnoozedUntil = 'rate_prompt.snoozed_until';
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
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_kSnoozedUntil);
      return;
    }
    await prefs.setString(_kSnoozedUntil, value.toUtc().toIso8601String());
  }

  String _triggerCountKey(RatePromptTrigger trigger) =>
      '$_kTriggerCountPrefix.${trigger.storageKey}';
}
