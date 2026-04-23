import 'dart:async';

import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/filter_preset.dart';
import 'package:brick_collector/services/collection_sync_service.dart';
import 'package:brick_collector/ui/modals/sync_progress_modal.dart';
import 'package:brick_collector/ui/nav_menu.dart';
import 'package:brick_lib/model/rebrickable_color.dart';

class PresetListScreen extends StatefulWidget {
  const PresetListScreen({super.key});

  @override
  State<StatefulWidget> createState() => PresetListScreenState();
}

class _PresetStats {
  _PresetStats(this.partCount, this.totalQty);
  final int partCount;
  final int totalQty;
}

class PresetListScreenState extends State<PresetListScreen> {
  DateTime? _lastSync;
  final Map<int, _PresetStats> _stats = {};
  StreamSubscription<List<FilterPreset>>? _presetsSub;

  @override
  void initState() {
    super.initState();
    _loadSyncTime();
    _presetsSub = partsLogic.outPresets.listen(_recomputeStats);
    _recomputeStats(partsLogic.presets);
  }

  @override
  void dispose() {
    _presetsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadSyncTime() async {
    final at = await collectionSyncService.getLastSyncAt();
    if (!mounted) return;
    setState(() => _lastSync = at);
  }

  Future<void> _recomputeStats(List<FilterPreset> presets) async {
    final results = <int, _PresetStats>{};
    for (final p in presets) {
      final rows = await dbLogic.filterInventory(
        categoryIds: (p.categories ?? []).map((c) => c.id).toSet(),
        colorIds: (p.colors ?? []).map((c) => c.id).toSet(),
        searchText: p.searchText,
      );
      final qty = rows.fold<int>(0, (sum, r) => sum + r.quantity);
      results[p.id] = _PresetStats(rows.length, qty);
    }
    if (!mounted) return;
    setState(() {
      _stats
        ..clear()
        ..addAll(results);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Presets"),
        automaticallyImplyLeading: true,
      ),
      drawer: const Drawer(child: NavMenu()),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _lastSync == null ? 'Inventory never synced' : 'Inventory: ${_formatAge(_lastSync!)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                TextButton.icon(
                  onPressed: _syncCollection,
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('Sync'),
                ),
              ],
            ),
          ),
        ),
        StreamBuilder<List<FilterPreset>>(
          stream: partsLogic.outPresets,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
            }
            final presets = snapshot.data ?? const [];
            if (presets.isEmpty) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No Presets', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList.builder(
                itemBuilder: (context, index) => _buildPreset(presets[index]),
                itemCount: presets.length,
              ),
            );
          },
        )
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPreset,
        tooltip: 'Create a new filter preset',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      extendBody: true,
      bottomNavigationBar: const BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 10,
      ),
    );
  }

  Widget _buildPreset(FilterPreset preset) {
    final categories = preset.categories ?? const [];
    final colors = preset.colors ?? const [];
    final search = (preset.searchText ?? '').trim();

    final stats = _stats[preset.id];
    final statsLine = stats == null ? '…' : '${stats.partCount} parts · ${stats.totalQty} total';

    final rows = <Widget>[
      Text(
        statsLine,
        style: const TextStyle(
          color: AppColors.highlightColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      if (categories.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: _labelLine('Categories', categories.map((c) => c.name).join(', ')),
        ),
      if (colors.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Colors: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: colors.map(_buildColorChip).toList(),
                ),
              ),
            ],
          ),
        ),
      if (search.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: _labelLine('Search', '"$search"'),
        ),
      if (categories.isEmpty && colors.isEmpty && search.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Text('No filters (all parts)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: () => context.go(ScreenPaths.presetPage(preset.id)),
        title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        ),
        trailing: IconButton(
          tooltip: 'Edit filter',
          icon: const Icon(Icons.tune, color: AppColors.textSecondary),
          onPressed: () => context.go(ScreenPaths.partFilterEditPage(preset.id)),
        ),
      ),
    );
  }

  Widget _labelLine(String label, String value) {
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        children: [
          TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          TextSpan(text: value),
        ],
      ),
    );
  }

  Widget _buildColorChip(RebrickableColor color) {
    final swatch = HexColor.fromHex('#${color.rgb}');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: swatch,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Text(
        color.name,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: swatch.computeLuminance() < 0.45 ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  String _formatAge(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _addPreset() async {
    final text = await showTextInputDialog(
      context: context,
      textFields: const [DialogTextField(hintText: 'Preset name')],
      title: 'Create a new filter preset',
    );
    if (text == null || text.isEmpty || text.first.trim().isEmpty) return;
    final preset = await partsLogic.addNewPreset(text.first.trim());
    if (!mounted) return;
    context.go(ScreenPaths.partFilterEditPage(preset.id));
  }

  Future<void> _syncCollection() async {
    await showSyncProgressModal(context);
    if (!mounted) return;
    await _loadSyncTime();
    await _recomputeStats(partsLogic.presets);
  }
}
