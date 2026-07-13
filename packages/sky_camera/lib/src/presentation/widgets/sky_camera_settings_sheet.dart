import 'package:flutter/material.dart';
import 'package:sky_camera/src/presentation/sky_camera_strings.dart';

/// Camera settings bottom sheet — currently just the record-audio toggle.
/// [audioEnabled] is the current driver state; flipping the switch resolves
/// through [onRecordAudioChanged], which returns the value that actually
/// took effect (a denied microphone falls back to off).
Future<void> showSkyCameraSettingsSheet(
  BuildContext context, {
  required SkyCameraStrings strings,
  required bool audioEnabled,
  required Future<bool> Function(bool enabled) onRecordAudioChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF10151F),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _SkyCameraSettingsSheet(
      strings: strings,
      audioEnabled: audioEnabled,
      onRecordAudioChanged: onRecordAudioChanged,
    ),
  );
}

class _SkyCameraSettingsSheet extends StatefulWidget {
  const _SkyCameraSettingsSheet({
    required this.strings,
    required this.audioEnabled,
    required this.onRecordAudioChanged,
  });

  final SkyCameraStrings strings;
  final bool audioEnabled;
  final Future<bool> Function(bool enabled) onRecordAudioChanged;

  @override
  State<_SkyCameraSettingsSheet> createState() =>
      _SkyCameraSettingsSheetState();
}

class _SkyCameraSettingsSheetState extends State<_SkyCameraSettingsSheet> {
  late bool _audioEnabled = widget.audioEnabled;
  bool _isApplying = false;

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.settingsTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const Key('sky_camera.settings_record_audio'),
              contentPadding: EdgeInsets.zero,
              value: _audioEnabled,
              onChanged: _isApplying ? null : _handleChanged,
              title: Text(
                strings.recordAudio,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              subtitle: Text(
                strings.recordAudioHint,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.64),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleChanged(bool enabled) async {
    setState(() {
      _audioEnabled = enabled;
      _isApplying = true;
    });
    final effective = await widget.onRecordAudioChanged(enabled);
    if (!mounted) return;
    setState(() {
      _audioEnabled = effective;
      _isApplying = false;
    });
  }
}
