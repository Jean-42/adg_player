import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/queue_item.dart';
import '../models/radio_station.dart';
import 'audio_handler.dart';


enum PlayerRepeatMode { none, one, all }

class PlayerController extends ChangeNotifier {
  final AdgAudioHandler audioHandler;

  // ── Queue ──────────────────────────────────────────────────────────
  final List<QueueItem> queue = [];
  int _queueIndex = -1;
  PlayerRepeatMode repeatMode = PlayerRepeatMode.none;

  int get queueIndex => _queueIndex;
  QueueItem? get current => _queueIndex >= 0 && _queueIndex < queue.length
      ? queue[_queueIndex] : null;

  // ── Settings ───────────────────────────────────────────────────────
  bool autoplayNext = true;
  bool isFullscreen = false;

  // ── Radio ──────────────────────────────────────────────────────────
  RadioStation? currentRadio;

  // ── Saved position (for resume) ────────────────────────────────────
  // key: queue item id → saved position in milliseconds
  final Map<String, int> _savedPositions = {};

  PlayerController({required this.audioHandler}) {
    _initListeners();
    _loadAll();
  }

  void _initListeners() {
    // Forward audio state changes to UI
    audioHandler.playerStateStream.listen((_) => notifyListeners());
    audioHandler.positionStream.listen((_) => notifyListeners());
    audioHandler.durationStream.listen((_) => notifyListeners());

    // Auto-advance when track ends
    audioHandler.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _saveCurrentPosition(Duration.zero); // reset on complete
        _onTrackEnded();
      }
    });

    // Save position periodically while playing
    audioHandler.positionStream.listen((pos) {
      final cur = current;
      if (cur != null && audioHandler.playing && pos.inSeconds > 0) {
        _savedPositions[cur.id] = pos.inMilliseconds;
        // Persist every 5 seconds to avoid too many writes
        if (pos.inSeconds % 5 == 0) _persistPositions();
      }
    });
  }

  // ── Persistence ────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    final p = await SharedPreferences.getInstance();
    autoplayNext = p.getBool('autoplayNext') ?? true;

    // Restore queue
    final raw = p.getString('adg_queue_v1');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final item in list) {
          final m = item as Map<String, dynamic>;
          queue.add(QueueItem(
            id:              m['id'] ?? '',
            type:            MediaType.values.firstWhere(
                (e) => e.name == m['type'], orElse: () => MediaType.direct),
            url:             m['url'] ?? '',
            embedUrl:        m['embedUrl'] ?? '',
            title:           m['title'] ?? 'Untitled',
            subtitle:        m['subtitle'] ?? '',
            isPortraitVideo: m['isPortraitVideo'] == true,
          ));
        }
      } catch (_) {}
    }

    // Restore saved positions
    final posRaw = p.getString('adg_positions_v1');
    if (posRaw != null) {
      try {
        final map = jsonDecode(posRaw) as Map<String, dynamic>;
        map.forEach((k, v) => _savedPositions[k] = v as int);
      } catch (_) {}
    }

    // Restore last playing index
    final lastIdx = p.getInt('adg_last_index');
    if (lastIdx != null && lastIdx >= 0 && lastIdx < queue.length) {
      _queueIndex = lastIdx;
    }

    if (queue.isNotEmpty) notifyListeners();
  }

  Future<void> _saveQueue() async {
    final p = await SharedPreferences.getInstance();
    final saveable = queue
        .where((q) => q.type != MediaType.local)
        .map((q) => {
              'id':              q.id,
              'type':            q.type.name,
              'url':             q.url,
              'embedUrl':        q.embedUrl,
              'title':           q.title,
              'subtitle':        q.subtitle,
              'isPortraitVideo': q.isPortraitVideo,
            })
        .toList();
    await p.setString('adg_queue_v1', jsonEncode(saveable));
    await p.setInt('adg_last_index', _queueIndex);
  }

  Future<void> _persistPositions() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('adg_positions_v1', jsonEncode(_savedPositions));
  }

  void _saveCurrentPosition(Duration pos) {
    final cur = current;
    if (cur != null) {
      _savedPositions[cur.id] = pos.inMilliseconds;
      _persistPositions();
    }
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('autoplayNext', autoplayNext);
  }

  // ── Saved position helpers ─────────────────────────────────────────

  /// Returns the saved resume position for an item (null if none / < 5s)
  Duration? getSavedPosition(String itemId) {
    final ms = _savedPositions[itemId];
    if (ms == null || ms < 5000) return null; // ignore tiny positions
    return Duration(milliseconds: ms);
  }

  void clearSavedPosition(String itemId) {
    _savedPositions.remove(itemId);
    _persistPositions();
  }

  // ── Audio state getters (for UI) ───────────────────────────────────

  bool get isAudioPlaying => audioHandler.playing;
  Duration get audioPosition => audioHandler.position;
  Duration get audioDuration => audioHandler.duration;

  // ── Queue management ───────────────────────────────────────────────

  void addToQueue(QueueItem item) {
    queue.add(item);
    _saveQueue();
    notifyListeners();
  }

  void removeFromQueue(int index) {
    final item = queue[index];
    _savedPositions.remove(item.id);
    queue.removeAt(index);
    if (_queueIndex >= index && _queueIndex > 0) _queueIndex--;
    _saveQueue();
    notifyListeners();
  }

  void clearQueue() {
    queue.clear();
    _queueIndex = -1;
    _savedPositions.clear();
    audioHandler.stop();
    currentRadio = null;
    _saveQueue();
    _persistPositions();
    notifyListeners();
  }

  void shuffleQueue() {
    if (queue.length < 2) return;
    final cur = current;
    queue.shuffle();
    if (cur != null) _queueIndex = queue.indexOf(cur);
    _saveQueue();
    notifyListeners();
  }

  void cycleRepeat() {
    repeatMode = PlayerRepeatMode.values[
        (repeatMode.index + 1) % PlayerRepeatMode.values.length];
    notifyListeners();
  }

  // ── Playback ───────────────────────────────────────────────────────

  /// Play a queue item. For native audio/radio, starts the audio handler.
  /// For embed types (YouTube etc.), just updates index — WebView handles it.
  Future<void> playItem(int index) async {
  if (index < 0 || index >= queue.length) return;

  if (_queueIndex >= 0 && _queueIndex < queue.length) {
    _saveCurrentPosition(audioHandler.position);
  }

  _queueIndex = index;
  currentRadio = null;
  _saveQueue();
  notifyListeners();

  final item = queue[index];

  // For native audio/video — load into audio handler (plays + shows notification)
  if (item.type == MediaType.direct || item.type == MediaType.local) {
    final resume = getSavedPosition(item.id);
    await audioHandler.loadTrack(
      url: item.url,
      title: item.title,
      artist: item.subtitle,
      startPosition: resume ?? Duration.zero,
    );
  } else {
    // For embed types (YouTube etc.) — stop native audio, WebView handles it
    await audioHandler.stop();
  }
}

  void onNativeEnded() {
    _saveCurrentPosition(Duration.zero);
    _onTrackEnded();
  }

  void _onTrackEnded() {
    if (repeatMode == PlayerRepeatMode.one) { playItem(_queueIndex); return; }
    if (autoplayNext) {
      if (_queueIndex < queue.length - 1) {
        playItem(_queueIndex + 1);
      } else if (repeatMode == PlayerRepeatMode.all && queue.isNotEmpty) {
        playItem(0);
      }
    }
  }

  void playNext() {
    if (_queueIndex < queue.length - 1) playItem(_queueIndex + 1);
  }

  void playPrev() {
    if (_queueIndex > 0) playItem(_queueIndex - 1);
  }

  // ── Audio controls (for native items) ─────────────────────────────

  Future<void> toggleAudio() async {
    if (audioHandler.playing) {
      await audioHandler.pause();
    } else {
      await audioHandler.play();
    }
  }

  Future<void> seekAudio(double fraction) async {
    final target = Duration(
        milliseconds: (audioDuration.inMilliseconds * fraction).round());
    await audioHandler.seek(target);
  }
  
  
  // ── Radio ──────────────────────────────────────────────────────────

  Future<void> playRadio(RadioStation station) async {
    // Save position of previous item
    if (_queueIndex >= 0) _saveCurrentPosition(audioHandler.position);

    currentRadio = station;
    _queueIndex = -1;
    notifyListeners();

    await audioHandler.loadTrack(
      url:    station.streamUrl,
      title:  station.name,
      artist: '${station.country} · Radio',
    );
  }
  
    /// Show notification for embed types (YouTube, Vimeo, etc.)
  /// Used when playing videos that can't maintain background audio
  Future<void> showEmbedNotification(String title, String subtitle) async {
    await audioHandler.showEmbedNotification(
      title: title,
      artist: subtitle,
    );
  }

  // ── Fullscreen ─────────────────────────────────────────────────────

  void enterFullscreen() { isFullscreen = true;  notifyListeners(); }
  void exitFullscreen()  { isFullscreen = false; notifyListeners(); }

  // ── Settings ───────────────────────────────────────────────────────

  void toggleAutoplay() {
    autoplayNext = !autoplayNext;
    _savePrefs();
    notifyListeners();
  }

  @override
void dispose() {
  // DO NOT call audioHandler.stop() here!
  // The background service should keep running
  // Only stop if user explicitly stops it
  super.dispose();
}
}
