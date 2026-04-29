import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_controller.dart';
import '../services/radio_service.dart';
import '../models/radio_station.dart';
import '../theme.dart';

class RadioTab extends StatefulWidget {
  const RadioTab({super.key});

  @override
  State<RadioTab> createState() => _RadioTabState();
}

class _RadioTabState extends State<RadioTab>
    with AutomaticKeepAliveClientMixin {
  List<RadioStation> _stations = [];
  bool _loading = true;
  String _error = '';
  final _searchCtrl = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch([String query = '']) async {
    setState(() { _loading = true; _error = ''; });
    try {
      final results = query.isEmpty
          ? await RadioService.fetchTop()
          : await RadioService.search(query);
      if (mounted) setState(() { _stations = results; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load stations';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ctrl = context.watch<PlayerController>();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(
                      color: AppColors.text1, fontSize: 13),
                  decoration: const InputDecoration(
                      hintText: 'Search radio stations…'),
                  onSubmitted: (v) => _fetch(v),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _fetch(_searchCtrl.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bg3,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Icon(Icons.search,
                    color: AppColors.text2, size: 18),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.accent, strokeWidth: 2))
              : _error.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off,
                              color: AppColors.red, size: 32),
                          const SizedBox(height: 8),
                          Text(_error,
                              style: const TextStyle(
                                  color: AppColors.red,
                                  fontSize: 13)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () =>
                                _fetch(_searchCtrl.text),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _stations.isEmpty
                      ? const Center(
                          child: Text('No stations found',
                              style: TextStyle(
                                  color: AppColors.text3,
                                  fontSize: 13)),
                        )
                      : ListView.builder(
                          itemCount: _stations.length,
                          itemBuilder: (ctx, i) {
                            final s = _stations[i];
                            final isPlaying =
                                ctrl.currentRadio?.stationuuid ==
                                    s.stationuuid;
                            return _RadioTile(
                              station: s,
                              isPlaying: isPlaying,
                              onTap: () =>
                                  ctrl.playRadio(s),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

class _RadioTile extends StatelessWidget {
  final RadioStation station;
  final bool isPlaying;
  final VoidCallback onTap;

  const _RadioTile({
    required this.station,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isPlaying ? AppColors.bg3 : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: isPlaying ? AppColors.green : Colors.transparent,
            width: 2,
          ),
          bottom: const BorderSide(color: AppColors.border),
        ),
      ),
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: _favicon(),
        title: Text(station.name,
            style: const TextStyle(
                color: AppColors.text1, fontSize: 13),
            overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            if (station.country.isNotEmpty) station.country,
            if (station.bitrate > 0) '${station.bitrate}kbps',
            if (station.firstTag.isNotEmpty) station.firstTag,
          ].join(' · '),
          style: const TextStyle(
              color: AppColors.text3, fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isPlaying
            ? const Icon(Icons.volume_up,
                color: AppColors.green, size: 16)
            : null,
      ),
    );
  }

  Widget _favicon() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
          color: AppColors.bg4,
          borderRadius: BorderRadius.circular(7)),
      child: station.favicon.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.network(
                station.favicon,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.radio,
                    color: AppColors.green, size: 16),
              ),
            )
          : const Icon(Icons.radio, color: AppColors.green, size: 16),
    );
  }
}
