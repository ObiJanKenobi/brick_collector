import 'dart:async';

import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/logic/inventory_view.dart';
import 'package:brick_collector/model/filter_preset.dart';
import 'package:brick_collector/services/collection_sync_service.dart';
import 'package:brick_collector/ui/filter_editor.dart';
import 'package:brick_collector/ui/load_error_view.dart';
import 'package:brick_collector/ui/modals/sync_progress_modal.dart';
import 'package:brick_collector/ui/nav_menu.dart';
import 'package:brick_collector/ui/part_group_card.dart';
import 'package:brick_lib/model/rebrickable_color.dart';
import 'package:brick_lib/model/rebrickable_part_category.dart';

/// The whole synced inventory, optionally narrowed by the same criteria a
/// preset uses. The filter is transient: it is edited on a separate page and
/// only takes effect when the user taps Apply. It is only persisted when the
/// user explicitly saves it as a new preset.
class AllPartsScreen extends StatefulWidget {
  const AllPartsScreen({super.key});

  @override
  State<AllPartsScreen> createState() => _AllPartsScreenState();
}

FilterPreset _emptyFilter() => partsLogic.newPreset('All parts');

/// Default name for a preset saved from [f], e.g. "Bricks, Black, Red" or
/// "plate, Bricks +3".
String _suggestedPresetName(FilterPreset f) {
  final search = (f.searchText ?? '').trim();
  final names = [
    if (search.isNotEmpty) search,
    ...?f.categories?.map((c) => c.name),
    ...?f.colors?.map((c) => c.name),
  ];
  if (names.length <= 3) return names.join(', ');
  return '${names.take(2).join(', ')} +${names.length - 2}';
}

int _criteriaCount(FilterPreset f) =>
    (f.categories?.length ?? 0) +
    (f.colors?.length ?? 0) +
    ((f.searchText ?? '').trim().isEmpty ? 0 : 1);

class _AllPartsScreenState extends State<AllPartsScreen> {
  bool _loading = true;

  /// Null before the first load and after a failed one ([_loadError]).
  InventoryView? _view;
  Object? _loadError;
  FilterPreset _filter = _emptyFilter();
  StreamSubscription<SyncProgress?>? _syncSub;

  /// Bumped per load so a slow, superseded query can't overwrite a newer one.
  int _loadGeneration = 0;

  bool get _isFiltered => _criteriaCount(_filter) > 0;

