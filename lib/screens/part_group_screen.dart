import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/CollectablePartGroup.dart';
import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/notifications/save_moc_notification.dart';
import 'package:brick_collector/services/part_image_resolver.dart';
import 'package:brick_collector/ui/StripedContainer.dart';
import 'package:brick_collector/ui/app_colors.dart';
import 'package:brick_collector/ui/back_button.dart';
import 'package:brick_collector/ui/smart_part_image.dart';
import 'package:brick_collector/ui/modals/add_part_modal.dart';
import 'package:brick_collector/ui/modals/collect_modal.dart';
import 'package:brick_collector/ui/modals/edit_quantity_modal.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:url_launcher/url_launcher.dart';

class PartGroupScreen extends StatefulWidget {
  final CollectablePartGroup group;
  final Moc moc;

  const PartGroupScreen(this.group, this.moc, {super.key});

  @override
  State<StatefulWidget> createState() => PartGroupScreenState();
}

class PartGroupScreenState extends State<PartGroupScreen> {
  PartGroupScreenState();

  final Map<String, int> _inventoryCounts = {};
  List<String> _headerCandidates = const [];
  NeededColor? _topNeed;

  CollectablePartGroup get group => widget.group;

  Moc get moc => widget.moc;

  String _inventoryKey(CollectablePart part) => "${part.part}_${part.color}";

  @override
  void initState() {
    super.initState();
    _loadInventoryCounts();
  }

  Future<void> _loadInventoryCounts() async {
    final counts = await Future.wait(group.parts.map((part) async {
      final partNum = part.part;
      final colorId = int.tryParse(part.color ?? '');
      if (partNum == null || colorId == null) {
        return MapEntry(_inventoryKey(part), 0);
      }
      final items = await dbLogic.findItemsForPart(partNum, colorId: colorId);
      final count = items.fold<int>(0, (sum, i) => sum + i.quantity);
      return MapEntry(_inventoryKey(part), count);
    }));

    final partNum = group.partNum;
    final colorsByNeed = <int, NeededColor>{};
    for (final p in group.parts) {
      final cid = int.tryParse(p.color ?? '');
      if (cid == null) continue;
      final prev = colorsByNeed[cid];
      colorsByNeed[cid] = NeededColor(
        colorId: cid,
        qty: (prev?.qty ?? 0) + p.quantity,
        name: p.colorName ?? prev?.name,
      );
    }
    final needList = colorsByNeed.values.toList()..sort((a, b) => b.qty.compareTo(a.qty));
    final candidates = await PartImageResolver.resolveCandidates(partNum, needList);
    final top = needList.isEmpty ? null : needList.first;

    if (!mounted) return;
    setState(() {
      for (final entry in counts) {
        _inventoryCounts[entry.key] = entry.value;
      }
      _headerCandidates = candidates;
      _topNeed = top;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final factor = size.width % 350;

    final double maxCardWidth = 350 + factor;

    var sortedParts = group.parts.sorted((a, b) {
      if (moc.groupSort == PartSort.nameAsc || moc.groupSort == PartSort.nameDesc) {
        return moc.groupSort == PartSort.nameAsc ? a.colorName!.compareTo(b.colorName!) : b.colorName!.compareTo(a.colorName!);
      }

      if (moc.groupSort == PartSort.quantityAsc || moc.groupSort == PartSort.quantityDesc) {
        return moc.groupSort == PartSort.quantityAsc ? a.quantity.compareTo(b.quantity) : b.quantity.compareTo(a.quantity);
      }
      return moc.groupSort == PartSort.collectedAsc
          ? a.collectedCount.compareTo(b.collectedCount)
          : b.collectedCount.compareTo(a.collectedCount);
    });

    final sortedPartsCompleted = sortedParts.where((element) => moc.hideCompleteGroup ? element.collectedCount == element.quantity : false);
    sortedParts = sortedParts.where((element) => moc.hideCompleteGroup ? element.collectedCount != element.quantity : true).toList();

    final slivers = <Widget>[
      SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCardWidth,
          mainAxisSpacing: 0.0,
          crossAxisSpacing: 6.0,
          childAspectRatio: 5.0,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return _buildPartListItem(sortedParts.elementAt(index));
          },
          childCount: sortedParts.length,
        ),
      )
    ];

