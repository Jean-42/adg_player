import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import '../services/player_controller.dart';
import '../theme.dart';

class YoutubePlayerWidget extends StatefulWidget {
  final String videoId;
  final String title;
  final String subtitle;

  const YoutubePlayerWidget({
    super.key,
    required this.videoId,
    required this.title,
    required this.subtitle,
  });

  @override
  State<YoutubePlayerWidget> createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget> {
  late YoutubePlayerController _controller;
  bool _loading = true;
  bool _didSeekToResume = false;
  Timer? _positionTimer;

  String get _itemId => 'yt_${widget.videoId}';

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _didSeekToResume = false;
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        enableCaption: true,
        forceHD: false,
      ),
    );
    _controller.addListener(_onPlayerState);
  }

  void _onPlayerState() {
    final v = _controller.value;

    // Seek to resume position the first time the video starts playing
    if (!_didSeekToResume && v.playerState == PlayerState.playing) {
      _didSeekToResume = true;
      final resume = context.read<PlayerController>().getSavedPosition(_itemId);
      if (resume != null && resume.inSeconds > 5) {
        _controller.seekTo(resume);
      }
    }

    switch (v.playerState) {
      case PlayerState.playing:
        if (mounted) setState(() => _loading = false);
        _startPositionTimer();
        break;
      case PlayerState.paused:
        _savePosition();
        break;
      case PlayerState.ended:
        context.read<PlayerController>().reportEmbedPosition(_itemId, Duration.zero);
        if (mounted) context.read<PlayerController>().onNativeEnded();
        break;
      case PlayerState.buffering:
        if (mounted) setState(() => _loading = true);
        break;
      default:
        break;
    }
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_controller.value.playerState == PlayerState.playing) _savePosition();
    });
  }

  void _savePosition() {
    if (!mounted) return;
    final pos = _controller.value.position;
    context.read<PlayerController>().reportEmbedPosition(_itemId, pos);
  }

  @override
  void didUpdateWidget(YoutubePlayerWidget old) {
    super.didUpdateWidget(old);
    if (old.videoId != widget.videoId) {
      _positionTimer?.cancel();
      _didSeekToResume = false;
      _controller.load(widget.videoId);
      if (mounted) setState(() => _loading = true);
    }
  }

  @override
  void dispose() {
    _savePosition();
    _positionTimer?.cancel();
    _controller.removeListener(_onPlayerState);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // YoutubePlayerBuilder handles fullscreen correctly — pushes a route that
    // covers the entire screen (header, footer, nav bar) on fullscreen tap.
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.accent,
        progressColors: const ProgressBarColors(
          playedColor:     AppColors.accent,
          handleColor:     AppColors.accent2,
          backgroundColor: AppColors.bg4,
          bufferedColor:   AppColors.bg3,
        ),
        onReady: () {
          if (mounted) setState(() => _loading = false);
        },
        onEnded: (_) {
          context.read<PlayerController>().reportEmbedPosition(_itemId, Duration.zero);
          context.read<PlayerController>().onNativeEnded();
        },
      ),
      onEnterFullScreen: () {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      },
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      },
      builder: (context, player) {
        return Stack(children: [
          player,
          if (_loading)
            Container(
              color: Colors.black87,
              alignment: Alignment.center,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(
                  width: 28, height: 28,
                  child: CircularProgressIndicator(
                      color: AppColors.accent, strokeWidth: 2.5),
                ),
                const SizedBox(height: 10),
                Text('Loading ${widget.subtitle}…',
                    style: const TextStyle(
                        color: AppColors.text2, fontSize: 12)),
              ]),
            ),
        ]);
      },
    );
  }
}
