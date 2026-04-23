import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/logic/db_logic.dart';
import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/model/filter_preset.dart';
import 'package:brick_collector/services/collection_sync_service.dart';
import 'package:brick_collector/ui/modals/sync_progress_modal.dart';
import 'package:brick_collector/ui/nav_menu.dart';
import 'package:brick_collector/ui/part_group_card.dart';

class PresetScreen extends StatefulWidget {
  const PresetScreen(this.presetId, {super.key});

  final int presetId;

  @override
  State<StatefulWidget> createState() => _PresetScreenState();
}

class _PresetScreenState extends State<PresetScreen> {
  bool _loading = true;
  List<AggregatedInventoryRow> _rows = [];
  DateTime? _lastSync;
  FilterPreset? _preset;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preset = _lookupPreset();
    if (preset == null) return;
    final rows = await dbLogic.filterInventory(
      categoryIds: (preset.categories ?? []).map((c) => c.id).toSet(),
      colorIds: (preset.colors ?? []).map((c) => c.id).toSet(),
      searchText: preset.searchText,
    );
    final lastSync = await collectionSyncService.getLastSyncAt();
    if (!mounted) return;
    setState(() {
      _preset = preset;
      _rows = rows;
      _lastSync = lastSync;
      _loading = false;
    });
  }

  FilterPreset? _lookupPreset() {
    try {
      return partsLogic.getPresetById(widget.presetId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FilterPreset>>(
      stream: partsLogic.outPresets,
      builder: (context, snapshot) {
        final preset = _preset ?? _lookupPreset();
        if (preset == null) {
          return const Scaffold(body: Center(child: Text('Preset not found')));
        }
        return _buildScaffold(preset);
      },
    );
  }

  Widget _buildScaffold(FilterPreset preset) {
    final parts = _rows.map(_toCollectablePart).toList();
    final groups = appLogic.groupParts(parts).values.toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));
    final totalQty = _rows.fold<int>(0, (sum, r) => sum + r.quantity);

    final subtitle = _loading
        ? 'Filtering…'
        : (_lastSync == null
            ? '${_rows.length} parts · $totalQty total · never synced'
            : '${_rows.length} parts · $totalQty total · inventory ${_formatAge(_lastSync!)}');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(preset.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        automaticallyImplyLeading: true,
      ),
      drawer: const Drawer(child: NavMenu()),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (groups.isEmpty
              ? _buildEmpty()
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8, top: 8),
                      sliver: SliverList.builder(
                        itemBuilder: (context, index) => PartGroupCard(
                          groups[index],
                          null,
                          positiveQuantity: true,
                        ),
                        itemCount: groups.length,
                      ),
                    ),
                  ],
                )),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            IconButton(
              onPressed: _syncCollection,
              icon: const Icon(Icons.sync),
              tooltip: 'Sync collection',
            ),
            IconButton(
              onPressed: () => context.push(ScreenPaths.partFilterEditPage(preset.id)),
              icon: const Icon(Icons.tune),
              tooltip: 'Edit filter',
            ),
            IconButton(
              onPressed: () => _rename(preset),
              icon: const Icon(Icons.edit),
              tooltip: 'Rename',
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _delete(preset),
              icon: const Icon(Icons.delete),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.widgets_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              _lastSync == null
                  ? 'Your inventory has not been synced yet. Sync from the drawer or below.'
                  : 'No parts in your inventory match this filter.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _syncCollection,
              icon: const Icon(Icons.sync),
              label: const Text('Sync collection'),
            ),
          ],
        ),
      ),
    );
  }

  CollectablePart _toCollectablePart(AggregatedInventoryRow r) {
    return CollectablePart(
      part: r.partNum,
      name: r.partName,
      color: r.colorId.toString(),
      colorName: r.colorName,
      rgb: r.rgb,
      quantity: r.quantity,
    );
  }

  String _formatAge(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _syncCollection() async {
    await showSyncProgressModal(context);
    if (!mounted) return;
    await _load();
  }

  Future<void> _rename(FilterPreset preset) async {
    final text = await showTextInputDialog(
      context: context,
      title: 'Rename preset',
      textFields: [DialogTextField(initialText: preset.name)],
    );
    if (text == null || text.isEmpty) return;
    final newName = text.first.trim();
    if (newName.isEmpty) return;
    preset.name = newName;
    await partsLogic.savePreset(preset);
    partsLogic.notifyPresetsChanged();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _delete(FilterPreset preset) async {
    final result = await showOkCancelAlertDialog(
      context: context,
      title: 'Delete preset',
      message: 'Remove "${preset.name}"?',
      okLabel: 'Delete',
      isDestructiveAction: true,
    );
    if (result != OkCancelResult.ok) return;
    await partsLogic.deletePreset(preset);
    if (!mounted) return;
    context.go(ScreenPaths.parts);
  }
}
