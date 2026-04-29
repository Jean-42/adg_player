import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_controller.dart';
import '../theme.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PlayerController>();

    return ListView(
      children: [
        _Section(
          label: 'Playback',
          children: [
            _SettingRow(
              name: 'Autoplay next in queue',
              value: ctrl.autoplayNext,
              onToggle: () => ctrl.toggleAutoplay(),
            ),
          ],
        ),
        _Section(
          label: 'About',
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ADG Media Player v1.0.0',
                      style: TextStyle(
                          color: AppColors.text2, fontSize: 13)),
                  SizedBox(height: 4),
                  Text(
                    'YouTube · Vimeo · Dailymotion\n'
                    'Facebook · Instagram · Direct URLs\n'
                    'Local Files · Internet Radio',
                    style: TextStyle(
                        color: AppColors.text3,
                        fontSize: 12,
                        height: 1.7),
                  ),
                ],
              ),
            ),
          ],
        ),
        _Section(
          label: 'Supported Platforms',
          children: [
            _PlatformRow(
                icon: Icons.smart_display,
                color: AppColors.youtube,
                name: 'YouTube',
                note: 'youtube-nocookie embed'),
            _PlatformRow(
                icon: Icons.play_circle_filled,
                color: AppColors.vimeo,
                name: 'Vimeo',
                note: 'Vimeo player embed'),
            _PlatformRow(
                icon: Icons.play_arrow,
                color: AppColors.dailymotion,
                name: 'Dailymotion',
                note: 'Dailymotion player embed'),
            _PlatformRow(
                icon: Icons.thumb_up,
                color: AppColors.facebook,
                name: 'Facebook / Reels',
                note: 'Requires FB login in some cases'),
            _PlatformRow(
                icon: Icons.camera_alt,
                color: AppColors.instagram,
                name: 'Instagram',
                note: 'Public posts only'),
            _PlatformRow(
                icon: Icons.link,
                color: AppColors.green,
                name: 'Direct URL',
                note: 'MP4, WebM, MP3, AAC…'),
            _PlatformRow(
                icon: Icons.folder_open,
                color: AppColors.yellow,
                name: 'Local Files',
                note: 'From device storage'),
            _PlatformRow(
                icon: Icons.radio,
                color: AppColors.green,
                name: 'Internet Radio',
                note: 'Powered by Radio Browser API'),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _Section({required this.label, required this.children});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Text(label.toUpperCase(),
                style: const TextStyle(
                    color: AppColors.text3,
                    fontSize: 10,
                    letterSpacing: 0.5)),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border.symmetric(
                  horizontal:
                      BorderSide(color: AppColors.border)),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14),
              child: Column(children: children),
            ),
          ),
        ],
      );
}

class _SettingRow extends StatelessWidget {
  final String name;
  final bool value;
  final VoidCallback onToggle;

  const _SettingRow({
    required this.name,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name,
                style: const TextStyle(
                    color: AppColors.text2, fontSize: 13)),
            Switch(
              value: value,
              onChanged: (_) => onToggle(),
              activeColor: AppColors.accent,
              trackColor:
                  WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.accent.withValues(alpha: 0.4);
                }
                return AppColors.bg4;
              }),
            ),
          ],
        ),
      );
}

class _PlatformRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;
  final String note;

  const _PlatformRow({
    required this.icon,
    required this.color,
    required this.name,
    required this.note,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 10),
            Text(name,
                style: const TextStyle(
                    color: AppColors.text2, fontSize: 13)),
            const Spacer(),
            Text(note,
                style: const TextStyle(
                    color: AppColors.text3, fontSize: 11)),
          ],
        ),
      );
}
