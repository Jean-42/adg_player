import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_controller.dart';
import '../models/queue_item.dart';
import '../widgets/embed_player.dart';
import '../widgets/native_video_player.dart';
import '../theme.dart';

// Facebook and Instagram are always 9:16 portrait.
bool _isPortrait(QueueItem? item) =>
    item?.type == MediaType.facebook || item?.type == MediaType.instagram;

class PlayerSection extends StatelessWidget {
  const PlayerSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl     = context.watch<PlayerController>();
    final cur      = ctrl.current;
    final screenW  = MediaQuery.of(context).size.width;
    final portrait = _isPortrait(cur);

    // Portrait (Facebook/Instagram): full width at 9:16, tall enough for controls
    if (portrait) {
      final h = (screenW * 16 / 9).clamp(300.0, 460.0);
      return Container(
        color: Colors.black,
        width: double.infinity,
        height: h,
        child: _buildPlayer(ctrl, cur),
      );
    }

    // Landscape — give enough height so the Chewie/YouTube fullscreen
    // button sits comfortably above the bottom nav bar
    final playerH = (screenW * 9 / 16).clamp(200.0, 280.0);
    return SizedBox(
      width: double.infinity,
      height: playerH,
      child: _buildPlayer(ctrl, cur),
    );
  }

  Widget _buildPlayer(PlayerController ctrl, QueueItem? cur) {
    if (ctrl.currentTv != null) {
      return NativeVideoPlayer(
          url: ctrl.currentTv!.streamUrl, isLocal: false, isLiveStream: true);
    }
    if (cur == null && ctrl.currentRadio == null) return const EmbedPlayer(item: null);
    if (cur == null) return _RadioVisual(name: ctrl.currentRadio!.name);
    switch (cur.type) {
      case MediaType.youtube:
      case MediaType.vimeo:
      case MediaType.dailymotion:
      case MediaType.facebook:
      case MediaType.instagram:
        return EmbedPlayer(item: cur);
      case MediaType.direct:
      case MediaType.local:
        return NativeVideoPlayer(
            url: cur.url, isLocal: cur.type == MediaType.local);
      case MediaType.radio:
        return _RadioVisual(name: cur.title);
    }
  }
}

// ── Radio visual ──────────────────────────────────────────────────────
class _RadioVisual extends StatelessWidget {
  final String name;
  const _RadioVisual({required this.name});

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.bg1,
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
              color: AppColors.bg4, borderRadius: BorderRadius.circular(32)),
          child: const Icon(Icons.radio, color: AppColors.green, size: 32)),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(name,
            style: const TextStyle(color: AppColors.text1, fontSize: 14,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis, maxLines: 2),
      ),
      const SizedBox(height: 6),
      const Text('Live Radio',
          style: TextStyle(color: AppColors.green, fontSize: 11)),
    ]),
  );
}
