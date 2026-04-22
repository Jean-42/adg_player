import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/player_controller.dart';
import '../services/url_parser.dart';
import '../models/queue_item.dart';
import '../widgets/toast.dart';
import '../theme.dart';

class AddTab extends StatefulWidget {
  const AddTab({super.key});

  @override
  State<AddTab> createState() => _AddTabState();
}

class _AddTabState extends State<AddTab> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  final _ytCtrl   = TextEditingController();
  final _viCtrl   = TextEditingController();
  final _dmCtrl   = TextEditingController();
  final _fbCtrl   = TextEditingController();
  final _igCtrl   = TextEditingController();
  final _urlCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [_ytCtrl, _viCtrl, _dmCtrl, _fbCtrl, _igCtrl, _urlCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _play(QueueItem? item) async {
    if (item == null) {
      showToast(context, 'Invalid URL or ID', type: ToastType.error);
      return;
    }
    final ctrl = context.read<PlayerController>();
    // Remove duplicate if same id exists, then set as current
    ctrl.queue.removeWhere((q) => q.id == item.id);
    ctrl.queue.insert(0, item);
    await ctrl.playItem(0);
    showToast(context, 'Playing: ${item.subtitle}', type: ToastType.success);
  }

  void _add(QueueItem? item) {
    if (item == null) {
      showToast(context, 'Invalid URL or ID', type: ToastType.error);
      return;
    }
    context.read<PlayerController>().addToQueue(item);
    showToast(context, 'Added to queue', type: ToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Platform tabs
        Container(
          color: AppColors.bg1,
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent2,
            unselectedLabelColor: AppColors.text3,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'YouTube'),
              Tab(text: 'Vimeo'),
              Tab(text: 'Dailymotion'),
              Tab(text: 'Facebook'),
              Tab(text: 'Instagram'),
              Tab(text: 'URL'),
              Tab(text: 'Local'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _PlatformPane(
                ctrl: _ytCtrl,
                hint: 'YouTube URL or video ID…',
                onPlay: () => _play(UrlParser.buildYouTube(_ytCtrl.text)),
                onAdd:  () => _add(UrlParser.buildYouTube(_ytCtrl.text)),
                playColor: AppColors.youtube,
                icon: Icons.smart_display,
              ),
              _PlatformPane(
                ctrl: _viCtrl,
                hint: 'Vimeo URL or video ID…',
                onPlay: () => _play(UrlParser.buildVimeo(_viCtrl.text)),
                onAdd:  () => _add(UrlParser.buildVimeo(_viCtrl.text)),
                playColor: AppColors.vimeo,
                icon: Icons.play_circle_filled,
              ),
              _PlatformPane(
                ctrl: _dmCtrl,
                hint: 'Dailymotion URL or video ID…',
                onPlay: () => _play(UrlParser.buildDailymotion(_dmCtrl.text)),
                onAdd:  () => _add(UrlParser.buildDailymotion(_dmCtrl.text)),
                playColor: AppColors.dailymotion,
                icon: Icons.play_arrow,
              ),
              _PlatformPane(
                ctrl: _fbCtrl,
                hint: 'Facebook video or Reel URL…',
                onPlay: () => _play(UrlParser.buildFacebook(_fbCtrl.text)),
                onAdd:  () => _add(UrlParser.buildFacebook(_fbCtrl.text)),
                playColor: AppColors.facebook,
                icon: Icons.thumb_up,
                note: 'May require Facebook login',
              ),
              _PlatformPane(
                ctrl: _igCtrl,
                hint: 'Instagram post or Reel URL…',
                onPlay: () => _play(UrlParser.buildInstagram(_igCtrl.text)),
                onAdd:  () => _add(UrlParser.buildInstagram(_igCtrl.text)),
                playColor: AppColors.instagram,
                icon: Icons.camera_alt,
              ),
              _PlatformPane(
                ctrl: _urlCtrl,
                hint: 'Direct video/audio URL (MP4, MP3…)',
                onPlay: () => _play(UrlParser.buildDirect(_urlCtrl.text)),
                onAdd:  () => _add(UrlParser.buildDirect(_urlCtrl.text)),
                playColor: AppColors.green,
                icon: Icons.link,
              ),
              _LocalPane(onPlay: _play, onAdd: _add),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Reusable pane for embed platforms and direct URL ──────────────────

class _PlatformPane extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final VoidCallback onPlay;
  final VoidCallback onAdd;
  final Color playColor;
  final IconData icon;
  final String? note;

  const _PlatformPane({
    required this.ctrl,
    required this.hint,
    required this.onPlay,
    required this.onAdd,
    required this.playColor,
    required this.icon,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: ctrl,
            style: const TextStyle(color: AppColors.text1, fontSize: 13),
            decoration: InputDecoration(hintText: hint),
            onSubmitted: (_) => onPlay(),
          ),
          if (note != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 12, color: AppColors.text3),
                const SizedBox(width: 4),
                Text(note!,
                    style: const TextStyle(
                        color: AppColors.text3, fontSize: 11)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPlay,
                  icon: Icon(icon, size: 15),
                  label: const Text('Play'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: playColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onAdd,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text2,
                  side: const BorderSide(color: AppColors.border2),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Icon(Icons.add, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Local file picker pane ────────────────────────────────────────────

class _LocalPane extends StatefulWidget {
  final void Function(QueueItem?) onPlay;
  final void Function(QueueItem?) onAdd;

  const _LocalPane({required this.onPlay, required this.onAdd});

  @override
  State<_LocalPane> createState() => _LocalPaneState();
}

class _LocalPaneState extends State<_LocalPane> {
  List<PlatformFile> _picked = [];

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'mp4','mkv','avi','mov','webm','flv','wmv',
        'mp3','aac','flac','ogg','wav','m4a',
      ],
      allowMultiple: true,
    );
    if (res != null) setState(() => _picked = res.files);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _pick,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border2),
              ),
              child: Column(
                children: [
                  const Icon(Icons.folder_open,
                      color: AppColors.accent2, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    _picked.isEmpty
                        ? 'Tap to browse files'
                        : '${_picked.length} file(s) selected',
                    style: const TextStyle(
                        color: AppColors.text2, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          if (_picked.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._picked.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(f.name,
                      style: const TextStyle(
                          color: AppColors.text3, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                )),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _picked.isEmpty
                      ? null
                      : () {
                          final f = _picked.first;
                          widget.onPlay(UrlParser.buildLocal(
                              f.path ?? f.name, f.name));
                        },
                  icon: const Icon(Icons.folder_open, size: 15),
                  label: const Text('Play First'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _picked.isEmpty
                    ? null
                    : () {
                        for (final f in _picked) {
                          widget.onAdd(UrlParser.buildLocal(
                              f.path ?? f.name, f.name));
                        }
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text2,
                  side: const BorderSide(color: AppColors.border2),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Add All',
                    style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
