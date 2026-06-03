import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/cached_inventory_item.dart';
import 'package:brick_collector/model/cached_source.dart';
import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/services/collection_sync_service.dart';
import 'package:brick_collector/services/part_image_resolver.dart';
import 'package:brick_collector/ui/back_button.dart';
import 'package:brick_collector/ui/modals/sync_progress_modal.dart';
import 'package:brick_collector/ui/smart_part_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class PartSummaryScreen extends StatefulWidget {
  final CollectablePart part;

  /// Initial color filter. `null` means "show all colors". A singleton set
  /// behaves like the legacy "this color only" mode; a multi-element set is
  /// used when arriving from a preset card so we only show the colors the
  /// preset actually filtered on.
  final Set<int>? initialColorIds;

  const PartSummaryScreen(this.part, {this.initialColorIds, super.key});

  @override
  State<StatefulWidget> createState() => _PartSummaryScreenState();
}

class _SourceRow {
  _SourceRow(this.source, this.items);
  final CachedSource source;
  final List<CachedInventoryItem> items;

  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);
}

class _PartSummaryScreenState extends State<PartSummaryScreen> {
  late Set<int>? _filterColorIds = widget.initialColorIds == null
      ? null
      : Set<int>.from(widget.initialColorIds!);

  /// What to restore when the user toggles the filter chip back on after
  /// expanding to all colors. Updated whenever the active filter changes
  /// (e.g. user drills into a specific color via the inventory rows).
  late Set<int>? _restoreColorIds = _filterColorIds == null ? null : Set<int>.from(_filterColorIds!);

  /// Color names keyed by id; populated from the active inventory cache so the
  /// chip and header text can show the color name without an extra lookup.
  final Map<int, String> _colorNames = {};

  bool _loading = true;
  List<_SourceRow> _rows = [];
  DateTime? _lastSyncAt;
  List<String> _headerCandidates = const [];

  late String? _goBrickPart =
      (widget.part.goBrickPart?.isNotEmpty ?? false) ? widget.part.goBrickPart : null;
  late String? _bricklinkId =
      (widget.part.bricklinkId?.isNotEmpty ?? false) ? widget.part.bricklinkId : null;
  bool _bricklinkLookupAttempted = false;

  @override
  void initState() {
    super.initState();
    // Seed color name for the part we navigated in with so the chip can show
    // it before _load() finishes pulling rows from cache.
    final entryColorId = int.tryParse(widget.part.color ?? '');
    final entryColorName = widget.part.colorName;
    if (entryColorId != null && entryColorName != null && entryColorName.isNotEmpty) {
      _colorNames[entryColorId] = entryColorName;
    }
    _resolveShopIds();
    _load();
  }

  Future<void> _resolveShopIds() async {
    final partNum = widget.part.part;
    if (partNum == null || partNum.isEmpty) return;

    _goBrickPart ??= brickConverterLogic.legoToGoBricksMap[partNum];

    if (_bricklinkId != null || _bricklinkLookupAttempted) {
      if (mounted) setState(() {});
      return;
    }
    _bricklinkLookupAttempted = true;

    try {
      final detail = await rbService.getPartDetail(partNum);
      final ext = detail?.externalIds;
      final list = ext is Map ? ext['BrickLink'] : null;
      if (list is List && list.isNotEmpty) {
        _bricklinkId = list.first?.toString();
      }
    } catch (_) {
      // Network/API failure — leave _bricklinkId null; chip just won't show.
    }
    if (mounted) setState(() {});
  }

  String? _bricklinkColorForActiveFilter() {
    // Only deep-link to a specific BrickLink colour when exactly one is active.
    final ids = _filterColorIds;
    if (ids == null || ids.length != 1) return null;
    final rbId = ids.first.toString();
    final color = brickConverterLogic.colors
        .firstWhereOrNull((c) => c.rebrickableColor == rbId);
    final bl = color?.bricklinkColor;
    return (bl != null && bl.isNotEmpty) ? bl : null;
  }

  void _selectColor(int colorId, String? colorName) {
    if (colorName != null && colorName.isNotEmpty) {
      _colorNames[colorId] = colorName;
    }
    setState(() {
      _filterColorIds = {colorId};
      _restoreColorIds = {colorId};
    });
    _load();
  }

  void _toggleFilter() {
    setState(() {
      if (_filterColorIds == null) {
        _filterColorIds = _restoreColorIds == null ? null : Set<int>.from(_restoreColorIds!);
      } else {
        _restoreColorIds = Set<int>.from(_filterColorIds!);
        _filterColorIds = null;
      }
    });
    _load();
  }

