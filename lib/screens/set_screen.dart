import 'dart:async';

import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/logic/part_sort.dart';
import 'package:brick_collector/logic/set_parts.dart';
import 'package:brick_collector/model/cached_source.dart';
import 'package:brick_collector/model/set_sale.dart';
import 'package:brick_collector/notifications/save_moc_notification.dart';
import 'package:brick_collector/ui/back_button.dart';
import 'package:brick_collector/ui/load_error_view.dart';
import 'package:brick_collector/ui/modals/sync_progress_modal.dart';
import 'package:brick_collector/ui/part_group_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// The parts of one copy of a set, spares included, read from the inventory
/// cache. "Verkauf" mode turns the list into a MOC-style checklist for
/// collecting the set's parts back out of the inventory to sell it.
class SetScreen extends StatefulWidget {
  const SetScreen(this.setNum, {this.initial, super.key});

  final String setNum;

  /// The set as My Sets listed it, to show its name straight away. The screen
  /// re-reads it from the cache, which a sync may have changed since.
  final CachedSource? initial;

  @override
  State<StatefulWidget> createState() => SetScreenState();
}

class SetScreenState extends State<SetScreen> {
  String get _setNum => widget.setNum;

  late CachedSource? _set = widget.initial;

  String get _name => _set?.name ?? _setNum;

  SetPartList? _list;
  Object? _loadError;

  /// The set's parts as an unsaved MOC, so the part screen can show them.
  /// Collected counts go to the sale via [_saveIfChanged]; the part screen's
  /// sort and hide-completed stay on this object for the visit. Never saved
  /// as a MOC.
  Moc? _moc;

  /// Null until the first snapshot; the Verkauf toggle waits for it so a save
  /// can't replace progress that hasn't been read yet.
  SetSale? _sale;
  StreamSubscription<SetSale>? _saleSub;

  PartSort _sort = PartSort.nameAsc;

  bool get _selling => _sale?.active == true;

  @override
  void initState() {
    super.initState();
    _loadParts();
    _saleSub = dbLogic.watchSetSale(_setNum).listen(_onSale, onError: _onSaleError);
  }

  @override
  void dispose() {
    _saleSub?.cancel();
    super.dispose();
  }

