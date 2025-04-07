import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/CollectablePartGroup.dart';
import 'package:brick_collector/notifications/save_moc_notification.dart';
import 'package:brick_collector/ui/nav_menu.dart';
import 'package:brick_collector/ui/part_group_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

  MocScreenState();

  @override
  void initState() {
    super.initState();
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
        foregroundColor: Colors.white,
        title: Text("${moc.name} | ${moc.collectedCount} Collected"),
        // | ${moc.parts?.length ?? 0} Parts | ${moc.quantity} Quantity |
        automaticallyImplyLeading: true,
        actions: [IconButton(onPressed: userClick, icon: const Icon(Icons.person)), const SizedBox(width: 30, height: 0)],
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
      drawer: const Drawer(child: NavMenu()),
      body: NotificationListener<SaveMocNotification>(
        onNotification: _saveMoc,
        child: CustomScrollView(slivers: childs),
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100.0)),
        backgroundColor: const Color(0xFFF2542D),
        onPressed: _addParts,
        tooltip: 'Add parts',
        child: const Icon(Icons.add),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      extendBody: true,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.navItemBgColor,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
                onPressed: editMoc,
                icon: const Icon(
                  Icons.edit,
                  color: Colors.white,
                )),
            IconButton(
                onPressed: sortParts,
                icon: const Icon(
                  Icons.sort,
                  color: Colors.white,
                )),
            IconButton(
                onPressed: showSettings,
                icon: Icon(
                  moc.hideComplete ? Icons.disabled_visible : Icons.remove_red_eye,
                  color: Colors.white,
                )),
            const Spacer(),
            IconButton(
                onPressed: deleteMoc,
                icon: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ))
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

    final groups = appLogic.groupParts(moc.parts!);
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
    }).where((element) => moc.hideComplete ? element.collectedCount != element.quantity : true);

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 90),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCardWidth,
          mainAxisSpacing: 6.0,
          crossAxisSpacing: 6.0,
          childAspectRatio: 2.5,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return PartGroupCard(sortedParts.elementAt(index), moc);
          },
          childCount: sortedParts.length,
        ),
      ),
    );
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

  void showSettings() async {
    moc.hideComplete = !moc.hideComplete;
    await mocLogic.saveMoc(moc);
    setState(() {});
  }

  void userClick() async {
    if (!appLogic.loggedIn) {
      await loginUser(context);
    }
  }
}
