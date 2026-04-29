import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_controller.dart';
import '../widgets/platform_icon.dart';
import '../widgets/toast.dart';
import '../theme.dart';

class QueueTab extends StatelessWidget {
  const QueueTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PlayerController>();
    final queue = ctrl.queue;

    return Column(
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          decoration: const BoxDecoration(
            color: AppColors.bg1,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              const Icon(Icons.queue_music,
                  color: AppColors.accent2, size: 16),
              const SizedBox(width: 6),
              const Text('Queue',
                  style: TextStyle(
                      color: AppColors.text2,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.bg3,
                    borderRadius: BorderRadius.circular(8)),
                child: Text('${queue.length}',
                    style: const TextStyle(
                        color: AppColors.text3, fontSize: 11)),
              ),
              const Spacer(),
              _iconBtn(Icons.shuffle, () {
                ctrl.shuffleQueue();
                showToast(context, 'Shuffled', type: ToastType.success);
              }),
              _iconBtn(Icons.delete_outline, () {
                if (queue.isEmpty) return;
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppColors.bg2,
                    title: const Text('Clear queue?',
                        style: TextStyle(color: AppColors.text1)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel',
                              style:
                                  TextStyle(color: AppColors.text3))),
                      TextButton(
                          onPressed: () {
                            ctrl.clearQueue();
                            Navigator.pop(context);
                          },
                          child: const Text('Clear',
                              style: TextStyle(color: AppColors.red))),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        // List
        Expanded(
          child: queue.isEmpty
              ? _empty()
              : ReorderableListView.builder(
                  itemCount: queue.length,
                  onReorder: (oldIdx, newIdx) {
                    if (newIdx > oldIdx) newIdx--;
                    final item = queue.removeAt(oldIdx);
                    queue.insert(newIdx, item);
                    // fix current index
                    if (ctrl.queueIndex == oldIdx) {
                      // ignore: invalid_use_of_protected_member
                      ctrl.notifyListeners();
                    }
                  },
                  itemBuilder: (ctx, i) {
                    final item = queue[i];
                    final isCurrent = ctrl.queueIndex == i;
                    return _QueueTile(
                      key: ValueKey(item.id),
                      item: item,
                      isCurrent: isCurrent,
                      index: i,
                      onPlay: () => ctrl.playItem(i),
                      onRemove: () => ctrl.removeFromQueue(i),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: AppColors.text3, size: 18),
        ),
      );

  Widget _empty() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.3,
              child: Icon(Icons.music_note,
                  color: AppColors.text2, size: 40),
            ),
            SizedBox(height: 8),
            Text('Queue is empty',
                style: TextStyle(color: AppColors.text3, fontSize: 13)),
          ],
        ),
      );
}

class _QueueTile extends StatelessWidget {
  final dynamic item;
  final bool isCurrent;
  final int index;
  final VoidCallback onPlay;
  final VoidCallback onRemove;

  const _QueueTile({
    super.key,
    required this.item,
    required this.isCurrent,
    required this.index,
    required this.onPlay,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.bg3 : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: isCurrent ? AppColors.accent2 : Colors.transparent,
            width: 2,
          ),
          bottom: const BorderSide(color: AppColors.border),
        ),
      ),
      child: ListTile(
        dense: true,
        onTap: onPlay,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: AppColors.bg4,
              borderRadius: BorderRadius.circular(7)),
          child: Center(
              child: PlatformIcon(type: item.type, size: 14)),
        ),
        title: Text(item.title,
            style: const TextStyle(
                color: AppColors.text1, fontSize: 13),
            overflow: TextOverflow.ellipsis),
        subtitle: Text(item.platformLabel,
            style: const TextStyle(
                color: AppColors.text3, fontSize: 11)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrent)
              const Icon(Icons.volume_up,
                  color: AppColors.green, size: 14),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close,
                    color: AppColors.text3, size: 16),
              ),
            ),
            const Icon(Icons.drag_handle,
                color: AppColors.text3, size: 18),
          ],
        ),
      ),
    );
  }
}
