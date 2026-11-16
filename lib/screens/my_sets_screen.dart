import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/logic/set_filter.dart';
import 'package:brick_collector/model/cached_source.dart';
import 'package:brick_collector/services/collection_sync_service.dart';
import 'package:brick_collector/ui/modals/add_set_modal.dart';
import 'package:brick_collector/ui/modals/alternate_builds_modal.dart';
import 'package:brick_collector/ui/modals/sync_progress_modal.dart';
import 'package:brick_collector/ui/nav_menu.dart';
import 'package:brick_lib/model/rebrickable_set.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Lists the user's Rebrickable sets pulled in during collection sync. Each set
/// can be toggled to exclude its parts from inventory/available counts — useful
/// for sets that are built and shouldn't contribute loose parts. Rebrickable's
/// API doesn't expose its own "Build" selection, so this flag is local-only.
class MySetsScreen extends StatefulWidget {
  const MySetsScreen({super.key});

  @override
  State<StatefulWidget> createState() => MySetsScreenState();
}

class MySetsScreenState extends State<MySetsScreen> {
  List<CachedSource>? _sets;
  bool _addingSet = false;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _countedOnly = false;

  bool get _isFiltered => _query.trim().isNotEmpty || _countedOnly;

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _countedOnly = false;
    });
  }

  Future<void> _loadSets() async {
    final sets = await dbLogic.getSourcesByType(CachedSourceType.set);
    if (!mounted) return;
    setState(() => _sets = sets);
  }

  Future<void> _toggleExcluded(CachedSource set, bool excluded) async {
    // Optimistic local update, then persist + invalidate the inventory cache.
    setState(() => set.excludeFromInventory = excluded);
    if (excluded && _countedOnly) {
      // The filter hides the set the moment it's switched off; say so and
      // offer a way back, since the row is gone from under the user's finger.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('${set.name} is no longer counted'),
          persist: false,
          action: SnackBarAction(label: 'Undo', onPressed: () => _toggleExcluded(set, false)),
        ));
    }
    await dbLogic.setSourceExcluded(set.id, excluded);
  }

  @override
  Widget build(BuildContext context) {
    final sets = _sets;
    final includedCount = sets?.where((s) => !s.excludeFromInventory).length ?? 0;
    // Live filter: with "only counted" on, a set switched off here drops out.
    final visible = sets == null ? null : filterSets(sets, query: _query, countedOnly: _countedOnly);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Sets'),
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add set',
            onPressed: _addingSet ? null : _addSet,
          ),
        ],
      ),
      drawer: const Drawer(child: NavMenu()),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _addingSet
                        ? 'Importing set…'
                        : sets == null
                            ? 'Loading…'
                            : _isFiltered
                                ? 'Showing ${visible!.length} of ${sets.length} sets · $includedCount counted'
                                : '$includedCount of ${sets.length} sets counted toward inventory',
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
        // Kept while a filter is active, so it can always be seen and cleared.
        if (sets != null && (sets.isNotEmpty || _isFiltered)) SliverToBoxAdapter(child: _buildFilters()),
        if (sets == null)
          const SliverToBoxAdapter(
            child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
          )
        else if (sets.isEmpty && !_isFiltered)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Text(
                    'No sets synced yet.\nSync your collection to fetch your Rebrickable sets.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _addingSet ? null : _addSet,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add a set'),
                  ),
                ],
              ),
            ),
          )
        else if (visible!.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Text(
                    'No sets match the filter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off, size: 16),
                    label: const Text('Clear filters'),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverList.builder(
              itemBuilder: (context, index) => _buildSet(visible[index]),
              itemCount: visible.length,
            ),
          ),
      ]),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextField(
              key: const Key('mySetsSearch'),
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Filter by name or number',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                floatingLabelStyle: const TextStyle(color: AppColors.highlightColor),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                        tooltip: 'Clear',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Only sets counted in inventory',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
              Switch(
                key: const Key('mySetsCountedOnly'),
                value: _countedOnly,
                activeThumbColor: AppColors.highlightColor,
                onChanged: (value) => setState(() => _countedOnly = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSet(CachedSource set) {
    final excluded = set.excludeFromInventory;
    final meta = <String>[
      set.externalId,
      if (set.year > 0) '${set.year}',
      '${set.numParts} parts',
      if (set.ownedQuantity > 1) '×${set.ownedQuantity}',
    ].join(' · ');

    // Decode at the box's physical pixel size so the large source image is
    // resampled at full device resolution instead of being downscaled and then
    // stretched (which is what made it look pixelated).
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final decodeWidth = (104 * dpr).round();

    return Card(
      // The filtered list shifts under its rows; keep each row's state (switch
      // animation, image) with its set.
      key: ValueKey(set.id),
      margin: const EdgeInsets.only(bottom: 6),
      child: Opacity(
        opacity: excluded ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 104,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(8),
                      child: (set.imgUrl != null && set.imgUrl!.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: set.imgUrl!,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              memCacheWidth: decodeWidth,
                              errorWidget: (_, __, ___) =>
                                  const Icon(Icons.widgets_outlined, color: AppColors.textSecondary),
                            )
                          : const Icon(Icons.widgets_outlined, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      set.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(meta, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    if (excluded)
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          'Not counted in inventory',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.highlightColor),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.lightbulb_outline),
                tooltip: 'Alternate builds',
                onPressed: () => _showAlternates(set),
              ),
              Switch(
                value: !excluded,
                activeThumbColor: AppColors.highlightColor,
                onChanged: (counted) => _toggleExcluded(set, !counted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _syncCollection() async {
    await showSyncProgressModal(context);
    if (!mounted) return;
    await _loadSets();
  }

  void _showAlternates(CachedSource set) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AlternateBuildsModal(setNum: set.externalId, setName: set.name),
    );
  }

  /// Adds a set to the Rebrickable collection, then pulls just that set into
  /// the local cache so its parts count immediately, without a full sync.
  Future<void> _addSet() async {
    final added = await showModalBottomSheet<RebrickableSet>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddSetModal(),
    );
    if (added == null || !mounted) return;

    setState(() => _addingSet = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Read the quantity back from the server: adding a set that is already
      // in the collection increments it rather than creating a second entry.
      final userSet = await rbService.getUserSet(added.setNum);
      await collectionSyncService.syncSingleSet(
        userSet?.set ?? added,
        quantity: userSet?.quantity ?? 1,
      );
      if (!mounted) return;
      await _loadSets();
      messenger.showSnackBar(
        SnackBar(content: Text('Added ${added.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('${added.setNum} was added, but importing its parts failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _addingSet = false);
    }
  }
}
