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

class PartSummaryScreen extends StatefulWidget {
  final CollectablePart part;
  final bool filterByColor;

  const PartSummaryScreen(this.part, {this.filterByColor = true, super.key});

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
  late bool _filterByColor = widget.filterByColor;
  late int? _filterColorId = int.tryParse(widget.part.color ?? '');
  late String? _filterColorName = widget.part.colorName;
  bool _loading = true;
  List<_SourceRow> _rows = [];
  DateTime? _lastSyncAt;
  List<String> _headerCandidates = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _selectColor(int colorId, String? colorName) {
    setState(() {
      _filterByColor = true;
      _filterColorId = colorId;
      _filterColorName = colorName;
    });
    _load();
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

    final colorFilter = _filterByColor ? _filterColorId : null;
    final items = await dbLogic.findItemsForPart(partNum, colorId: colorFilter);
    _lastSyncAt = await collectionSyncService.getLastSyncAt();

    List<String> headerCandidates;
    if (_filterByColor && _filterColorId != null) {
      headerCandidates = await PartImageResolver.resolveCandidates(
        partNum,
        [NeededColor(colorId: _filterColorId!, qty: 1, name: _filterColorName)],
      );
    } else {
      // All-colors view: pick images for every owned color, biggest quantity first.
      // Falls back to the incoming widget.part.details if the cache is empty.
      final allItems = await dbLogic.findItemsForPart(partNum);
      final byColor = <int, int>{};
      final colorNames = <int, String?>{};
      for (final it in allItems) {
        byColor[it.colorId] = (byColor[it.colorId] ?? 0) + it.quantity;
        colorNames[it.colorId] ??= it.colorName;
      }
      final needs = byColor.entries
          .map((e) => NeededColor(colorId: e.key, qty: e.value, name: colorNames[e.key]))
          .toList()
        ..sort((a, b) => b.qty.compareTo(a.qty));
      headerCandidates = await PartImageResolver.resolveCandidates(partNum, needs);
      // If cache is empty for this part, synthesize a URL using the entry color we arrived with.
      final entryColorId = int.tryParse(widget.part.color ?? '');
      if (headerCandidates.isEmpty && entryColorId != null) {
        headerCandidates = [PartImageResolver.buildCdnUrl(partNum, entryColorId)];
      }
      final generic = widget.part.details?.imgUrl;
      if (generic != null && generic.isNotEmpty) headerCandidates = [...headerCandidates, generic];
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
    rows.sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));

    if (!mounted) return;
    setState(() {
      _rows = rows;
      _headerCandidates = headerCandidates;
      _loading = false;
    });
  }

  int get _totalCount => _rows.fold(0, (sum, r) => sum + r.totalQuantity);

  @override
  Widget build(BuildContext context) {
    final part = widget.part;
    final headerColor = _filterByColor ? (_filterColorName ?? '') : 'All colors';

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
              onExhausted: (_filterByColor && _filterColorId != null && part.part != null)
                  ? () => PartImageResolver.fetchApiUrl(part.part!, _filterColorId!)
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
                  'You have in ${_rows.length} ${_rows.length == 1 ? "source" : "sources"}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '${part.part} · $headerColor',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          FilterChip(
            label: Text(_filterByColor ? 'This color only' : 'All colors'),
            selected: _filterByColor,
            onSelected: (_) {
              setState(() => _filterByColor = !_filterByColor);
              _load();
            },
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: (row.source.imgUrl ?? '').isNotEmpty
                  ? CachedNetworkImage(imageUrl: row.source.imgUrl!, fit: BoxFit.contain)
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
    );
  }

  Widget _buildColorChip(CachedInventoryItem item) {
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
          if (!_filterByColor) ...[
            const SizedBox(width: 4),
            Text(
              item.colorName ?? '',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
          ],
        ],
      ),
    );

    if (_filterByColor) return chip;

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