    if (moc.hideCompleteGroup && sortedPartsCompleted.isNotEmpty) {
      slivers.add(SliverToBoxAdapter(
          child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          "Completed",
          style: Theme.of(context).textTheme.titleLarge,
        ),
      )));
      slivers.add(SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCardWidth,
          mainAxisSpacing: 0.0,
          crossAxisSpacing: 6.0,
          childAspectRatio: 5.0,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return _buildPartListItem(sortedPartsCompleted.elementAt(index));
          },
          childCount: sortedPartsCompleted.length,
        ),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: moc.shoppingMode ? AppColors.highlightColor.withValues(alpha: 0.18) : null,
        title: Text(
          group.partName,
          maxLines: 2,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: const MyBackButton(),
        actions: [
          if (moc.shoppingMode)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
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
              ),
            ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(children: [
            Hero(
                tag: "part-img-${group.partNum}",
                child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SmartPartImage(
                        candidates: _headerCandidates.isNotEmpty
                            ? _headerCandidates
                            : (group.imgUrl.isNotEmpty ? [group.imgUrl] : const []),
                        onExhausted: _topNeed == null
                            ? null
                            : () => PartImageResolver.fetchApiUrl(group.partNum, _topNeed!.colorId),
                        fallback: const Icon(Icons.widgets_outlined, color: AppColors.textSecondary, size: 32),
                      ),
                    ))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("${group.collectedCount} / ${group.quantity}", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: group.partNum));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Part number copied")));
                  },
                  child: Row(
                    children: [
                      Text(group.partNum, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy, size: 14, color: AppColors.textSecondary),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                _buildShopLinks(),
              ]),
            ),
          ]),
        ),
        Expanded(
          child: group.parts.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: CustomScrollView(slivers: slivers),
                )
              : const Center(child: Text("No Parts", style: TextStyle(color: AppColors.textSecondary))),
        ),
      ]),
      bottomNavigationBar: BottomAppBar(
        color: moc.shoppingMode ? AppColors.highlightColor.withValues(alpha: 0.12) : null,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(onPressed: sortParts, icon: const Icon(Icons.sort)),
            IconButton(
                onPressed: showSettings,
                icon: Icon(moc.hideCompleteGroup ? Icons.disabled_visible : Icons.remove_red_eye)),
            IconButton(
                onPressed: _addColor,
                icon: const Icon(Icons.add_box_outlined),
                tooltip: 'Add colour'),
            const Spacer(),
            IconButton(
                onPressed: () { handleDeleteGroup(group.partNum); },
                icon: const Icon(Icons.delete))
          ],
        ),
      ),
    );
  }

  Widget _buildPartListItem(CollectablePart part) {
    final bool anyColor = part.color == "9999" || part.colorName == "No Color/Any Color";
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Slidable(
          // Specify a key if the Slidable is dismissible.
          key: ValueKey(part.color),

          // The start action pane is the one at the left or the top side.
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (ctx) {
                  _showEditQuantityModal(part);
                },
                backgroundColor: AppColors.highlightColor,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'Edit',
              ),
              SlidableAction(
                onPressed: (BuildContext context) {
                  handleCollected(part);
                },
                backgroundColor: const Color(0xFF7BC043),
                foregroundColor: Colors.white,
                icon: Icons.archive,
                label: 'Collected',
              ),
            ],
          ),

          // The end action pane is the one at the right or the bottom side.
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (BuildContext context) {
                  handleDeletePart(part);
                },
                backgroundColor: const Color(0xFFFE4A49),
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
              ),
            ],
          ),

          // The child of the Slidable is what the user sees when the
          // component is not dragged.
          child: ListTile(
              onTap: () {
                if (moc.shoppingMode) {
                  context.push(ScreenPaths.partSummary(part.part!), extra: part);
                } else {
                  _showCollectModal(part);
                }
              },
              dense: true,
              contentPadding: const EdgeInsets.only(left: 10),
              minVerticalPadding: 2,
              leading: AspectRatio(
                aspectRatio: 1,
                child: anyColor
                    ? const DiagonalStripePatternView()
                    : ColoredBox(
                        color: HexColor.fromHex(part.rgb!),
                      ),
              ),
              title: Text("${part.colorName}"),
              subtitle: Text(
                _inventoryCounts.containsKey(_inventoryKey(part))
                    ? "${part.collectedCount} / ${part.quantity} (${_inventoryCounts[_inventoryKey(part)]})"
                    : "${part.collectedCount} / ${part.quantity}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: (moc.shoppingMode && part.bricklinkId != null && part.bricklinkId!.isNotEmpty)
                  ? IconButton(
                      tooltip: 'Open on BrickLink',
                      icon: const Icon(Icons.open_in_new, size: 18, color: AppColors.highlightColor),
                      onPressed: () => _openBrickLink(part.bricklinkId!, bricklinkColor: part.bricklinkColor),
                    )
                  : null,
              )),
    );
  }

  void showSettings() async {
    moc.hideCompleteGroup = !moc.hideCompleteGroup;
    await mocLogic.saveMoc(moc);
    setState(() {});
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
      initialSelectedActionKey: moc.groupSort,
    );
    if (result == null) return;

    moc.groupSort = result;
    await mocLogic.saveMoc(moc);
    setState(() {});
  }

  void _showCollectModal(CollectablePart part) async {
    await showModalBottomSheet(
        context: context,
        builder: (context) {
          return CollectModal(part);
        });

    mocLogic.saveMoc(moc);
    setState(() {});
  }

  void _addColor() async {
    final existing = group.parts.map((p) => p.color).whereType<String>().toSet();
    final parts = await showModalBottomSheet<List<CollectablePart>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddPartModal(
        fixedPartId: group.partNum,
        partName: group.partName,
        existingColorIds: existing,
      ),
    );
    if (parts == null || parts.isEmpty) return;

    // mergeParts dedupes against existing entries: a same part+colour entry
    // gets its quantity bumped instead of becoming a duplicate row (the old
    // raw add created duplicates, which corrupted quantities on rebuild).
    moc.parts = appLogic.mergeParts(moc.parts ?? [], parts);
    for (final p in parts) {
      // Only genuinely new entries survive the merge as-is; merged ones
      // already exist in group.parts (same object, quantity updated).
      if (moc.parts!.contains(p) && !group.parts.contains(p)) {
        group.parts.add(p);
      }
    }
    await mocLogic.saveMoc(moc);
    if (!mounted) return;
    _loadInventoryCounts();
    setState(() {});
  }

  void _showEditQuantityModal(CollectablePart part) async {
    final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return EditQuantityModal(part);
        });

    if (saved == true) {
      mocLogic.saveMoc(moc);
      setState(() {});
    }
  }

  getPartsInCollection(BrickPart part) async {
    if (!appLogic.loggedIn) {
      await loginUser(context);
    }

    final parts = await rbService.getUserParts(partNum: part.part!, colorId: part.color!);

    if (parts == null || parts.isEmpty == true) {
      await showOkAlertDialog(context: context, title: "Parts in inventory", message: "You don't have this part in your inventory");
      return;
    }

    int partCount = 0;
    for (var p in parts) {
      partCount += p.quantity;
    }

    await showOkAlertDialog(context: context, title: "Parts in inventory", message: "$partCount");
  }

  void handleDeleteGroup(String partNum) async {
    final result = await showOkCancelAlertDialog(
      context: context,
      title: 'Delete Part Group',
      message: 'Do you really want to delete this part group from the collection?',
      canPop: false,
      isDestructiveAction: true,
    );
    if (result != OkCancelResult.ok) return;

    // Remove every colour of this part from the MOC, then leave the (now empty)
    // detail screen.
    moc.parts?.removeWhere((p) => p.part == partNum);
    group.parts.clear();
    await mocLogic.saveMoc(moc);
    if (!mounted) return;
    context.pop();
  }

  void handleCollected(CollectablePart part) async {
    part.collectedCount = part.quantity;

    mocLogic.saveMoc(moc);
    setState(() {});
  }

  void handleDeletePart(CollectablePart part) async {
    await mocLogic.deletePart(moc, group, part);
    if (!mounted) return;
    // Last colour gone → nothing left to show, return to the MOC.
    if (group.parts.isEmpty) {
      context.pop();
    } else {
      _loadInventoryCounts();
      setState(() {});
    }
  }

  Widget _buildShopLinks() {
    final goBrickPart = group.parts
        .map((p) => p.goBrickPart)
        .firstWhere((s) => s != null && s.isNotEmpty, orElse: () => null);
    final bricklinkId = group.parts
        .map((p) => p.bricklinkId)
        .firstWhere((s) => s != null && s.isNotEmpty, orElse: () => null);

    if (goBrickPart == null && bricklinkId == null) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (goBrickPart != null)
          _shopChip(
            label: 'Yourwobb',
            icon: Icons.shopping_bag_outlined,
            onTap: () => _openYourwobb(goBrickPart),
          ),
        if (bricklinkId != null)
          _shopChip(
            label: 'BrickLink',
            icon: Icons.open_in_new,
            onTap: () => _openBrickLink(bricklinkId),
          ),
      ],
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
}
