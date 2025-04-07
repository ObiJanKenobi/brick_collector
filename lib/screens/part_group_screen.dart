import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/CollectablePartGroup.dart';
import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/notifications/save_moc_notification.dart';
import 'package:brick_collector/ui/StripedContainer.dart';
import 'package:brick_collector/ui/app_colors.dart';
import 'package:brick_collector/ui/back_button.dart';
import 'package:brick_collector/ui/modals/collect_modal.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class PartGroupScreen extends StatefulWidget {
  final CollectablePartGroup group;
  final Moc moc;

  const PartGroupScreen(this.group, this.moc, {super.key});

  @override
  State<StatefulWidget> createState() => PartGroupScreenState();
}

class PartGroupScreenState extends State<PartGroupScreen> {
  PartGroupScreenState();

  CollectablePartGroup get group => widget.group;

  Moc get moc => widget.moc;

  @override
  void initState() {
    super.initState();
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
        foregroundColor: Colors.white,
        title: Text(
          "${group.partName}",
          maxLines: 2,
          style: const TextStyle(fontSize: 16),
        ),
        // | ${moc.parts?.length ?? 0} Parts | ${moc.quantity} Quantity |
        leading: const MyBackButton(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            height: 2,
            decoration: const BoxDecoration(color: AppColors.highlightColor
                // gradient: LinearGradient(
                //   colors: <Color>[Color(0xFFF2542D), Colors.red],
                // ),
                ),
          ),
        ),
      ),
      body: Stack(children: [
        Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(children: [
              Hero(
                  tag: "part-img-${group.partNum}",
                  child: CircleAvatar(
                      radius: 46,
                      backgroundColor: AppColors.navItemBgColor,
                      child: group.imgUrl.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircleAvatar(
                                radius: 44,
                                backgroundColor: Colors.white,
                                foregroundImage: CachedNetworkImageProvider(group.imgUrl),
                              ),
                            )
                          : const CircleAvatar(radius: 46, backgroundColor: Colors.white))),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text("Collected: ${group.collectedCount} / ${group.quantity}", style: Theme.of(context).textTheme.titleLarge),
                  GestureDetector(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: group.partNum));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Teilenummer in Zwischenablage kopiert")));
                    },
                    child: Text(
                      "Part-Number: ${group.partNum}",
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ]),
              ),
            ])),
        group.parts.isNotEmpty
            ? Positioned(
                top: 120,
                left: 10,
                right: 10,
                bottom: 0,
                child: CustomScrollView(
                  slivers: slivers,
                )
                // SingleChildScrollView(
                //   child: Column(children: group.parts.map((e) => _buildPartListItem(e)).toList()),
                // ),
                )
            : const Center(child: Text("No Parts"))
      ]),
      bottomNavigationBar: BottomAppBar(
        color: AppColors.navItemBgColor,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
                onPressed: sortParts,
                icon: const Icon(
                  Icons.sort,
                  color: Colors.white,
                )),
            IconButton(
                onPressed: showSettings,
                icon: Icon(
                  moc.hideCompleteGroup ? Icons.disabled_visible : Icons.remove_red_eye,
                  color: Colors.white,
                )),
            const Spacer(),
            IconButton(
                onPressed: () {
                  handleDeleteGroup(group.partNum);
                },
                icon: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ))
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
            // A motion is a widget used to control how the pane animates.
            motion: const DrawerMotion(),

            // A pane can dismiss the Slidable.
            dismissible: DismissiblePane(onDismissed: () {}),

            // All actions are defined in the children parameter.
            children: [
              // A SlidableAction can have an icon and/or a label.
              SlidableAction(
                onPressed: (BuildContext context) {
                  handleDeletePart(part);
                },
                backgroundColor: const Color(0xFFFE4A49),
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
              ),
              SlidableAction(
                onPressed: (ctx) {
                  getPartsInCollection(part);
                },
                backgroundColor: const Color(0xFF21B7CA),
                foregroundColor: Colors.white,
                icon: Icons.inventory,
                label: 'In collection',
              ),
            ],
          ),

          // The end action pane is the one at the right or the bottom side.
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (BuildContext context) {
                  handleCollected(part);
                },
                backgroundColor: const Color(0xFF7BC043),
                foregroundColor: Colors.white,
                icon: Icons.archive,
                label: 'Collected',
              )
            ],
          ),

          // The child of the Slidable is what the user sees when the
          // component is not dragged.
          child: ListTile(
              onTap: () {
                _showCollectModal(part);
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
                "${part.collectedCount} / ${part.quantity}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ))),
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
    );
    if (result == OkCancelResult.ok) {
      // await mocLogic.deletePart(moc, group, part);
    }
    setState(() {});
  }

  void handleCollected(CollectablePart part) async {
    part.collectedCount = part.quantity;

    mocLogic.saveMoc(moc);
    setState(() {});
  }

  void handleDeletePart(CollectablePart part) async {}
}
