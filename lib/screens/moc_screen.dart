import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/CollectablePartGroup.dart';
import 'package:brick_collector/notifications/save_moc_notification.dart';
import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/ui/modals/add_part_modal.dart';
import 'package:brick_collector/ui/modals/moc_filter_modal.dart';
import 'package:brick_collector/ui/nav_menu.dart';
import 'package:brick_collector/ui/part_group_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MocScreen extends StatefulWidget {
  final Moc moc;

  const MocScreen(this.moc, {super.key});

  @override
  State<StatefulWidget> createState() => MocScreenState();
}

class MocScreenState extends State<MocScreen> {
  Moc get moc => widget.moc;

  bool _loading = false;
  bool _fileLoaded = false;

  /// Rebrickable colour ids to show; empty = show all colours.
  final Set<String> _colorFilter = {};

  /// When true, hide parts the synced inventory can already cover.
  bool _missingOnly = false;

  /// Owned quantity per "part_color" from the inventory cache; loaded lazily
  /// while the "missing only" filter is active.
  Map<String, int> _ownedCounts = {};
  bool _ownedLoaded = false;

  bool get _hasActiveFilter => _colorFilter.isNotEmpty || _missingOnly || moc.hideComplete;

  MocScreenState();

  @override
  void initState() {
    super.initState();
    // Repair legacy data: duplicate part+colour entries used to be merged by
    // mutation on every rebuild (PartGroup.addPart), inflating the persisted
    // quantity. Merge them once for real and save the cleaned-up list.
    if (appLogic.dedupeMocParts(moc)) {
      mocLogic.saveMoc(moc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> childs = [];

    if (moc.parts == null || moc.parts?.isEmpty == true) {
      childs.add(const SliverToBoxAdapter(
          child: Center(
        child: Text("No parts added to Collection"),
      )));
    } else {
      childs.add(_buildPartsView());
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: moc.shoppingMode ? AppColors.highlightColor.withValues(alpha: 0.18) : null,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(moc.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text("${moc.collectedCount} / ${moc.quantity} collected",
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (moc.shoppingMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.highlightColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.highlightColor.withValues(alpha: 0.6), width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_cart, size: 12, color: AppColors.highlightColor),
                    SizedBox(width: 4),
                    Text('Shopping',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.highlightColor,
                            letterSpacing: 0.3)),
                  ],
                ),
              ),
          ],
        ),
        automaticallyImplyLeading: true,
      ),
      drawer: const Drawer(child: NavMenu()),
      body: NotificationListener<SaveMocNotification>(
        onNotification: _saveMoc,
        child: CustomScrollView(slivers: childs),
      ),
      bottomNavigationBar: BottomAppBar(
        color: moc.shoppingMode ? AppColors.highlightColor.withValues(alpha: 0.12) : null,
        child: Row(
          children: [
            IconButton(onPressed: editMoc, icon: const Icon(Icons.edit), tooltip: 'Rename'),
            IconButton(
              onPressed: _pickImage,
              icon: Icon(moc.imageBase64 != null ? Icons.image : Icons.image_outlined),
              tooltip: 'Set MOC image',
            ),
            IconButton(onPressed: _addManualPart, icon: const Icon(Icons.add_box_outlined), tooltip: 'Add part'),
            IconButton(onPressed: _addParts, icon: const Icon(Icons.file_download), tooltip: 'Import parts (CSV or Studio .io)'),
            if (moc.sourceUrl != null)
              IconButton(onPressed: _openOnRebrickable, icon: const Icon(Icons.open_in_browser), tooltip: 'Rebrickable'),
            IconButton(onPressed: sortParts, icon: const Icon(Icons.sort), tooltip: 'Sort'),
            IconButton(
                onPressed: _showFilter,
                icon: Icon(
                  _hasActiveFilter ? Icons.filter_alt : Icons.filter_alt_outlined,
                  color: _hasActiveFilter ? AppColors.highlightColor : null,
                ),
                tooltip: _hasActiveFilter ? 'Filter (active)' : 'Filter'),
            IconButton(
                onPressed: toggleShoppingMode,
                icon: Icon(
                  moc.shoppingMode ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                  color: moc.shoppingMode ? AppColors.highlightColor : null,
                ),
                tooltip: moc.shoppingMode ? 'Shopping mode (on)' : 'Shopping mode'),
            const Spacer(),
            IconButton(onPressed: deleteMoc, icon: const Icon(Icons.delete), tooltip: 'Delete'),
          ],
        ),
      ),
    );
  }

  editMoc() async {
    final text = await showTextInputDialog(context: context, textFields: [DialogTextField(initialText: moc.name)], title: "Update MOC");

    if (text == null || text.isEmpty == true) {
      return;
    }
    moc.name = text.first;

    await mocLogic.saveMoc(moc);
  }

  deleteMoc() async {
    final result = await showOkCancelAlertDialog(
      context: context,
      title: 'Delete MoC',
      message: 'Do you really want to delete this MoC?',
      canPop: false,
    );
    if (result == OkCancelResult.ok) {
      await mocLogic.deleteMoc(moc);
      context.go(ScreenPaths.home);
    }
  }

  Widget _buildPartsView() {
    final size = MediaQuery.of(context).size;

    final factor = size.width % 350;

    final double maxCardWidth = 350 + factor;
    print("Width: ${size.width} | Cardw: $maxCardWidth");

    final source = _colorFilter.isEmpty
        ? moc.parts!
        : moc.parts!.where((p) => p.color != null && _colorFilter.contains(p.color)).toList();
    final groups = appLogic.groupParts(source);
    final sortedParts = groups.values.sorted((a, b) {
      if (moc.sort == PartSort.nameAsc || moc.sort == PartSort.nameDesc) {
        return moc.sort == PartSort.nameAsc ? a.partName.compareTo(b.partName) : b.partName.compareTo(a.partName);
      }

      if (moc.sort == PartSort.quantityAsc || moc.sort == PartSort.quantityDesc) {
        return moc.sort == PartSort.quantityAsc ? a.quantity.compareTo(b.quantity) : b.quantity.compareTo(a.quantity);
      }

      return moc.sort == PartSort.collectedAsc
          ? a.collectedCount.compareTo(b.collectedCount)
          : b.collectedCount.compareTo(a.collectedCount);
    }).where((element) => moc.hideComplete ? element.collectedCount != element.quantity : true)
        // Keep a group only if at least one of its (colour-filtered) parts is
        // still missing from inventory. Skipped until counts have loaded.
        .where((group) => !(_missingOnly && _ownedLoaded) || group.parts.any(_isMissing))
        .toList();

    if (sortedParts.isEmpty && (_colorFilter.isNotEmpty || _missingOnly)) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No parts match the active filter.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8, top: 8),
      sliver: SliverList.builder(
        itemBuilder: (BuildContext context, int index) {
          return PartGroupCard(sortedParts.elementAt(index), moc);
        },
        itemCount: sortedParts.length,
      ),
    );
  }

  void _addManualPart() async {
    final existingPartIds = (moc.parts ?? []).map((p) => p.part).whereType<String>().toSet();
    final parts = await showModalBottomSheet<List<CollectablePart>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddPartModal(existingPartIds: existingPartIds),
    );
    if (parts == null || parts.isEmpty) return;

    moc.parts = appLogic.mergeParts(moc.parts ?? [], parts);
    await mocLogic.saveMoc(moc);
    if (!mounted) return;
    setState(() {});
  }

  /// Distinct colours present in the MOC, with a count of parts per colour.
  List<ColorFilterOption> _availableColors() {
    final byId = <String, ColorFilterOption>{};
    for (final p in moc.parts ?? <CollectablePart>[]) {
      final id = p.color;
      if (id == null) continue;
      final existing = byId[id];
      if (existing == null) {
        byId[id] = ColorFilterOption(id: id, name: p.colorName ?? id, rgb: p.rgb ?? '', count: 1);
      } else {
        existing.count++;
      }
    }
    return byId.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  void _showFilter() async {
    final result = await showModalBottomSheet<MocFilterResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MocFilterModal(
        options: _availableColors(),
        selectedColors: _colorFilter,
        hideCompleted: moc.hideComplete,
        missingOnly: _missingOnly,
      ),
    );
    if (result == null) return;

    setState(() {
      _colorFilter
        ..clear()
        ..addAll(result.colors);
      _missingOnly = result.missingOnly;
    });

    if (moc.hideComplete != result.hideCompleted) {
      moc.hideComplete = result.hideCompleted;
      await mocLogic.saveMoc(moc);
    }
    // Inventory data only needed when the filter is on; reload on apply so it
    // reflects any parts added/removed since last time.
    if (_missingOnly) {
      await _loadOwnedCounts();
    }
    if (mounted) setState(() {});
  }

  /// Sums owned quantity per "part_color" across the inventory cache for every
  /// part in this MOC (excluded sources are already filtered out by DbLogic).
  Future<void> _loadOwnedCounts() async {
    final partNums = (moc.parts ?? <CollectablePart>[]).map((p) => p.part).whereType<String>().toSet();
    final map = <String, int>{};
    for (final pn in partNums) {
      final items = await dbLogic.findItemsForPart(pn);
      for (final it in items) {
        final key = '${it.partNum}_${it.colorId}';
        map[key] = (map[key] ?? 0) + it.quantity;
      }
    }
    if (!mounted) return;
    setState(() {
      _ownedCounts = map;
      _ownedLoaded = true;
    });
  }

  /// A part is "missing" when the inventory can't cover what's still needed.
  bool _isMissing(CollectablePart part) {
    if (part.remaining <= 0) return false;
    final owned = _ownedCounts['${part.part}_${part.color}'] ?? 0;
    return owned < part.remaining;
  }

  void _addParts() async {
    setState(() {
      _loading = true;
    });
    await appLogic.addPartsToMoc(moc);

    setState(() {
      _loading = false;
      _fileLoaded = true;
    });
  }

  bool _saveMoc(SaveMocNotification notification) {
    _saveMocInternal();

    return true;
  }

  void _saveMocInternal() async {
    await mocLogic.saveMoc(moc);

    setState(() {});

    // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("MoC saved")));
  }

  void sortParts() async {
    final result = await showConfirmationDialog<PartSort>(
      context: context,
      title: 'Select sort order',
      message: 'How to sort the parts',
      actions: PartSort.values
          .map(
            (e) => AlertDialogAction(
              label: getLabel(e),
              key: e,
            ),
          )
          .toList(),
      initialSelectedActionKey: moc.sort,
    );
    if (result == null) return;

    moc.sort = result;
    await mocLogic.saveMoc(moc);
    setState(() {});
  }

  void toggleShoppingMode() async {
    moc.shoppingMode = !moc.shoppingMode;
    await mocLogic.saveMoc(moc);
    setState(() {});
  }

  void _openOnRebrickable() async {
    final uri = Uri.parse(moc.sourceUrl!);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _pickImage() async {
    final messenger = ScaffoldMessenger.of(context);

    if (moc.imageBase64 != null) {
      final action = await showModalActionSheet<String>(
        context: context,
        title: 'MOC image',
        actions: const [
          SheetAction(label: 'Replace image', key: 'replace'),
          SheetAction(label: 'Remove image', key: 'remove', isDestructiveAction: true),
        ],
      );
      if (action == null) return;
      if (action == 'remove') {
        await mocLogic.clearMocImage(moc);
        if (!mounted) return;
        setState(() {});
        messenger.showSnackBar(
          const SnackBar(content: Text('Image removed'), duration: Duration(seconds: 2)),
        );
        return;
      }
    }

    final List<int>? bytes;
    try {
      bytes = await mocLogic.pickImageBytes();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Could not open picker: $e')));
      return;
    }
    if (bytes == null) return; // User cancelled the picker.

    // Spinner only covers the encode + Firestore save, not the user's
    // gallery-browsing time.
    final progress = messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Saving image…'),
          ],
        ),
        duration: Duration(minutes: 1),
      ),
    );

    try {
      await mocLogic.setMocImageFromBytes(moc, bytes);
      progress.close();
      if (!mounted) return;
      setState(() {});
      messenger.showSnackBar(
        const SnackBar(content: Text('Image saved'), duration: Duration(seconds: 2)),
      );
    } catch (e) {
      progress.close();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Could not set image: $e')));
    }
  }
}