  String _filterChipLabel() {
    final ids = _filterColorIds;
    if (ids == null || ids.isEmpty) return 'All colors';
    if (ids.length == 1) {
      final name = _colorNames[ids.first];
      return (name != null && name.isNotEmpty) ? name : 'This color only';
    }
    return '${ids.length} colors';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final partNum = widget.part.part;
    if (partNum == null) {
      setState(() {
        _rows = [];
        _loading = false;
      });
      return;
    }

    final activeFilter = _filterColorIds;
    final filterIsSingle = activeFilter != null && activeFilter.length == 1;

    // Fetch all items for this part once and filter client-side; the cache for
    // a single partNum is small enough that the membership check is cheap.
    // Include excluded sources here so they still show (greyed out) rather than
    // disappearing — only their quantities are kept out of the counted total.
    final allItems = await dbLogic.findItemsForPart(partNum, includeExcluded: true);
    final items = activeFilter == null
        ? allItems
        : allItems.where((it) => activeFilter.contains(it.colorId)).toList();

    _lastSyncAt = await collectionSyncService.getLastSyncAt();

    // Pick header image candidates based on the active filter. For a singleton
    // filter we want exactly that colour; for a set we prefer the heaviest
    // owned colour within the set; for "all colours" we go by inventory total.
    final byColor = <int, int>{};
    for (final it in items) {
      byColor[it.colorId] = (byColor[it.colorId] ?? 0) + it.quantity;
      final name = it.colorName;
      if (name != null && name.isNotEmpty) _colorNames[it.colorId] ??= name;
    }
    List<NeededColor> needs;
    if (filterIsSingle) {
      final cid = activeFilter.first;
      needs = [NeededColor(colorId: cid, qty: 1, name: _colorNames[cid])];
    } else if (activeFilter != null) {
      needs = activeFilter
          .map((cid) => NeededColor(colorId: cid, qty: byColor[cid] ?? 0, name: _colorNames[cid]))
          .toList()
        ..sort((a, b) => b.qty.compareTo(a.qty));
    } else {
      needs = byColor.entries
          .map((e) => NeededColor(colorId: e.key, qty: e.value, name: _colorNames[e.key]))
          .toList()
        ..sort((a, b) => b.qty.compareTo(a.qty));
    }

    var headerCandidates = await PartImageResolver.resolveCandidates(partNum, needs);
    // Synthesise a CDN URL from the entry colour when the resolver came back
    // empty (covers fresh installs where no part-image cache exists yet).
    final entryColorId = int.tryParse(widget.part.color ?? '');
    if (headerCandidates.isEmpty && entryColorId != null) {
      headerCandidates = [PartImageResolver.buildCdnUrl(partNum, entryColorId)];
    }
    final generic = widget.part.details?.imgUrl;
    if (generic != null && generic.isNotEmpty) {
      headerCandidates = [...headerCandidates, generic];
    }

    final grouped = <String, List<CachedInventoryItem>>{};
    for (final item in items) {
      final key = '${item.sourceType.name}:${item.sourceExternalId}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final rows = <_SourceRow>[];
    for (final entry in grouped.entries) {
      final first = entry.value.first;
      final source = await dbLogic.getSource(first.sourceType, first.sourceExternalId);
      if (source == null) continue;
      rows.add(_SourceRow(source, entry.value));
    }
    // Counted sources first, then excluded ones; quantity desc within each.
    rows.sort((a, b) {
      final ax = a.source.excludeFromInventory ? 1 : 0;
      final bx = b.source.excludeFromInventory ? 1 : 0;
      if (ax != bx) return ax - bx;
      return b.totalQuantity.compareTo(a.totalQuantity);
    });

    if (!mounted) return;
    setState(() {
      _rows = rows;
      _headerCandidates = headerCandidates;
      _loading = false;
    });
  }

  /// Counted rows only — excluded sources don't contribute to the total.
  List<_SourceRow> get _countedRows =>
      _rows.where((r) => !r.source.excludeFromInventory).toList();

  int get _totalCount => _countedRows.fold(0, (sum, r) => sum + r.totalQuantity);

  String _headerColorLabel() {
    final ids = _filterColorIds;
    if (ids == null || ids.isEmpty) return 'All colors';
    if (ids.length == 1) {
      return _colorNames[ids.first] ?? '';
    }
    return '${ids.length} colors';
  }

  @override
  Widget build(BuildContext context) {
    final part = widget.part;
    final headerColor = _headerColorLabel();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          part.name ?? part.part ?? 'Part Summary',
          maxLines: 2,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: const MyBackButton(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(part, headerColor),
          _buildFilterRow(),
          if (_lastSyncAt == null && !_loading) _buildEmptyBanner(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader(CollectablePart part, String headerColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: SmartPartImage(
              candidates: _headerCandidates,
              // Single colour active → retry the API for that colour.
              // Multi-colour set → pick the first as a best-effort fallback.
              // All-colours → nothing useful to ask for, so leave the callback null.
              onExhausted: (part.part != null && (_filterColorIds?.isNotEmpty ?? false))
                  ? () => PartImageResolver.fetchApiUrl(part.part!, _filterColorIds!.first)
                  : null,
              fallback: const Icon(Icons.widgets_outlined, color: AppColors.textSecondary, size: 28),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loading ? '—' : '$_totalCount',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  'You have in ${_countedRows.length} ${_countedRows.length == 1 ? "source" : "sources"}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '${part.part} · $headerColor',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                _buildShopLinks(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopLinks() {
    final go = _goBrickPart;
    final bl = _bricklinkId;
    if ((go == null || go.isEmpty) && (bl == null || bl.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          if (go != null && go.isNotEmpty)
            _shopChip(
              label: 'Yourwobb',
              icon: Icons.shopping_bag_outlined,
              onTap: () => _openYourwobb(go),
            ),
          if (bl != null && bl.isNotEmpty)
            _shopChip(
              label: 'BrickLink',
              icon: Icons.open_in_new,
              onTap: () => _openBrickLink(bl, bricklinkColor: _bricklinkColorForActiveFilter()),
            ),
        ],
      ),
    );
  }

  Widget _shopChip({required String label, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.highlightColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.highlightColor),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Future<void> _openYourwobb(String goBrickPart) async {
    final uri = Uri.parse('https://www.yourwobb.com/search?q=$goBrickPart');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openBrickLink(String bricklinkId, {String? bricklinkColor}) async {
    final color = (bricklinkColor != null && bricklinkColor.isNotEmpty) ? '&idColor=$bricklinkColor' : '';
    final uri = Uri.parse(
        'https://www.bricklink.com/v2/catalog/catalogitem.page?P=$bricklinkId$color');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          FilterChip(
            label: Text(_filterChipLabel()),
            selected: _filterColorIds != null,
            // Disable the chip when there's no "filter" state to come back to
            // — i.e. we entered in all-colours mode with no preset filter.
            onSelected:
                (_filterColorIds != null || (_restoreColorIds?.isNotEmpty ?? false))
                    ? (_) => _toggleFilter()
                    : null,
            selectedColor: AppColors.highlightColor.withValues(alpha: 0.3),
            backgroundColor: AppColors.surfaceLight,
            labelStyle: const TextStyle(color: AppColors.textPrimary),
            checkmarkColor: AppColors.highlightColor,
          ),
          const Spacer(),
          if (_lastSyncAt != null)
            Text(
              'Cache: ${_formatAge(_lastSyncAt!)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          IconButton(
            tooltip: 'Re-sync',
            icon: const Icon(Icons.refresh, size: 20, color: AppColors.textSecondary),
            onPressed: () async {
              await showSyncProgressModal(context);
              if (!mounted) return;
              await _load();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.textSecondary, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'No collection synced yet. Tap the refresh icon or use "Sync Collection" in the menu.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.highlightColor));
    }
    if (_rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Not found in any of your sets or part lists.',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: _rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) => _buildRow(_rows[i]),
    );
  }

  Widget _buildRow(_SourceRow row) {
    final excluded = row.source.excludeFromInventory;
    // Decode at the box's physical pixel size for a crisp image (see My Sets).
    final decodeWidth = (96 * MediaQuery.devicePixelRatioOf(context)).round();
    return Card(
      child: Opacity(
        opacity: excluded ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.all(8),
                child: (row.source.imgUrl ?? '').isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: row.source.imgUrl!,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        memCacheWidth: decodeWidth,
                      )
                    : Icon(
                        row.source.type == CachedSourceType.set ? Icons.widgets : Icons.list_alt,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.source.name,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      row.source.type == CachedSourceType.set
                          ? 'Set ${row.source.externalId}${row.source.year > 0 ? " · ${row.source.year}" : ""}'
                          : 'Part list',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    if (excluded)
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          'Not counted in inventory',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.highlightColor),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: row.items.map(_buildColorChip).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${row.totalQuantity}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorChip(CachedInventoryItem item) {
    // Show the color name (and make the chip clickable as a drill-down) when
    // more than one color is currently visible. A singleton filter would mean
    // every chip is the same colour so the name and tap target are noise.
    final showMulti = (_filterColorIds?.length ?? 0) != 1;

    final rgb = item.rgb;
    Color swatch = AppColors.surfaceLight;
    if (rgb != null && rgb.length == 6) {
      swatch = Color(int.parse('FF$rgb', radix: 16));
    }
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: swatch, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 4),
          Text(
            '${item.quantity}',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          if (showMulti) ...[
            const SizedBox(width: 4),
            Text(
              item.colorName ?? '',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
          ],
        ],
      ),
    );

    if (!showMulti) return chip;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _selectColor(item.colorId, item.colorName),
      child: chip,
    );
  }

  String _formatAge(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
