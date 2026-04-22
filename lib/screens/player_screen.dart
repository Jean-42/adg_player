import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/player_controller.dart';
import '../models/queue_item.dart';
import '../widgets/embed_player.dart';
import '../widgets/native_video_player.dart';
import '../theme.dart';

class PlayerSection extends StatelessWidget {
  const PlayerSection({super.key});

    @override
  Widget build(BuildContext context) {
    final ctrl       = context.watch<PlayerController>();
    final cur        = ctrl.current;
    final screenW    = MediaQuery.of(context).size.width;
    final isPortrait = cur?.isPortraitVideo ?? false;

    if (isPortrait) {
      final maxW = screenW * 0.60;
      final h    = (maxW * 16 / 9).clamp(200.0, 300.0);
      return Container(
        color: Colors.black,
        width: double.infinity,
        height: h,
        child: Center(
          child: SizedBox(
            width: maxW, height: h,
            child: _buildPlayer(ctrl, cur),
          ),
        ),
      );
    }

    final playerH = (screenW * 9 / 16).clamp(200.0, 280.0);
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: playerH,
      child: Stack(children: [
        _buildPlayer(ctrl, cur),
        // Fullscreen button overlay — bottom right corner
        if (cur != null)
          Positioned(
            bottom: 8, right: 8,
            child: _FullscreenBtn(),
          ),
      ]),
    );
  }

  Widget _buildPlayer(PlayerController ctrl, QueueItem? cur) {
    if (cur == null && ctrl.currentRadio == null) return const EmbedPlayer(item: null);
    if (cur == null) return _RadioVisual(name: ctrl.currentRadio!.name);
    switch (cur.type) {
      case MediaType.youtube:
        // YouTube: Show simple info, audio plays in background via audio_service
        return _YouTubeAudioVisual(title: cur.title, subtitle: cur.subtitle);
      case MediaType.vimeo:
      case MediaType.dailymotion:
      case MediaType.facebook:
      case MediaType.instagram:
        return EmbedPlayer(item: cur);
      case MediaType.direct:
      case MediaType.local:
        return NativeVideoPlayer(url: cur.url, isLocal: cur.type == MediaType.local);
      case MediaType.radio:
        return _RadioVisual(name: cur.title);
    }
  }
}

// ── Fullscreen button ─────────────────────────────────────────────────
class _FullscreenBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<PlayerController>().enterFullscreen(),
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white24),
        ),
        child: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
      ),
    );
  }
}

// ── Fullscreen overlay — covers entire screen ─────────────────────────
class FullscreenPlayer extends StatefulWidget {
  const FullscreenPlayer({super.key});
  @override
  State<FullscreenPlayer> createState() => _FullscreenPlayerState();
}

class _FullscreenPlayerState extends State<FullscreenPlayer> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    // Hide status bar + nav bar for true fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Auto-hide controls after 3s
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  @override
  void dispose() {
    // Restore UI when leaving fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _exit(BuildContext context) {
    context.read<PlayerController>().exitFullscreen();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PlayerController>();
    final cur  = ctrl.current;

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          // Full screen player
          Positioned.fill(
            child: cur == null
                ? const Center(child: Icon(Icons.play_circle_outline,
                    color: AppColors.accent2, size: 48))
                : cur.isEmbed
                    ? EmbedPlayer(item: cur, fullscreen: true)
                    : NativeVideoPlayer(
                        url: cur.url,
                        isLocal: cur.type == MediaType.local),
          ),

          // Controls overlay
          if (_showControls) ...[
            // Top bar with exit button
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12, right: 12, bottom: 12,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => _exit(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.fullscreen_exit,
                            color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text('Exit Fullscreen',
                            style: TextStyle(color: Colors.white,
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                  const Spacer(),
                  // Title
                  if (cur != null)
                    Flexible(child: Text(cur.title,
                        style: const TextStyle(color: Colors.white70,
                            fontSize: 12),
                        overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ),

            // Bottom bar with prev/next
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                  left: 16, right: 16, top: 16,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _fsBtn(Icons.skip_previous, () => ctrl.playPrev()),
                    const SizedBox(width: 24),
                    _fsBtn(Icons.skip_next, () => ctrl.playNext()),
                  ],
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _fsBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    ),
  );
}

class _RadioVisual extends StatelessWidget {
  final String name;
  const _RadioVisual({required this.name});

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.bg1,
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 64, height: 64,
        decoration: BoxDecoration(
            color: AppColors.bg4,
            borderRadius: BorderRadius.circular(32)),
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

// ── YouTube Audio Visual ─────────────────────────────────────────────
class _YouTubeAudioVisual extends StatelessWidget {
  final String title;
  final String subtitle;
  const _YouTubeAudioVisual({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.bg1,
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: AppColors.bg4,
          borderRadius: BorderRadius.circular(40),
        ),
        child: const Icon(Icons.play_circle, color: Color(0xFFFF0000), size: 48),
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.text1,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.green,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 16),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Playing audio in background...',
          style: TextStyle(color: AppColors.text3, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    ]),
  );
}