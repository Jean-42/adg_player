import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_controller.dart';
import '../models/queue_item.dart';
import '../theme.dart';
import 'platform_icon.dart';

class MiniControls extends StatelessWidget {
  const MiniControls({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl  = context.watch<PlayerController>();
    final cur   = ctrl.current;
    final radio = ctrl.currentRadio;

    final isActive = cur != null || radio != null;
    final isEmbed  = cur?.isEmbed ?? false;
    final isAudio  = !isEmbed && (cur?.type == MediaType.direct ||
                                   cur?.type == MediaType.local ||
                                   radio != null);

    final title    = cur?.title ?? radio?.name ?? 'No media loaded';
    final subtitle = cur?.subtitle ??
        (radio != null ? '${radio.country} · Radio' : 'ADG Media Player');

    final progress = (isAudio && ctrl.audioDuration.inMilliseconds > 0)
        ? (ctrl.audioPosition.inMilliseconds /
               ctrl.audioDuration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    // Check if there's a saved resume position for current item
    final savedPos = cur != null ? ctrl.getSavedPosition(cur.id) : null;
    final showResume = savedPos != null && !isAudio;

    return Container(
      color: AppColors.bg2,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Seek bar — native audio only
        if (isAudio && isActive)
          GestureDetector(
            onTapDown: (d) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              ctrl.seekAudio(
                  (d.localPosition.dx / box.size.width).clamp(0.0, 1.0));
            },
            child: SizedBox(
              height: 3,
              child: Stack(children: [
                Container(color: AppColors.bg4),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(color: AppColors.accent),
                ),
              ]),
            ),
          ),

        // Embed hint
        if (isEmbed && isActive)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3),
            color: AppColors.bg3,
            child: const Text(
              'Use controls inside the video to play, pause & seek',
              style: TextStyle(color: AppColors.text3, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),

        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Title row
            Row(children: [
              if (cur != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: PlatformIcon(type: cur.type, size: 12),
                ),
              Expanded(
                child: Text(title,
                    style: const TextStyle(color: AppColors.text1,
                        fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
              // Time display
              if (isAudio && ctrl.audioDuration > Duration.zero)
                Text(
                  '${_fmt(ctrl.audioPosition)} / ${_fmt(ctrl.audioDuration)}',
                  style: const TextStyle(color: AppColors.text3, fontSize: 10),
                ),
            ]),

            Text(subtitle,
                style: const TextStyle(color: AppColors.text3, fontSize: 10),
                overflow: TextOverflow.ellipsis),

            // Resume banner — shown when there's a saved position
            if (showResume)
              GestureDetector(
                onTap: () {
                  // Clear so it doesn't show again after user acknowledges
                  ctrl.clearSavedPosition(cur!.id);
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.history,
                        color: AppColors.accent2, size: 11),
                    const SizedBox(width: 4),
                    Text(
                      'Last played at ${_fmt(savedPos!)} — tap to dismiss',
                      style: const TextStyle(
                          color: AppColors.accent2, fontSize: 10),
                    ),
                  ]),
                ),
              ),

            const SizedBox(height: 4),

            // Controls row
            Row(children: [
              _ctrl(Icons.skip_previous,
                  () => ctrl.playPrev(), active: isActive),
              const SizedBox(width: 2),
              _playBtn(ctrl, isEmbed, isActive, isAudio),
              const SizedBox(width: 2),
              _ctrl(Icons.skip_next,
                  () => ctrl.playNext(), active: isActive),
              const Spacer(),
              _repeatBtn(ctrl),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _ctrl(IconData icon, VoidCallback onTap, {bool active = true}) =>
      InkWell(
        onTap: active ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon,
              color: active ? AppColors.text2 : AppColors.text3, size: 20),
        ),
      );

  Widget _playBtn(PlayerController ctrl, bool isEmbed,
      bool isActive, bool isAudio) {
    if (!isAudio || !isActive) {
      return Opacity(
        opacity: isEmbed ? 0.35 : 1.0,
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
        ),
      );
    }
    return InkWell(
      onTap: () => ctrl.toggleAudio(),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(8)),
        child: Icon(
            ctrl.isAudioPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white, size: 18),
      ),
    );
  }

  Widget _repeatBtn(PlayerController ctrl) {
    Color color;
    if (ctrl.repeatMode == PlayerRepeatMode.one) {
      color = AppColors.accent2;
    } else if (ctrl.repeatMode == PlayerRepeatMode.all) {
      color = AppColors.green;
    } else {
      color = AppColors.text3;
    }
    return InkWell(
      onTap: () => ctrl.cycleRepeat(),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          ctrl.repeatMode == PlayerRepeatMode.one
              ? Icons.repeat_one : Icons.repeat,
          color: color, size: 18,
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
