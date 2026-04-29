import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/player_controller.dart';
import '../models/queue_item.dart';
import '../theme.dart';
import '../widgets/toast.dart';

class DownloadTab extends StatefulWidget {
  const DownloadTab({super.key});
  @override
  State<DownloadTab> createState() => _DownloadTabState();
}

class _DownloadTabState extends State<DownloadTab> {
  String _format  = 'mp4';
  String _quality = 'best';

  // ── Open in external app (browser / yt-dlp GUI / share) ───────────
  Future<void> _openExternal(QueueItem item) async {
    final uri = Uri.parse(item.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) showToast(context, 'Cannot open URL', type: ToastType.error);
    }
  }

  // ── Share via Android share sheet ─────────────────────────────────
  Future<void> _share(QueueItem item) async {
    // Use the Share intent approach via url_launcher
    final uri = Uri.parse(item.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Try to launch yt-dlp or ytdl-patito deeplinks ─────────────────
  Future<void> _tryYtdlpApp(QueueItem item) async {
    // Common Android yt-dlp front-end deep link schemes
    final schemes = [
      'ytdlp://download?url=${Uri.encodeComponent(item.url)}&format=$_format&quality=$_quality',
      'dvd://download?url=${Uri.encodeComponent(item.url)}',
      'newpipe://download?url=${Uri.encodeComponent(item.url)}',
    ];

    bool launched = false;
    for (final s in schemes) {
      try {
        final uri = Uri.parse(s);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          launched = true;
          break;
        }
      } catch (_) {}
    }

    if (!launched && mounted) {
      _showNoYtdlpDialog(item);
    }
  }

  void _showNoYtdlpDialog(QueueItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Download Options',
            style: TextStyle(color: AppColors.text1, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To download videos on Android, install one of these apps:',
              style: TextStyle(color: AppColors.text2, fontSize: 13),
            ),
            const SizedBox(height: 14),
            _appOption('NewPipe', 'Free YouTube client with download',
                'https://newpipe.net', item),
            const SizedBox(height: 8),
            _appOption('Seal', 'yt-dlp front-end for Android',
                'https://github.com/JunkFood02/Seal/releases', item),
            const SizedBox(height: 8),
            _appOption('YTDLnis', 'yt-dlp GUI for Android',
                'https://ytdlnis.com', item),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.text3)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openExternal(item);
            },
            child: const Text('Open in Browser',
                style: TextStyle(color: AppColors.accent2)),
          ),
        ],
      ),
    );
  }

  Widget _appOption(String name, String desc, String url, QueueItem item) =>
      InkWell(
        onTap: () async {
          Navigator.pop(context);
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.bg3,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            const Icon(Icons.download, color: AppColors.accent2, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(
                    color: AppColors.text1, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(desc, style: const TextStyle(color: AppColors.text3, fontSize: 11)),
              ],
            )),
            const Icon(Icons.open_in_new, color: AppColors.text3, size: 13),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PlayerController>();
    final cur  = ctrl.current;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Current video info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border2),
          ),
          child: cur == null
              ? const Row(children: [
                  Icon(Icons.info_outline, color: AppColors.text3, size: 16),
                  SizedBox(width: 8),
                  Text('Load a video first to download it',
                      style: TextStyle(color: AppColors.text3, fontSize: 13)),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    _platformDot(cur.type),
                    const SizedBox(width: 8),
                    Expanded(child: Text(cur.title,
                        style: const TextStyle(color: AppColors.text1,
                            fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 4),
                  Text(cur.url,
                      style: const TextStyle(color: AppColors.text3, fontSize: 10),
                      overflow: TextOverflow.ellipsis, maxLines: 2),
                ]),
        ),

        const SizedBox(height: 14),

        // Format selector
        const Text('FORMAT', style: TextStyle(color: AppColors.text3,
            fontSize: 10, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Row(children: [
          _formatChip('mp4', 'Video (MP4)', Icons.videocam),
          const SizedBox(width: 8),
          _formatChip('mp3', 'Audio (MP3)', Icons.music_note),
        ]),

        const SizedBox(height: 14),

        // Quality selector
        const Text('QUALITY', style: TextStyle(color: AppColors.text3,
            fontSize: 10, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _qualityChip('best', 'Best'),
          _qualityChip('1080p', '1080p'),
          _qualityChip('720p', '720p'),
          _qualityChip('480p', '480p'),
        ]),

        const SizedBox(height: 18),

        // Download button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: cur == null ? null : () => _tryYtdlpApp(cur),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download', style: TextStyle(fontSize: 15,
                fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.bg4,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Share / Open button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: cur == null ? null : () => _openExternal(cur),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open in Browser', style: TextStyle(fontSize: 14)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text2,
              side: const BorderSide(color: AppColors.border2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Info box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.info_outline, color: AppColors.accent2, size: 15),
              SizedBox(width: 6),
              Text('How downloads work on Android',
                  style: TextStyle(color: AppColors.text1, fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 10),
            _infoRow(Icons.phone_android, 'Tap Download to launch a compatible downloader app (Seal, YTDLnis, NewPipe)'),
            const SizedBox(height: 6),
            _infoRow(Icons.download_for_offline, 'If no downloader is installed, you\'ll be guided to install one'),
            const SizedBox(height: 6),
            _infoRow(Icons.open_in_browser, 'Or use "Open in Browser" to access the video page directly'),
            const SizedBox(height: 6),
            _infoRow(Icons.laptop, 'For full yt-dlp downloads, use the Windows desktop app'),
          ]),
        ),
      ],
    );
  }

  Widget _platformDot(MediaType type) {
    Color color;
    switch (type) {
      case MediaType.youtube:     color = AppColors.youtube; break;
      case MediaType.vimeo:       color = AppColors.vimeo; break;
      case MediaType.dailymotion: color = AppColors.dailymotion; break;
      case MediaType.facebook:    color = AppColors.facebook; break;
      case MediaType.instagram:   color = AppColors.instagram; break;
      default:                    color = AppColors.green; break;
    }
    return Container(width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }

  Widget _formatChip(String val, String label, IconData icon) {
    final active = _format == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _format = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : AppColors.bg3,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? AppColors.accent : AppColors.border2),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 15, color: active ? Colors.white : AppColors.text2),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.text2)),
          ]),
        ),
      ),
    );
  }

  Widget _qualityChip(String val, String label) {
    final active = _quality == val;
    return GestureDetector(
      onTap: () => setState(() => _quality = val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.bg3,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.accent : AppColors.border2),
        ),
        child: Text(label, style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.text2)),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 13, color: AppColors.text3),
      const SizedBox(width: 8),
      Expanded(child: Text(text,
          style: const TextStyle(color: AppColors.text3, fontSize: 12, height: 1.4))),
    ],
  );
}