  Future<void> _loadParts() async {
    try {
      // Read together with the items: the copy count they were stored with
      // may have changed in a sync since My Sets listed the set.
      final source = await dbLogic.getSource(CachedSourceType.set, _setNum);
      final items = await dbLogic.getSourceItems(CachedSourceType.set, _setNum);
      if (!mounted) return;
      final set = source ?? _set;
      final list = SetPartList.fromCache(items, copies: set?.ownedQuantity ?? 1);
      _sale?.applyTo(list.parts);
      setState(() {
        _set = set;
        _list = list;
        // Kept across reloads, so the part screen's settings survive a sync.
        _moc = (_moc ?? Moc(name: _name))..parts = list.parts;
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  void _retryLoad() {
    setState(() => _loadError = null);
    _loadParts();
  }

  void _onSale(SetSale sale) {
    final list = _list;
    if (list != null) sale.applyTo(list.parts);
    setState(() => _sale = sale);
  }

  void _onSaleError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load the Verkauf progress: $e')));
  }

  void _saveSale() {
    final sale = _sale;
    if (sale == null) return;
    final list = _list;
    if (list != null) sale.readFrom(list.parts);
    dbLogic.saveSetSale(_setNum, sale);
  }

  void _toggleSelling() {
    setState(() => _sale!.active = !_sale!.active);
    _saveSale();
  }

  void _toggleHideComplete() {
    setState(() => _sale!.hideComplete = !_sale!.hideComplete);
    _saveSale();
  }

  /// A card's collect modal closed. It reports this whether or not anything
  /// was saved, so [_saveIfChanged] only writes when a count changed.
  bool _onCollected(SaveMocNotification notification) {
    _saveIfChanged();
    return true;
  }

  /// Saves the collected counts if they differ from the sale's. Also the part
  /// screen's save hook, which calls it for its sort and filter changes too;
  /// those don't change the counts, so they just refresh this screen.
  void _saveIfChanged() {
    if (!mounted) return;
    final sale = _sale;
    final list = _list;
    if (sale != null && list != null) {
      final before = Map.of(sale.collected);
      sale.readFrom(list.parts);
      if (!const MapEquality<String, int>().equals(before, sale.collected)) {
        dbLogic.saveSetSale(_setNum, sale);
      }
    }
    setState(() {});
  }

  Future<void> _sortParts() async {
    final result = await showPartSortDialog(context, _sort);
    if (result == null || !mounted) return;
    setState(() => _sort = result);
  }

  Future<void> _syncCollection() async {
    await showSyncProgressModal(context);
    if (!mounted) return;
    await _loadParts();
  }

  Future<void> _openOnRebrickable() async {
    await launchUrl(Uri.parse('https://rebrickable.com/sets/$_setNum/'),
        mode: LaunchMode.externalApplication);
  }

  String get _subtitle {
    final list = _list;
    if (list == null) return _setNum;
    if (_selling) return '${list.collectedCount} / ${list.quantity} collected';
    final spares = list.spareCount > 0 ? ' · incl. ${list.spareCount} spare' : '';
    return '$_setNum · ${list.quantity} parts$spares';
  }

  @override
  Widget build(BuildContext context) {
    final selling = _selling;
    final hideComplete = _sale?.hideComplete == true;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: selling ? AppColors.highlightColor.withValues(alpha: 0.18) : null,
        leading: const MyBackButton(),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(_subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (selling) const _VerkaufBadge(),
          ],
        ),
      ),
      body: NotificationListener<SaveMocNotification>(
        onNotification: _onCollected,
        child: _buildBody(selling: selling, hideComplete: selling && hideComplete),
      ),
      bottomNavigationBar: BottomAppBar(
        color: selling ? AppColors.highlightColor.withValues(alpha: 0.12) : null,
        child: Row(
          children: [
            TextButton.icon(
              key: const Key('setVerkauf'),
              onPressed: _sale == null ? null : _toggleSelling,
              icon: Icon(selling ? Icons.sell : Icons.sell_outlined,
                  color: selling ? AppColors.highlightColor : AppColors.textPrimary),
              label: Text(
                'Verkauf',
                style: TextStyle(
                  color: selling ? AppColors.highlightColor : AppColors.textPrimary,
                  fontWeight: selling ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            IconButton(onPressed: _sortParts, icon: const Icon(Icons.sort), tooltip: 'Sort'),
            if (selling)
              IconButton(
                onPressed: _toggleHideComplete,
                icon: Icon(
                  hideComplete ? Icons.visibility_off : Icons.visibility_outlined,
                  color: hideComplete ? AppColors.highlightColor : null,
                ),
                tooltip: hideComplete ? 'Show completed' : 'Hide completed',
              ),
            const Spacer(),
            IconButton(
                onPressed: _openOnRebrickable, icon: const Icon(Icons.open_in_browser), tooltip: 'Rebrickable'),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({required bool selling, required bool hideComplete}) {
    if (_loadError != null) {
      return LoadErrorView(error: _loadError!, onRetry: _retryLoad, what: 'the parts of this set');
    }
    final list = _list;
    if (list == null) return const Center(child: CircularProgressIndicator());
    if (list.parts.isEmpty) {
      return _message(
        'No parts cached for this set yet.\nSync your collection to fetch them.',
        action: TextButton.icon(onPressed: _syncCollection, icon: const Icon(Icons.sync, size: 16), label: const Text('Sync')),
      );
    }

    final groups = appLogic
        .groupParts(list.parts)
        .values
        .where((g) => !hideComplete || g.collectedCount < g.quantity)
        .sorted((a, b) => comparePartGroups(a, b, _sort));
    if (groups.isEmpty) {
      return _message(
        'All parts collected.',
        action: TextButton.icon(
            onPressed: _toggleHideComplete,
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text('Show completed')),
      );
    }

    return CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8, top: 8),
        sliver: SliverList.builder(
          // Tapping a card opens the part screen, as on a MOC. Outside
          // Verkauf the cards just show quantities; inside, colours are
          // collected. A set's parts come from Rebrickable, so not editable.
          itemBuilder: (context, index) => PartGroupCard(
            groups[index],
            _moc,
            positiveQuantity: !selling,
            onSave: _saveIfChanged,
            collectable: selling,
            editable: false,
            key: ValueKey(groups[index].partNum),
          ),
          itemCount: groups.length,
        ),
      ),
    ]);
  }

  Widget _message(String text, {required Widget action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            action,
          ],
        ),
      ),
    );
  }
}

class _VerkaufBadge extends StatelessWidget {
  const _VerkaufBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.highlightColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.highlightColor.withValues(alpha: 0.6), width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sell, size: 12, color: AppColors.highlightColor),
          SizedBox(width: 4),
          Text('Verkauf',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.highlightColor, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}
