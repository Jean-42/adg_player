import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';
import '../services/player_controller.dart';
import '../theme.dart';

class NativeVideoPlayer extends StatefulWidget {
  final String url;
  final bool isLocal;

  const NativeVideoPlayer({
    super.key,
    required this.url,
    this.isLocal = false,
  });

  @override
  State<NativeVideoPlayer> createState() => _NativeVideoPlayerState();
}

class _NativeVideoPlayerState extends State<NativeVideoPlayer> {
  VideoPlayerController? _vpc;
  ChewieController?      _cc;
  bool _error = false;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _init(widget.url);
  }

  @override
  void didUpdateWidget(NativeVideoPlayer old) {
    super.didUpdateWidget(old);
    if (widget.url != _currentUrl) _init(widget.url);
  }

  Future<void> _init(String url) async {
    _currentUrl = url;
    await _dispose();
    setState(() => _error = false);

    try {
      final vpc = widget.isLocal
          ? VideoPlayerController.contentUri(Uri.parse(url))
          : VideoPlayerController.networkUrl(Uri.parse(url));

      await vpc.initialize();

      final cc = ChewieController(
        videoPlayerController: vpc,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        materialProgressColors: ChewieProgressColors(
          playedColor:  AppColors.accent,
          handleColor:  AppColors.accent2,
          backgroundColor: AppColors.bg4,
          bufferedColor: AppColors.bg3,
        ),
        placeholder: Container(color: Colors.black),
        errorBuilder: (ctx, msg) => Center(
          child: Text(msg,
              style: const TextStyle(color: AppColors.red, fontSize: 12)),
        ),
      );

      vpc.addListener(() {
        if (vpc.value.position >= vpc.value.duration &&
            vpc.value.duration > Duration.zero) {
          context.read<PlayerController>().onNativeEnded();
        }
      });

      if (mounted) setState(() { _vpc = vpc; _cc = cc; });
    } catch (e) {
      if (mounted) setState(() => _error = true);
    }
  }

  Future<void> _dispose() async {
    _cc?.dispose();
    await _vpc?.dispose();
    _cc = null;
    _vpc = null;
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.red, size: 32),
            SizedBox(height: 8),
            Text('Could not load media',
                style: TextStyle(color: AppColors.red, fontSize: 12)),
          ],
        ),
      );
    }

    if (_cc == null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
            color: AppColors.accent, strokeWidth: 2),
      );
    }

    return Chewie(controller: _cc!);
  }
}
