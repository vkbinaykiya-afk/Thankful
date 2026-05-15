import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Uploads local audio to Supabase Storage (`Journal-audio-files` bucket).
class AudioUploadService {
  const AudioUploadService();

  static const String _bucket = 'Journal-audio-files';

  /// Reads [filePath] and uploads to **`Journal-audio-files` / `{userId}/{timestamp}.m4a`**.
  ///
  /// Returns the object path within the bucket (e.g. `abc-user-id/1730000000000.m4a`).
  /// Throws [ArgumentError] for invalid inputs, [StateError] for missing Supabase
  /// config or failed upload.
  Future<String> uploadAudio(String filePath, String userId) async {
    final uid = userId.trim();
    if (uid.isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'userId must not be empty.',
      );
    }

    if (!SupabaseService.isInitialized) {
      throw StateError(
        'Supabase is not initialized. Add SUPABASE_URL and SUPABASE_ANON_KEY '
        'to .env (or pass --dart-define) before uploading audio.',
      );
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw ArgumentError.value(
        filePath,
        'filePath',
        'No file exists at this path.',
      );
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final lowerPath = filePath.toLowerCase();
    final isWav = lowerPath.endsWith('.wav');
    final ext = isWav ? 'wav' : 'm4a';
    final storagePath = '$uid/$ts.$ext';
    final contentType = isWav ? 'audio/wav' : 'audio/mp4';

    try {
      await Supabase.instance.client.storage.from(_bucket).upload(
            storagePath,
            file,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );
    } on StorageException catch (e) {
      throw StateError(
        'Supabase Storage upload failed: ${e.message}',
      );
    } catch (e) {
      throw StateError('Audio upload failed: $e');
    }

    return storagePath;
  }
}
