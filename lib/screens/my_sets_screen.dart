import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/cached_source.dart';
import 'package:brick_collector/services/collection_sync_service.dart';
import 'package:brick_collector/ui/modals/add_set_modal.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    final sets = await dbLogic.getSourcesByType(CachedSourceType.set);
    if (!mounted) return;
    setState(() => _sets = sets);
  }

  Future<void> _toggleExcluded(CachedSource set, bool excluded) async {
    // Optimistic local update, then persist + invalidate the inventory cache.
    setState(() => set.excludeFromInventory = excluded);
    await dbLogic.setSourceExcluded(set.id, excluded);
  }

  @override
  Widget build(BuildContext context) {
    final sets = _sets;
    final includedCount = sets?.where((s) => !s.excludeFromInventory).length ?? 0;

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
        if (sets == null)
          const SliverToBoxAdapter(
            child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
          )
        else if (sets.isEmpty)
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
        else
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverList.builder(
              itemBuilder: (context, index) => _buildSet(sets[index]),
              itemCount: sets.length,
            ),
          ),
      ]),
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
              const SizedBox(width: 8),
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
