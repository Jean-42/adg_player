import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tv_channel.dart';
import '../services/tv_service.dart';
import '../services/player_controller.dart';
import '../theme.dart';

class TvTab extends StatefulWidget {
  const TvTab({super.key});
  @override
  State<TvTab> createState() => _TvTabState();
}

class _TvTabState extends State<TvTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Data
  List<TvChannel> _channels    = [];
  List<String>    _countries   = [];
  List<String>    _categories  = [];

  // State
  bool   _loading      = true;
  bool   _loadingMore  = false;
  String _error        = '';
  String _search       = '';
  String _country      = '';   // empty = all
  String _category     = '';   // empty = all
  int    _limit        = 80;

  // Favorites (channel ids)
  final Set<String> _favorites = {};

  final _searchCtrl   = TextEditingController();
  final _scrollCtrl   = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load({bool retry = false}) async {
    setState(() { _loading = true; _error = ''; });
    if (retry) TvService.clearCache();
    try {
      final results = await Future.wait([
        TvService.query(
            search: _search,
            countryCode: _country,
            category: _category,
            limit: _limit),
        TvService.fetchCountryCodes(),
        TvService.fetchCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _channels   = results[0] as List<TvChannel>;
        _countries  = results[1] as List<String>;
        _categories = results[2] as List<String>;
        _loading    = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not load channels'; _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loading) return;
    setState(() { _loadingMore = true; _limit += 80; });
    try {
      final more = await TvService.query(
          search: _search,
          countryCode: _country,
          category: _category,
          limit: _limit);
      if (mounted) setState(() { _channels = more; _loadingMore = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _applyFilters() async {
    _limit = 80;
    setState(() { _loading = true; _error = ''; });
    try {
      final ch = await TvService.query(
          search: _search,
          countryCode: _country,
          category: _category,
          limit: _limit);
      if (mounted) setState(() { _channels = ch; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Filter failed'; _loading = false; });
    }
  }

  void _toggleFav(String id) =>
      setState(() => _favorites.contains(id)
          ? _favorites.remove(id)
          : _favorites.add(id));

  // Country code → flag emoji
  String _flag(String code) {
    if (code.length != 2) return '🌐';
    final base = 0x1F1E6 - 0x41;
    return String.fromCharCodes(
        [code.toUpperCase().codeUnitAt(0) + base,
         code.toUpperCase().codeUnitAt(1) + base]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ctrl = context.watch<PlayerController>();

    return Column(children: [
      _SearchBar(
        controller: _searchCtrl,
        onSearch: (v) { _search = v; _applyFilters(); },
      ),
      _FilterBar(
        countries:       _countries,
        categories:      _categories,
        selectedCountry: _country,
        selectedCat:     _category,
        flagOf:          _flag,
        onCountry: (v) { _country = v; _applyFilters(); },
        onCategory:(v) { _category = v; _applyFilters(); },
      ),
      _StatsBar(
        total:    _channels.length,
        country:  _country,
        category: _category,
        flagOf:   _flag,
      ),
      Expanded(child: _body(ctrl)),
    ]);
  }

  Widget _body(PlayerController ctrl) {
    if (_loading) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
          SizedBox(height: 12),
          Text('Loading TV channels…',
              style: TextStyle(color: AppColors.text2, fontSize: 12)),
        ]),
      );
    }

    if (_error.isNotEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off, color: AppColors.red, size: 32),
        const SizedBox(height: 8),
        Text(_error, style: const TextStyle(color: AppColors.red, fontSize: 13)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Retry'),
          onPressed: () => _load(retry: true),
        ),
      ]));
    }

    if (_channels.isEmpty) {
      return const Center(
        child: Text('No channels found',
            style: TextStyle(color: AppColors.text3, fontSize: 13)));
    }

    // Show favorites pinned at top if any match current filter
    final favChannels = _channels.where((c) => _favorites.contains(c.id)).toList();
    final otherChannels = _channels.where((c) => !_favorites.contains(c.id)).toList();
    final items = [...favChannels, ...otherChannels];

    return ListView.builder(
      controller: _scrollCtrl,
      itemCount: items.length + (_loadingMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(
                color: AppColors.accent, strokeWidth: 2)),
          );
        }
        final ch = items[i];
        final isPlaying = ctrl.currentTv?.id == ch.id;
        final isFav = _favorites.contains(ch.id);
        return _TvTile(
          channel:   ch,
          isPlaying: isPlaying,
          isFav:     isFav,
          flagOf:    _flag,
          onTap:     () => ctrl.playTv(ch),
          onFav:     () => _toggleFav(ch.id),
        );
      },
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  const _SearchBar({required this.controller, required this.onSearch});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
    child: Row(children: [
      Expanded(
        child: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.text1, fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Search TV channels…',
            prefixIcon: Icon(Icons.tv, color: AppColors.text3, size: 16),
          ),
          onSubmitted: onSearch,
        ),
      ),
      const SizedBox(width: 8),
      ElevatedButton(
        onPressed: () => onSearch(controller.text),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bg3,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Icon(Icons.search, color: AppColors.text2, size: 18),
      ),
    ]),
  );
}

