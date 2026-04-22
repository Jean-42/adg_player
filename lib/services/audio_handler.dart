import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Runs in a background isolate — keeps audio alive when screen is off.
/// Handles the media notification with play/pause/next/prev/stop buttons.
class AdgAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  AdgAudioHandler() {
    _init();
  }

  void _init() {
    // Forward player state → audio_service state (powers the notification)
    _player.playbackEventStream.listen(_broadcastState);
    _player.playerStateStream.listen((_) => _broadcastState(null));
    _player.durationStream.listen((d) {
      final current = mediaItem.value;
      if (current != null && d != null) {
        mediaItem.add(current.copyWith(duration: d));
      }
    });
  }

  // ── Called by PlayerController to load a track ─────────────────────

  Future<void> loadTrack({
    required String url,
    required String title,
    required String artist,
    String? artUri,
    Duration startPosition = Duration.zero,
  }) async {
    mediaItem.add(MediaItem(
      id:       url,
      title:    title,
      artist:   artist,
      artUri:   artUri != null ? Uri.parse(artUri) : null,
      duration: null, // will be set once loaded
    ));

    await _player.setUrl(url);
    if (startPosition > Duration.zero) {
      await _player.seek(startPosition);
    }
    await _player.play();
  }

  // ── Standard controls (notification buttons call these) ─────────────

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    // PlayerController handles next — just emit the event
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.completed,
    ));
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.seek(Duration.zero);
  }

  // ── Called for embed types (YouTube etc.) ─────────────────────────
  // Shows a notification so the user can return to the app and use
  // prev/next — even though actual audio is in the WebView.
  Future<void> showEmbedNotification({
    required String title,
    required String artist,
  }) async {
    // Stop any native audio that was playing before
    await _player.stop();

    // Publish a mediaItem so the notification appears
    mediaItem.add(MediaItem(
      id:     'embed_${DateTime.now().millisecondsSinceEpoch}',
      title:  title,
      artist: artist,
    ));

    // Broadcast a "playing" state so Android shows the notification
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.skipToNext,
      ],
      androidCompactActionIndices: const [0, 1],
      processingState: AudioProcessingState.ready,
      playing: true, // tells Android to show the notification
    ));
  }

  AudioPlayer get player => _player;

  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  bool get playing => _player.playing;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  // ── Broadcast current state to audio_service ──────────────────────

  void _broadcastState(dynamic _) {
    final processing = switch (_player.processingState) {
      ProcessingState.idle      => AudioProcessingState.idle,
      ProcessingState.loading   => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready     => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: processing,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }
}
