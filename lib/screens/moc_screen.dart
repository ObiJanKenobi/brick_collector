import 'dart:convert';
import 'dart:io';

import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/CollectablePartGroup.dart';
import 'package:brick_collector/notifications/save_moc_notification.dart';
import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/ui/modals/add_part_modal.dart';
import 'package:brick_collector/ui/modals/moc_filter_modal.dart';
import 'package:brick_collector/ui/nav_menu.dart';
import 'package:brick_collector/ui/part_group_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
            IconButton(onPressed: editMoc, icon: const Icon(Icons.edit), tooltip: 'Edit (name & image)'),
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
            if (moc.shoppingMode && moc.parts?.isNotEmpty == true)
              IconButton(
                onPressed: _orderOnBrickwith,
                icon: const Icon(Icons.storefront),
                tooltip: 'Order on Brickwith',
              ),
            const Spacer(),
            IconButton(onPressed: deleteMoc, icon: const Icon(Icons.delete), tooltip: 'Delete'),
          ],
        ),
      ),
    );
  }

  editMoc() async {
    final controller = TextEditingController(text: moc.name);

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          Uint8List? bytes;
          final b64 = moc.imageBase64;
          if (b64 != null) {
            try {
              bytes = base64Decode(b64);
            } catch (_) {/* corrupt data — show placeholder */}
          }
          return AlertDialog(
            title: const Text('Edit MOC'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tap the preview to pick/replace the image.
                  InkWell(
                    onTap: () async {
                      if (await _chooseAndSaveImage()) setLocal(() {});
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.highlightColor.withValues(alpha: 0.4)),
                        image: bytes != null
                            ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: bytes == null
                          ? const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.textSecondary),
                                SizedBox(height: 6),
                                Text('Add image', style: TextStyle(color: AppColors.textSecondary)),
                              ],
                            )
                          : null,
                    ),
                  ),
                  if (bytes != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          if (await _removeImage()) setLocal(() {});
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Remove image'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Name'),
                    onSubmitted: (_) => Navigator.of(ctx).pop(true),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save')),
            ],
          );
        },
      ),
    );

    // Image changes are applied immediately inside the dialog; only the name
    // is committed on Save.
    if (save == true) {
      final name = controller.text.trim();
      if (name.isNotEmpty && name != moc.name) {
        moc.name = name;
        await mocLogic.saveMoc(moc);
      }
    }
    if (mounted) setState(() {});
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

  /// Builds a BrickLink "Wanted List" XML from the MOC's parts. Brickwith (and
  /// the GoBricks backend) ingests this format and converts the BrickLink part
  /// id + colour to GoBricks server-side. Falls back to the LEGO/Rebrickable
  /// design id when no BrickLink id is known, and omits the colour when unknown
  /// rather than emitting a bogus value.
  String _buildBricklinkXml(List<CollectablePart> parts) {
    final buf = StringBuffer('<INVENTORY>\n');
    for (final p in parts) {
      final id = (p.bricklinkId != null && p.bricklinkId!.isNotEmpty)
          ? p.bricklinkId!
          : (p.part ?? '');
      if (id.isEmpty || p.quantity <= 0) continue;
      buf.writeln('\t<ITEM>');
      buf.writeln('\t\t<ITEMTYPE>P</ITEMTYPE>');
      buf.writeln('\t\t<ITEMID>$id</ITEMID>');
      final color = p.bricklinkColor;
      if (color != null && color.isNotEmpty) {
        buf.writeln('\t\t<COLOR>$color</COLOR>');
      }
      buf.writeln('\t\t<MINQTY>${p.quantity}</MINQTY>');
      buf.writeln('\t</ITEM>');
    }
    buf.write('</INVENTORY>');
    return buf.toString();
  }

  /// Copies the part list to the clipboard AND writes it to a file, then opens
  /// Brickwith's upload page. A launched URL can't pre-fill a web upload box, so
  /// on desktop we reveal the file in Finder/Explorer (drag it into the browser)
  /// and on mobile we open the share sheet; either way the list is one paste or
  /// one drop away.
  Future<void> _orderOnBrickwith() async {
    final messenger = ScaffoldMessenger.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    final parts = moc.parts ?? const <CollectablePart>[];

    final xml = _buildBricklinkXml(parts);
    final itemCount = '<ITEMID>'.allMatches(xml).length;
    if (itemCount == 0) {
      messenger.showSnackBar(const SnackBar(
          content: Text('No parts with a known BrickLink or LEGO id to export.')));
      return;
    }

    // (1) Clipboard — paste straight into Brickwith's list box.
    await Clipboard.setData(ClipboardData(text: xml));

    // (2) Write the file (Downloads on desktop, temp dir elsewhere).
    final safeName = moc.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    final date = DateTime.now().toIso8601String().split('T').first;
    File? file;
    try {
      file = await _writeExportFile('brickwith-$safeName-$date.xml', xml);
    } catch (_) {
      // Non-fatal — the clipboard copy still lets the user paste the list.
    }

    // (3) Surface the file: reveal on desktop, share sheet on mobile.
    final isDesktop =
        !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
    if (file != null && !kIsWeb) {
      if (isDesktop) {
        await _revealInFileManager(file);
      } else if (Platform.isIOS || Platform.isAndroid) {
        await SharePlus.instance.share(ShareParams(
          files: [XFile(file.path)],
          subject: 'Brickwith part list — ${moc.name}',
          sharePositionOrigin: renderBox != null
              ? renderBox.localToGlobal(Offset.zero) & renderBox.size
              : null,
        ));
      }
    }

    // (4) Open Brickwith's upload page.
    await launchUrl(Uri.parse('https://www.brickwith.com/en/part-list/upload'),
        mode: LaunchMode.externalApplication);

    // (5) Tell the user how to finish (the upload itself can't be automated).
    if (!mounted) return;
    final hint = isDesktop
        ? 'File revealed in ${Platform.isMacOS ? 'Finder' : 'your file manager'} — drag it onto the upload box, or paste (${Platform.isMacOS ? '⌘' : 'Ctrl'}+V) the list.'
        : 'List copied to clipboard — paste it, or use the shared file.';
    messenger.showSnackBar(SnackBar(
      content: Text('$itemCount parts ready for Brickwith. $hint'),
      duration: const Duration(seconds: 6),
    ));
  }

  /// Writes [contents] to [name] in the Downloads folder on desktop (so the user
  /// can find it to drag into the browser), or the temp dir on mobile/web.
  Future<File> _writeExportFile(String name, String contents) async {
    Directory? dir;
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      dir = await getDownloadsDirectory();
    }
    dir ??= await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$name');
    await file.writeAsString(contents);
    return file;
  }

  /// Opens the OS file manager with [file] selected (macOS Finder / Windows
  /// Explorer) or its containing folder (Linux has no portable "select").
  Future<void> _revealInFileManager(File file) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', file.path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', ['/select,${file.path}']);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [file.parent.path]);
      }
    } catch (_) {
      // Best-effort — the file is written and the list is on the clipboard.
    }
  }

  /// Picks an image and stores it on the MOC. Returns true if the image changed.
  /// Called from the edit dialog; shows progress/result via the Scaffold.
  Future<bool> _chooseAndSaveImage() async {
    final messenger = ScaffoldMessenger.of(context);

    final List<int>? bytes;
    try {
      bytes = await mocLogic.pickImageBytes();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not open picker: $e')));
      return false;
    }
    if (bytes == null) return false; // User cancelled the picker.

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
      messenger.showSnackBar(
        const SnackBar(content: Text('Image saved'), duration: Duration(seconds: 2)),
      );
      return true;
    } catch (e) {
      progress.close();
      messenger.showSnackBar(SnackBar(content: Text('Could not set image: $e')));
      return false;
    }
  }

  /// Clears the MOC image. Returns true (always changes state).
  Future<bool> _removeImage() async {
    final messenger = ScaffoldMessenger.of(context);
    await mocLogic.clearMocImage(moc);
    messenger.showSnackBar(
      const SnackBar(content: Text('Image removed'), duration: Duration(seconds: 2)),
    );
    return true;
  }
}
