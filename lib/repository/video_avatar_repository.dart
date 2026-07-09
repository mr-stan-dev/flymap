import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's flight-video avatar: a locally-stored photo that rides the plane
/// and appears on the summary card. There is no account or upload — [imagePath]
/// points at a file copied into the app's documents directory.
///
/// The name shown beside the avatar is NOT stored here — it reuses the profile
/// display name from onboarding/settings ([OnboardingRepository]) so there is a
/// single username across the app.
class VideoAvatarConfig {
  const VideoAvatarConfig({this.enabled = false, this.imagePath});

  /// Whether the avatar is shown in videos.
  final bool enabled;

  /// Absolute path to the avatar image resolved against the CURRENT documents
  /// directory, or null when none is stored / the file is gone.
  final String? imagePath;

  bool get hasImage => (imagePath ?? '').isNotEmpty;

  VideoAvatarConfig copyWith({bool? enabled, String? imagePath}) =>
      VideoAvatarConfig(
        enabled: enabled ?? this.enabled,
        imagePath: imagePath ?? this.imagePath,
      );
}

/// Persists the flight-video avatar photo + on/off choice in shared preferences.
///
/// The photo is stored as a path *relative* to the documents directory and
/// re-resolved against the current directory on read. iOS changes the app
/// container's path between launches/builds (the files are migrated, but the
/// absolute path prefix changes), so a stored absolute path goes stale and the
/// avatar "disappears" — most visibly in debug. Same fix as the sky-camera
/// media store.
class VideoAvatarRepository {
  static const _kEnabled = 'video.avatar.enabled';
  static const _kImagePath = 'video.avatar.imagePath';

  Future<VideoAvatarConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return VideoAvatarConfig(
      enabled: prefs.getBool(_kEnabled) ?? false,
      imagePath: await _resolve(prefs.getString(_kImagePath)),
    );
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, enabled);
  }

  /// Stores the picked avatar photo (as a documents-relative path). Enabling is
  /// a separate step so picking a photo doesn't force the avatar on until the
  /// user applies the setting.
  Future<void> setImagePath(String absolutePath) async {
    final prefs = await SharedPreferences.getInstance();
    final documents = await _documentsPath();
    final trimmed = absolutePath.trim();
    final toStore = p.isWithin(documents, trimmed)
        ? p.relative(trimmed, from: documents)
        : p.basename(trimmed);
    await prefs.setString(_kImagePath, toStore);
  }

  /// Resolves a stored (relative, or legacy absolute) path against the current
  /// documents directory, returning null when nothing is stored or the file no
  /// longer exists.
  Future<String?> _resolve(String? stored) async {
    final trimmed = stored?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final documents = await _documentsPath();
    final String resolved;
    if (!p.isAbsolute(trimmed)) {
      resolved = p.join(documents, trimmed);
    } else if (p.isWithin(documents, trimmed)) {
      resolved = trimmed;
    } else {
      // Legacy absolute path from an old container: rebase by filename.
      resolved = p.join(documents, p.basename(trimmed));
    }
    return await File(resolved).exists() ? resolved : null;
  }

  Future<String> _documentsPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }
}
