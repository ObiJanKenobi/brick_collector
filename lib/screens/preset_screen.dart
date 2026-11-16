import 'dart:async';

import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/logic/inventory_view.dart';
import 'package:brick_collector/model/filter_preset.dart';
import 'package:brick_collector/services/collection_sync_service.dart';
import 'package:brick_collector/ui/load_error_view.dart';
import 'package:brick_collector/ui/modals/sync_progress_modal.dart';
import 'package:brick_collector/ui/nav_menu.dart';
import 'package:brick_collector/ui/part_group_card.dart';

class PresetScreen extends StatefulWidget {
  const PresetScreen(this.presetId, {super.key});

  final String presetId;

  @override
  State<StatefulWidget> createState() => _PresetScreenState();
}

class _PresetScreenState extends State<PresetScreen> {
  bool _loading = true;

  /// Null before the first load and after a failed one ([_loadError]).
  InventoryView? _view;
  Object? _loadError;

  /// A copy from [PartsLogic.getPresetById], so it can be edited directly.
  FilterPreset? _preset;
  StreamSubscription<List<FilterPreset>>? _presetsSub;
  StreamSubscription<SyncProgress?>? _syncSub;

  /// Bumped per load so a slow, superseded query can't overwrite a newer one.
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    // Shown on the first frame; outPresets' replay then runs the first load.
    _preset = _lookupPreset();
    // Re-run the filter query whenever the preset list emits (initial Firestore
    // load, edits saved on the filter screen, or rename/delete from this
    // screen); _load skips it if this preset's criteria didn't change.
    _presetsSub = partsLogic.outPresets.listen((_) {
      if (!mounted) return;
      _load();
    });
    // The inventory itself changes with any sync, including one started from
    // the drawer. skip(1) drops the replay of a sync that finished earlier.
    _syncSub = collectionSyncService.progressStream.skip(1).listen((p) {
      if (p != null && p.finished && mounted) _reload();
    });
  }

  @override
  void dispose() {
    _presetsSub?.cancel();
    _syncSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final preset = _lookupPreset();
    if (preset == null) {
      // Deleted (here or elsewhere) or rolled back after a rejected create:
      // drop the stale copy so build() shows the not-found screen.
      if (_preset != null) setState(() => _preset = null);
      return;
    }
    // outPresets emits for any preset's change (and twice per save: local
    // write, then server ack). Only re-query when this one's criteria moved.
    final current = _preset;
    if (current != null && _view != null && current.hasSameCriteria(preset)) {
      setState(() => _preset = preset);
      return;
    }
    // First sighting (e.g. the preset list arrived after this screen opened):
    // show it as loading rather than not-found while the query runs.
    if (current == null) setState(() => _preset = preset);
    InventoryView? view;
    Object? error;
    try {
      view = await InventoryView.load(preset);
    } catch (e) {
      error = e;
    }
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _preset = preset;
      _view = view;
      _loadError = error;
      _loading = false;
    });
  }

  /// Re-runs the query even though the criteria are unchanged (new
  /// inventory, or a retry after an error).
  void _reload() {
    setState(() {
      _view = null;
      _loading = true;
    });
    _load();
  }

  FilterPreset? _lookupPreset() => partsLogic.getPresetById(widget.presetId);

  @override
  Widget build(BuildContext context) {
    final preset = _preset;
    if (preset == null) return _buildNotFound();
    return _buildScaffold(preset);
  }

  /// Reached when the preset was deleted (e.g. on another device) or its
  /// creation was rejected by the server. Keeps the drawer and a way back,
  /// since the route may have replaced the whole stack.
  Widget _buildNotFound() {
    return Scaffold(
      appBar: AppBar(title: const Text('Preset not found')),
      drawer: const Drawer(child: NavMenu()),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This preset does not exist (any more).',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go(ScreenPaths.parts),
                child: const Text('Back to presets'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScaffold(FilterPreset preset) {
    final view = _view;
    final groups = view?.groups ?? const [];
    final String subtitle;
    if (_loading) {
      subtitle = 'Filtering…';
    } else {
      subtitle = view?.summary ?? 'Could not load inventory';
    }

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
          : view == null
          ? LoadErrorView(error: _loadError ?? 'unknown error', onRetry: _reload)
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
              onPressed: () => context.push(ScreenPaths.partFilterEditPage(preset.firestoreId!)),
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
              _view?.lastSync == null
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

  /// The progressStream listener reloads once the sync finishes.
  Future<void> _syncCollection() => showSyncProgressModal(context);

  Future<void> _rename(FilterPreset preset) async {
    final text = await showTextInputDialog(
      context: context,
      title: 'Rename preset',
      textFields: [DialogTextField(initialText: preset.name)],
    );
    if (text == null || text.isEmpty) return;
    final newName = text.first.trim();
    if (newName.isEmpty) return;
    // Re-read rather than reuse [preset]: the filter may have changed while
    // the dialog was open (or before this screen caught up), and the save
    // writes the whole preset. Saving re-emits outPresets, which shows the name.
    final fresh = partsLogic.getPresetById(widget.presetId);
    if (fresh == null) return;
    partsLogic.savePreset(fresh..name = newName);
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
    // Stop listening first, or the deletion's emission would flash the
    // not-found page during this screen's exit transition.
    _presetsSub?.cancel();
    partsLogic.deletePreset(preset);
    if (mounted) context.go(ScreenPaths.parts);
  }
}
