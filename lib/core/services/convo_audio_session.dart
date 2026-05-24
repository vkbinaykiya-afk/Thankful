import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';

/// iOS/Android audio session for voice convo (mic + TTS + bg music).
///
/// Without [activateForVoiceSession], iOS often returns OSStatus `561017449`
/// (`!pri` / [AVAudioSessionErrorInsufficientPriority]) when [record] and
/// [just_audio] compete. Note: `561145187` (`!rec` / CannotStartRecording) is a
/// different code — do not confuse the two.
class ConvoAudioSession {
  ConvoAudioSession._();

  static const int _iosInsufficientPriority = 561017449;

  /// Configures play-and-record and activates the session.
  static Future<void> activateForVoiceSession() async {
    print('[AudioSession] Configuring for playAndRecord...');
    final session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker |
                AVAudioSessionCategoryOptions.allowBluetooth,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );
    await session.setActive(true);
    print('[AudioSession] Configured successfully — playAndRecord active');
  }

  /// User-facing message for convo startup failures.
  static String messageForError(Object error) {
    if (error is PlatformException &&
        error.code == '$_iosInsufficientPriority') {
      return 'Another app is using your microphone or speaker '
          '(call, music, etc.). Close it and try again.';
    }
    final text = error.toString();
    if (text.contains('561017449') || text.contains('!pri')) {
      return 'Another app is using your microphone or speaker '
          '(call, music, etc.). Close it and try again.';
    }
    if (error is StateError && text.contains('CARTESIA_API_KEY')) {
      return 'Voice is not configured for this build. Please update the app.';
    }
    if (error is StateError && text.contains('DEEPGRAM_API_KEY')) {
      return 'Listening is not configured for this build. Please update the app.';
    }
    return 'Could not start session. Please try again.';
  }
}
