import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/CollectablePartGroup.dart';
import 'package:brick_collector/notifications/save_moc_notification.dart';
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(moc.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text("${moc.collectedCount} / ${moc.quantity} collected",
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
        child: Row(
          children: [
            IconButton(onPressed: editMoc, icon: const Icon(Icons.edit), tooltip: 'Rename'),
            IconButton(onPressed: _addParts, icon: const Icon(Icons.file_download), tooltip: 'Import CSV'),
            if (moc.sourceUrl != null)
              IconButton(onPressed: _openOnRebrickable, icon: const Icon(Icons.open_in_browser), tooltip: 'Rebrickable'),
            IconButton(onPressed: sortParts, icon: const Icon(Icons.sort), tooltip: 'Sort'),
            IconButton(
                onPressed: showSettings,
                icon: Icon(moc.hideComplete ? Icons.disabled_visible : Icons.remove_red_eye),
                tooltip: 'Toggle completed'),
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
      padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8, top: 8),
      sliver: SliverList.builder(
        itemBuilder: (BuildContext context, int index) {
          return PartGroupCard(sortedParts.elementAt(index), moc);
        },
        itemCount: sortedParts.length,
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

  void _openOnRebrickable() async {
    final uri = Uri.parse(moc.sourceUrl!);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

}