  @override
  void initState() {
    super.initState();
    _load();
    // Reload after any sync, including one started from the drawer. skip(1)
    // drops the BehaviorSubject's replay of a sync that finished earlier.
    _syncSub = collectionSyncService.progressStream.skip(1).listen((p) {
      if (p != null && p.finished) _load();
    });
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    InventoryView? view;
    Object? error;
    try {
      view = await InventoryView.load(_filter);
    } catch (e) {
      error = e;
    }
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _view = view;
      _loadError = error;
      _loading = false;
    });
  }

  void _apply(FilterPreset filter) {
    setState(() {
      _filter = filter;
      _loading = true;
    });
    _load();
  }

  Future<void> _openFilter() async {
    final applied = await Navigator.of(context).push<FilterPreset>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FilterPage(initial: _filter.copy()),
    ));
    if (applied == null || !mounted) return;
    _apply(applied);
  }

  /// Saves the applied filter as a new preset and stays on this screen.
  Future<void> _saveAsPreset() async {
    final text = await showTextInputDialog(
      context: context,
      title: 'Save as preset',
      textFields: [
        DialogTextField(hintText: 'Preset name', initialText: _suggestedPresetName(_filter)),
      ],
    );
    if (text == null || text.isEmpty) return;
    final name = text.first.trim();
    if (name.isEmpty || !mounted) return;

    final id = partsLogic.savePreset(_filter.copy()..name = name);
    // Captured now: the SnackBar can outlive this screen.
    final router = GoRouter.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Saved preset "$name"'),
      // An action makes a SnackBar persist by default, which would hold back
      // a save-error SnackBar from DbLogic.writeErrors indefinitely.
      persist: false,
      action: SnackBarAction(
        label: 'View',
        onPressed: () => router.go(ScreenPaths.presetPage(id)),
      ),
    ));
  }

  /// The progressStream listener reloads once the sync finishes.
  Future<void> _syncCollection() => showSyncProgressModal(context);

  @override
  Widget build(BuildContext context) {
    final view = _view;
    final String subtitle;
    if (_loading) {
      subtitle = _isFiltered ? 'Filtering…' : 'Loading…';
    } else {
      subtitle = view?.summary ?? 'Could not load inventory';
    }
    final criteria = _criteriaCount(_filter);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('All Parts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
      drawer: const Drawer(child: NavMenu()),
      body: Column(
        children: [
          if (_isFiltered) _buildActiveFilterBar(),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            IconButton(
              onPressed: _syncCollection,
              icon: const Icon(Icons.sync),
              tooltip: 'Sync collection',
            ),
            IconButton(
              onPressed: _openFilter,
              icon: Badge(
                isLabelVisible: criteria > 0,
                label: Text('$criteria'),
                child: const Icon(Icons.tune),
              ),
              tooltip: 'Filter',
            ),
            if (_isFiltered)
              IconButton(
                onPressed: () => _apply(_emptyFilter()),
                icon: const Icon(Icons.filter_alt_off),
                tooltip: 'Clear filter',
              ),
            const Spacer(),
            if (_isFiltered)
              IconButton(
                onPressed: _saveAsPreset,
                icon: const Icon(Icons.bookmark_add_outlined),
                tooltip: 'Save as preset',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final view = _view;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (view == null) return LoadErrorView(error: _loadError ?? 'unknown error', onRetry: () => _apply(_filter));
    if (view.groups.isEmpty) return _buildEmpty(view);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      itemCount: view.groups.length,
      itemBuilder: (context, index) {
        final group = view.groups[index];
        return PartGroupCard(group, null, positiveQuantity: true, key: ValueKey(group.partNum));
      },
    );
  }

  /// Applied criteria as chips: tap one to edit the filter, or remove it with
  /// its delete icon (which re-applies right away).
  Widget _buildActiveFilterBar() {
    final f = _filter;
    final search = (f.searchText ?? '').trim();
    final chips = <Widget>[
      if (search.isNotEmpty)
        _filterChip(
          label: '"$search"',
          avatar: const Icon(Icons.search, size: 16),
          onDeleted: () => _apply(f.copy()..searchText = null),
        ),
      for (final c in f.categories ?? const <RebrickablePartCategory>[])
        _filterChip(
          label: c.name,
          onDeleted: () => _apply(f.copy()..removeCategory(c.id)),
        ),
      for (final c in f.colors ?? const <RebrickableColor>[])
        _filterChip(
          label: c.name,
          avatar: Container(
            decoration: BoxDecoration(
              color: HexColor.fromHex('#${c.rgb}'),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),
          onDeleted: () => _apply(f.copy()..removeColor(c.id)),
        ),
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, index) => Center(child: chips[index]),
      ),
    );
  }

  Widget _filterChip({required String label, Widget? avatar, required VoidCallback onDeleted}) {
    return InputChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      avatar: avatar,
      onPressed: _openFilter,
      onDeleted: onDeleted,
      deleteButtonTooltipMessage: 'Remove',
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildEmpty(InventoryView view) {
    final String message;
    final Widget action;
    if (view.lastSync == null) {
      message = 'Your inventory has not been synced yet.';
      action = _syncButton();
    } else if (_isFiltered) {
      message = 'No parts in your inventory match this filter.';
      action = OutlinedButton.icon(
        onPressed: () => _apply(_emptyFilter()),
        icon: const Icon(Icons.filter_alt_off),
        label: const Text('Clear filter'),
      );
    } else {
      message = 'Your inventory is empty.';
      action = _syncButton();
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.widgets_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            action,
          ],
        ),
      ),
    );
  }

  Widget _syncButton() => ElevatedButton.icon(
        onPressed: _syncCollection,
        icon: const Icon(Icons.sync),
        label: const Text('Sync collection'),
      );

}

/// Full-screen editor for a draft filter. Pops with the draft on Apply;
/// closing it any other way discards the changes.
class _FilterPage extends StatefulWidget {
  const _FilterPage({required this.initial});

  final FilterPreset initial;

  @override
  State<_FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<_FilterPage> {
  late FilterPreset _draft = widget.initial;

  void _apply() => Navigator.of(context).pop(_draft);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FilterEditor(
        filter: _draft,
        onSearchSubmitted: _apply,
        appBar: SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.bg,
          title: const Text('Filter parts'),
          actions: [
            TextButton(
              onPressed: () => setState(() => _draft = _emptyFilter()),
              child: const Text('Clear all'),
            ),
          ],
        ),
      ),
      extendBody: true,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            const Spacer(),
            FilledButton.icon(
              onPressed: _apply,
              icon: const Icon(Icons.check),
              label: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
