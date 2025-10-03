import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  AudioPlayerService() {
    _player = AudioPlayer();
  }

  late final AudioPlayer _player;

  Stream<PlayerState> get stateStream => _player.playerStateStream;

  Future<void> playRemote(String url) async {
    await _player.stop();
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> stop() => _player.stop();

  Future<void> dispose() async {
    await _player.dispose();
  }
}
