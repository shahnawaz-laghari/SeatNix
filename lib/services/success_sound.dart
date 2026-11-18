import 'package:audioplayers/audioplayers.dart';

/// Plays the short success chime when a payment completes.
class SuccessSound {
  SuccessSound._();

  static final AudioPlayer _player = AudioPlayer();

  static Future<void> play() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/success.wav'));
    } catch (_) {
      // Audio is a finishing touch; never block the success screen if it fails.
    }
  }

  static Future<void> dispose() => _player.dispose();
}