// ── Filter bar ────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final List<String> countries;
  final List<String> categories;
  final String selectedCountry;
  final String selectedCat;
  final String Function(String) flagOf;
  final ValueChanged<String> onCountry;
  final ValueChanged<String> onCategory;

  const _FilterBar({
    required this.countries,
    required this.categories,
    required this.selectedCountry,
    required this.selectedCat,
    required this.flagOf,
    required this.onCountry,
    required this.onCategory,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        // Country picker
        _FilterChip(
          label: selectedCountry.isEmpty
              ? '🌐 All Countries'
              : '${flagOf(selectedCountry)} $selectedCountry',
          active: selectedCountry.isNotEmpty,
          onTap: () => _pickCountry(context),
        ),
        const SizedBox(width: 8),
        // Category picker
        _FilterChip(
          label: selectedCat.isEmpty
              ? '📺 All Categories'
              : '📺 ${_capFirst(selectedCat)}',
          active: selectedCat.isNotEmpty,
          onTap: () => _pickCategory(context),
        ),
        if (selectedCountry.isNotEmpty || selectedCat.isNotEmpty) ...[
          const SizedBox(width: 8),
          _FilterChip(
            label: '✕ Clear',
            active: false,
            isReset: true,
            onTap: () {
              onCountry('');
              onCategory('');
            },
          ),
        ],
      ],
    ),
  );

  void _pickCountry(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _PickerSheet(
        title: 'Country',
        items: ['', ...countries],
        labelOf: (c) => c.isEmpty ? '🌐 All Countries' : '${flagOf(c)} $c',
        selected: selectedCountry,
        onPick: (v) { Navigator.pop(context); onCountry(v); },
      ),
    );
  }

  void _pickCategory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _PickerSheet(
        title: 'Category',
        items: ['', ...categories],
        labelOf: (c) => c.isEmpty ? '📺 All Categories' : _capFirst(c),
        selected: selectedCat,
        onPick: (v) { Navigator.pop(context); onCategory(v); },
      ),
    );
  }

  static String _capFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final bool isReset;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.isReset = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? AppColors.accent.withOpacity(0.2)
            : isReset
                ? AppColors.red.withOpacity(0.15)
                : AppColors.bg3,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.accent : AppColors.border,
        ),
      ),
      child: Text(label,
          style: TextStyle(
              color: active
                  ? AppColors.accent2
                  : isReset
                      ? AppColors.red
                      : AppColors.text2,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    ),
  );
}

