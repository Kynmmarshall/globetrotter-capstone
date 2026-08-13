import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Records a voice message and hands back its raw bytes for upload - mirrors
/// trip_map.dart's ensureLocationPermission() convention of letting the
/// plugin manage its own permission API rather than adding a general
/// permission_handler dependency.
class VoiceRecordingResult {
  const VoiceRecordingResult({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

class VoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> ensurePermission() => _recorder.hasPermission();

  Future<void> start() async {
    // `path` is a required parameter on every platform, but is documented
    // as ignored on web (the browser keeps the recording as an in-memory
    // Blob instead) - path_provider's temp directory is only meaningful on
    // the IO platforms, so web gets a harmless placeholder.
    final path = kIsWeb
        ? 'voice.wav'
        : '${(await getTemporaryDirectory()).path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: path);
  }

  Future<VoiceRecordingResult?> stop() async {
    final result = await _recorder.stop();
    if (result == null) return null;

    // On web, stop() returns a blob: URL (the recording lives in the
    // browser's memory as a Blob, never touches disk) - fetching it is how
    // you get the actual bytes back out, and it resolves fine since the
    // blob was created by this same page. On Android/Windows, it's a real
    // file path written to path_provider's temp directory.
    final bytes = kIsWeb
        ? (await http.get(Uri.parse(result))).bodyBytes
        : await File(result).readAsBytes();
    if (bytes.isEmpty) return null;
    return VoiceRecordingResult(bytes: bytes, filename: 'voice.wav');
  }

  Future<void> dispose() => _recorder.dispose();
}
