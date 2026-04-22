import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import '../services/player_controller.dart';
import '../theme.dart';

class YoutubePlayerWidget extends StatefulWidget {
  final String videoId;
  final String title;
  final String subtitle;
  final bool fullscreen;

  const YoutubePlayerWidget({
    super.key,
    required this.videoId,
    required this.title,
    required this.subtitle,
    this.fullscreen = false,
  });

  @override
  State<YoutubePlayerWidget> createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget> {
  late YoutubePlayerController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        enableCaption: true,
      ),
    );

    _controller.addListener(_onPlayerStateChange);
  }

  void _onPlayerStateChange() {
    final state = _controller.value.playerState;
    
    switch (state) {
      case PlayerState.playing:
        debugPrint('[YouTube] Playing');
        if (mounted) setState(() => _loading = false);
        break;
      case PlayerState.ended:
        debugPrint('[YouTube] Ended');
        if (mounted) {
          context.read<PlayerController>().onNativeEnded();
        }
        break;
      case PlayerState.buffering:
        if (mounted) setState(() => _loading = true);
        break;
      default:
        break;
    }
  }

  @override
  void didUpdateWidget(YoutubePlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _controller.load(widget.videoId);
      if (mounted) setState(() => _loading = true);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerStateChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.accent,
          progressColors: const ProgressBarColors(
            playedColor: AppColors.accent,
            handleColor: AppColors.accent2,
            backgroundColor: AppColors.bg4,
            bufferedColor: AppColors.bg3,
          ),
          onReady: () {
            if (mounted) setState(() => _loading = false);
          },
          onEnded: (_) {
            debugPrint('[YouTube] Video ended');
            context.read<PlayerController>().onNativeEnded();
          },
        ),
        if (_loading)
          Container(
            color: Colors.black87,
            alignment: Alignment.center,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                    color: AppColors.accent, strokeWidth: 2.5),
              ),
              const SizedBox(height: 10),
              Text('Loading ${widget.subtitle}…',
                  style: const TextStyle(color: AppColors.text2, fontSize: 12)),
            ]),
          ),
      ],
    );
  }
}