import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';

class RecordingPermissionException implements Exception {
  RecordingPermissionException([this.message = 'Microphone permission denied']);

  final String message;

  @override
  String toString() => message;
}

/// M4A capture + optional Supabase Storage upload.
class RecordingService {
  RecordingService() {
    _isRecordingController = StreamController<bool>.broadcast();
    _isRecordingController.add(false);
    _stateSub = _recorder.onStateChanged().listen((state) {
      final active =
          state == RecordState.record || state == RecordState.pause;
      if (!_isRecordingController.isClosed) {
        _isRecordingController.add(active);
      }
    });
  }

  final AudioRecorder _recorder = AudioRecorder();
  late final StreamController<bool> _isRecordingController;
  StreamSubscription<RecordState>? _stateSub;
  String? _activePath;

  Stream<bool> get isRecordingStream => _isRecordingController.stream;

  static Future<String?> uploadAudio(String filePath, String userId) async {
    if (!SupabaseService.isInitialized) {
      debugPrint('uploadAudio: Supabase not initialized');
      return null;
    }
    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint('uploadAudio: file not found');
      return null;
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$userId/$ts.m4a';
    try {
      await Supabase.instance.client.storage.from('audio-files').upload(
            storagePath,
            file,
            fileOptions: const FileOptions(
              contentType: 'audio/mp4',
              upsert: true,
            ),
          );
      return Supabase.instance.client.storage
          .from('audio-files')
          .getPublicUrl(storagePath);
    } on StorageException catch (e, st) {
      debugPrint('uploadAudio: $e\n$st');
      return null;
    } catch (e, st) {
      debugPrint('uploadAudio: $e\n$st');
      return null;
    }
  }

  /// [Permission.microphone] shows the iOS/Android system prompt reliably; then
  /// [AudioRecorder.hasPermission](request: false) aligns the `record` plugin.
  Future<void> startRecording() async {
    if (await _recorder.isRecording() || await _recorder.isPaused()) {
      return;
    }

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      throw RecordingPermissionException(
        mic.isPermanentlyDenied
            ? 'Microphone is off for Thankful. Enable it in Settings → Thankful → Microphone.'
            : 'Microphone permission denied',
      );
    }

    final synced = await _recorder.hasPermission(request: false);
    if (!synced) {
      debugPrint(
        'startRecording: mic granted but record.hasPermission false; continuing.',
      );
    }

    if (!await _recorder.isEncoderSupported(AudioEncoder.aacLc)) {
      throw StateError('AAC-LC encoder not supported on this device');
    }

    final dir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${dir.path}/recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    final path =
        '${recordingsDir.path}/journal_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _activePath = path;

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
  }

  Future<String?> stopRecording() async {
    if (!await _recorder.isRecording() && !await _recorder.isPaused()) {
      _activePath = null;
      return null;
    }
    final path = await _recorder.stop();
    _activePath = null;
    return path;
  }

  Future<void> cancelRecording() async {
    final path = _activePath;
    _activePath = null;
    try {
      await _recorder.cancel();
    } catch (e, st) {
      debugPrint('cancelRecording: $e\n$st');
    }
    if (path != null) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (e, st) {
        debugPrint('cancelRecording delete: $e\n$st');
      }
    }
  }

  Future<void> dispose() async {
    await _stateSub?.cancel();
    _stateSub = null;
    try {
      if (await _recorder.isRecording() || await _recorder.isPaused()) {
        await _recorder.cancel();
      }
    } catch (e, st) {
      debugPrint('RecordingService.dispose: $e\n$st');
    }
    if (_activePath != null) {
      try {
        final f = File(_activePath!);
        if (await f.exists()) await f.delete();
      } catch (_) {}
      _activePath = null;
    }
    await _recorder.dispose();
    await _isRecordingController.close();
  }
}