// ── Picker sheet ──────────────────────────────────────────────────────
class _PickerSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final String Function(String) labelOf;
  final String selected;
  final ValueChanged<String> onPick;
  const _PickerSheet({
    required this.title,
    required this.items,
    required this.labelOf,
    required this.selected,
    required this.onPick,
  });
  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String _filter = '';
  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where((i) => widget.labelOf(i).toLowerCase().contains(_filter.toLowerCase()))
        .toList();
    return Column(children: [
      const SizedBox(height: 12),
      Text(widget.title,
          style: const TextStyle(color: AppColors.text1, fontSize: 14,
              fontWeight: FontWeight.w600)),
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          autofocus: true,
          style: const TextStyle(color: AppColors.text1, fontSize: 13),
          decoration: const InputDecoration(hintText: 'Filter…'),
          onChanged: (v) => setState(() => _filter = v),
        ),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final item = filtered[i];
            final label = widget.labelOf(item);
            final sel = item == widget.selected;
            return ListTile(
              dense: true,
              onTap: () => widget.onPick(item),
              title: Text(label,
                  style: TextStyle(
                      color: sel ? AppColors.accent2 : AppColors.text1,
                      fontSize: 13)),
              trailing: sel
                  ? const Icon(Icons.check, color: AppColors.accent, size: 16)
                  : null,
            );
          },
        ),
      ),
    ]);
  }
}

// ── Stats bar ─────────────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final int total;
  final String country;
  final String category;
  final String Function(String) flagOf;
  const _StatsBar({
    required this.total,
    required this.country,
    required this.category,
    required this.flagOf,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>['$total channels'];
    if (country.isNotEmpty) parts.add('${flagOf(country)} $country');
    if (category.isNotEmpty) parts.add(category);

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      alignment: Alignment.centerLeft,
      child: Text(parts.join(' · '),
          style: const TextStyle(color: AppColors.text3, fontSize: 11)),
    );
  }
}

// ── Channel tile ──────────────────────────────────────────────────────
class _TvTile extends StatelessWidget {
  final TvChannel channel;
  final bool isPlaying;
  final bool isFav;
  final String Function(String) flagOf;
  final VoidCallback onTap;
  final VoidCallback onFav;

  const _TvTile({
    required this.channel,
    required this.isPlaying,
    required this.isFav,
    required this.flagOf,
    required this.onTap,
    required this.onFav,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: isPlaying ? AppColors.bg3 : Colors.transparent,
      border: Border(
        left: BorderSide(
            color: isPlaying ? AppColors.accent : Colors.transparent, width: 2),
        bottom: const BorderSide(color: AppColors.border),
      ),
    ),
    child: ListTile(
      dense: true,
      onTap: onTap,
      leading: _Logo(url: channel.logo, flag: flagOf(channel.countryCode)),
      title: Text(channel.name,
          style: const TextStyle(color: AppColors.text1, fontSize: 13),
          overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          if (channel.countryCode.isNotEmpty)
            '${flagOf(channel.countryCode)} ${channel.countryCode}',
          if (channel.categoryLabel.isNotEmpty) channel.categoryLabel,
          if (channel.languageLabel.isNotEmpty) channel.languageLabel,
        ].join(' · '),
        style: const TextStyle(color: AppColors.text3, fontSize: 11),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (isPlaying)
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: _LiveBadge(),
          ),
        GestureDetector(
          onTap: onFav,
          child: Icon(
            isFav ? Icons.star : Icons.star_border,
            color: isFav ? AppColors.yellow : AppColors.text3,
            size: 18,
          ),
        ),
      ]),
    ),
  );
}

class _Logo extends StatelessWidget {
  final String url;
  final String flag;
  const _Logo({required this.url, required this.flag});

  @override
  Widget build(BuildContext context) => Container(
    width: 36, height: 36,
    decoration: BoxDecoration(
        color: AppColors.bg4, borderRadius: BorderRadius.circular(8)),
    child: url.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(url, width: 36, height: 36, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _fallback()))
        : _fallback(),
  );

  Widget _fallback() => Center(
    child: Text(flag, style: const TextStyle(fontSize: 18)),
  );
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.red,
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Text('LIVE',
        style: TextStyle(color: Colors.white, fontSize: 9,
            fontWeight: FontWeight.w800, letterSpacing: 0.5)),
  );
}
