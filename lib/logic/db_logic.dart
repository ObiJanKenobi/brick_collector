import 'dart:async';

import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/cached_inventory_item.dart';
import 'package:brick_collector/model/cached_source.dart';
import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/model/filter_preset.dart';
import 'package:brick_collector/model/set_sale.dart';
import 'package:brick_collector/services/group_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

/// Aggregated view of the user's inventory for preset display — one row per
/// (partNum, colorId), quantity summed across all sources (sets + partlists).
class AggregatedInventoryRow {
  AggregatedInventoryRow({
    required this.partNum,
    required this.colorId,
    this.partName,
    this.partCategoryId,
    this.colorName,
    this.rgb,
    this.imgUrl,
    this.quantity = 0,
  });
  final String partNum;
  final int colorId;
  String? partName;
  int? partCategoryId;
  String? colorName;
  String? rgb;
  String? imgUrl;
  int quantity;

  /// For the shared part cards; [quantity] is the owned count. [imgUrl] is
  /// deliberately not passed on as details: it shows one colour, while
  /// details.imgUrl is read as the image for the whole part group. The cards
  /// get per-colour images from the same cache via PartImageResolver.
  CollectablePart toCollectablePart() => CollectablePart(
        part: partNum,
        name: partName,
        color: colorId.toString(),
        colorName: colorName,
        rgb: rgb,
        quantity: quantity,
      );
}

class DbLogic {
  final Logger _log = getLogger('DbLogic');

  late final Isar _isar;

  Isar get isar => _isar;

  // --- Isar (FilterPresets, inventory cache) ---

  /// Uses an already opened [isar] instead of [bootstrap], for tests.
  @visibleForTesting
  void useIsar(Isar isar) => _isar = isar;

  Future<void> bootstrap() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [FilterPresetSchema, CachedSourceSchema, CachedInventoryItemSchema],
      directory: dir.path,
    );
  }

  // --- Legacy local presets (read-only — kept for one-time migration to Firestore) ---

  Future<List<FilterPreset>> readLegacyLocalPresets() async {
    return _isar.filterPresets.where().findAll();
  }

  Future<void> clearLegacyLocalPresets() async {
    await _isar.writeTxn(() async {
      await _isar.filterPresets.clear();
    });
  }

  // --- Inventory cache ---

  /// Source keys ("type_externalId") the user has excluded from inventory
  /// counts. Cached in memory so the frequently-called inventory queries don't
  /// re-read the sources table on every lookup.
  Set<String>? _excludedSourceKeys;

  String _sourceKey(CachedSourceType type, String externalId) => '${type.name}_$externalId';

  String _itemSourceKey(CachedInventoryItem it) => _sourceKey(it.sourceType, it.sourceExternalId);

  Future<Set<String>> _loadExcludedSourceKeys() async {
    final cached = _excludedSourceKeys;
    if (cached != null) return cached;
    final excluded = await _isar.cachedSources.filter().excludeFromInventoryEqualTo(true).findAll();
    final keys = excluded.map((s) => _sourceKey(s.type, s.externalId)).toSet();
    return _excludedSourceKeys = keys;
  }

  void _invalidateExcludedSourceKeys() => _excludedSourceKeys = null;

  Future<void> clearInventoryCache() async {
    await _isar.writeTxn(() async {
      await _isar.cachedSources.clear();
      await _isar.cachedInventoryItems.clear();
    });
    _invalidateExcludedSourceKeys();
  }

  Future<void> upsertSource(CachedSource source) async {
    await _isar.writeTxn(() async {
      // The unique (type, externalId) index replaces the whole row on put,
      // which would reset the locally-set exclusion flag on every sync —
      // carry it over from the existing row.
      final existing = await _isar.cachedSources
          .filter()
          .typeEqualTo(source.type)
          .and()
          .externalIdEqualTo(source.externalId)
          .findFirst();
      if (existing != null) {
        source.excludeFromInventory = existing.excludeFromInventory;
      }
      await _isar.cachedSources.put(source);
    });
  }

  Future<void> replaceSourceItems(
    CachedSourceType type,
    String externalId,
    List<CachedInventoryItem> items,
  ) async {
    await _isar.writeTxn(() async {
      await _isar.cachedInventoryItems
          .filter()
          .sourceTypeEqualTo(type)
          .and()
          .sourceExternalIdEqualTo(externalId)
          .deleteAll();
      if (items.isNotEmpty) {
        await _isar.cachedInventoryItems.putAll(items);
      }
    });
  }

  /// Items for a part across all sources. By default sources the user excluded
  /// from inventory are filtered out (so counts ignore them); pass
  /// [includeExcluded] to get every source — the caller can then check
  /// `CachedSource.excludeFromInventory` to render excluded ones differently.
  Future<List<CachedInventoryItem>> findItemsForPart(
    String partNum, {
    int? colorId,
    bool includeExcluded = false,
  }) async {
    var query = _isar.cachedInventoryItems.filter().partNumEqualTo(partNum);
    final items = colorId != null
        ? await query.and().colorIdEqualTo(colorId).findAll()
        : await query.findAll();
    if (includeExcluded) return items;
    final excluded = await _loadExcludedSourceKeys();
    if (excluded.isEmpty) return items;
    return items.where((it) => !excluded.contains(_itemSourceKey(it))).toList();
  }

  Future<CachedSource?> getSource(CachedSourceType type, String externalId) async {
    return await _isar.cachedSources
        .filter()
        .typeEqualTo(type)
        .and()
        .externalIdEqualTo(externalId)
        .findFirst();
  }

  /// Every cached item of one source, whether or not the source is excluded
  /// from inventory. Backs the set parts screen.
  Future<List<CachedInventoryItem>> getSourceItems(CachedSourceType type, String externalId) {
    return _isar.cachedInventoryItems
        .filter()
        .sourceTypeEqualTo(type)
        .and()
        .sourceExternalIdEqualTo(externalId)
        .findAll();
  }

  /// All cached sources of [type], sorted by name. Backs the "My Sets" screen.
  Future<List<CachedSource>> getSourcesByType(CachedSourceType type) async {
    return _isar.cachedSources.filter().typeEqualTo(type).sortByName().findAll();
  }

  /// Toggle whether a source's parts count toward inventory/available totals.
  /// Applied locally first (works offline), then mirrored to the group's
  /// Firestore exclusions doc so other devices pick it up.
  Future<void> setSourceExcluded(int id, bool excluded) async {
    CachedSource? src;
    await _isar.writeTxn(() async {
      src = await _isar.cachedSources.get(id);
      if (src == null) return;
      src!.excludeFromInventory = excluded;
      await _isar.cachedSources.put(src!);
    });
    _invalidateExcludedSourceKeys();

    final s = src;
    if (s == null || !GroupService.instance.hasGroup) return;
    // Local state stays authoritative until the next successful write/sync.
    _writeInBackground(
      () => _exclusionsRef.set({
        'keys': excluded
            ? FieldValue.arrayUnion([_sourceKey(s.type, s.externalId)])
            : FieldValue.arrayRemove([_sourceKey(s.type, s.externalId)]),
      }, SetOptions(merge: true)),
      'Could not sync "${s.name}" being ${excluded ? 'excluded from' : 'included in'} the inventory',
    );
  }

  /// [filterInventory] with [filter]'s criteria.
  Future<List<AggregatedInventoryRow>> filterInventoryFor(FilterPreset filter) => filterInventory(
        categoryIds: (filter.categories ?? const []).map((c) => c.id).toSet(),
        colorIds: (filter.colors ?? const []).map((c) => c.id).toSet(),
        searchText: filter.searchText,
      );

  /// Filter & aggregate the inventory cache by preset criteria. Returns one row
  /// per (partNum, colorId) with quantity summed across every matching source.
  /// Empty [categoryIds] = no category filter; empty [colorIds] = no color filter;
  /// empty/null [searchText] = no name filter.
  Future<List<AggregatedInventoryRow>> filterInventory({
    Set<int> categoryIds = const {},
    Set<int> colorIds = const {},
    String? searchText,
  }) async {
    final search = (searchText ?? '').trim();
    // Filter in Isar so only matching rows are deserialized. `optional` (not a
    // bare anyOf, which still adds an empty group) keeps unset criteria out.
    final rows = await _isar.cachedInventoryItems
        .filter()
        .optional(colorIds.isNotEmpty, (q) => q.anyOf(colorIds, (q, id) => q.colorIdEqualTo(id)))
        .and()
        .optional(categoryIds.isNotEmpty, (q) => q.anyOf(categoryIds, (q, id) => q.partCategoryIdEqualTo(id)))
        .and()
        .optional(search.isNotEmpty, (q) => q.partNameContains(search, caseSensitive: false))
        .findAll();
    final excluded = await _loadExcludedSourceKeys();
    final aggregated = <String, AggregatedInventoryRow>{};

    for (final it in rows) {
      if (excluded.contains(_itemSourceKey(it))) continue;

      final key = CollectablePart.keyFor(it.partNum, it.colorId);
      final existing = aggregated[key];
      if (existing == null) {
        aggregated[key] = AggregatedInventoryRow(
          partNum: it.partNum,
          colorId: it.colorId,
          partName: it.partName,
          partCategoryId: it.partCategoryId,
          colorName: it.colorName,
          rgb: it.rgb,
          imgUrl: it.imgUrl,
          quantity: it.quantity,
        );
      } else {
        existing.quantity += it.quantity;
        existing.partName ??= it.partName;
        existing.partCategoryId ??= it.partCategoryId;
        existing.colorName ??= it.colorName;
        existing.rgb ??= it.rgb;
        if ((existing.imgUrl ?? '').isEmpty && (it.imgUrl ?? '').isNotEmpty) {
          existing.imgUrl = it.imgUrl;
        }
      }
    }

    return aggregated.values.toList();
  }

  Future<void> pruneOrphanSources(CachedSourceType type, Set<String> keepExternalIds) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.cachedSources.filter().typeEqualTo(type).findAll();
      for (final src in existing) {
        if (keepExternalIds.contains(src.externalId)) continue;
        await _isar.cachedSources.delete(src.id);
        await _isar.cachedInventoryItems
            .filter()
            .sourceTypeEqualTo(type)
            .and()
            .sourceExternalIdEqualTo(src.externalId)
            .deleteAll();
      }
    });
  }

  // --- Firestore (source exclusions) ---

  /// Single doc per group holding every excluded source key
  /// ("type_externalId"), so exclusions follow the user across devices the
  /// same way presets do. Isar remains the local materialization that all
  /// inventory queries read.
  DocumentReference get _exclusionsRef => FirebaseFirestore.instance
      .collection('groups')
      .doc(GroupService.instance.groupCode)
      .collection('settings')
      .doc('exclusions');

  /// Excluded source keys from Firestore. Emits null while the doc does not
  /// exist yet (fresh group) so the subscriber can seed it from local state.
  Stream<Set<String>?> watchExcludedSourceKeys() {
    return _exclusionsRef.snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>?;
      final list = (data?['keys'] as List?) ?? const [];
      return list.whereType<String>().toSet();
    });
  }

  /// Writes the remote exclusion set onto the local source rows so every
  /// existing Isar-based query keeps working (including offline).
  Future<void> applyExcludedSourceKeys(Set<String> keys) async {
    await _isar.writeTxn(() async {
      final sources = await _isar.cachedSources.where().findAll();
      final changed = <CachedSource>[];
      for (final src in sources) {
        final shouldExclude = keys.contains(_sourceKey(src.type, src.externalId));
        if (src.excludeFromInventory != shouldExclude) {
          src.excludeFromInventory = shouldExclude;
          changed.add(src);
        }
      }
      if (changed.isNotEmpty) {
        await _isar.cachedSources.putAll(changed);
      }
    });
    // Remote is the source of truth; keep keys for sources that haven't been
    // synced locally yet so their items are filtered correctly either way.
    _excludedSourceKeys = keys;
  }

  /// Seeds the group's exclusions doc from local flags — used when a device
  /// with existing local exclusions connects to a group whose doc is missing.
  Future<void> pushLocalExclusionsToFirestore() async {
    if (!GroupService.instance.hasGroup) return;
    _invalidateExcludedSourceKeys();
    final keys = await _loadExcludedSourceKeys();
    if (keys.isEmpty) return;
    // Merge: a snapshot from an offline cache also reports a missing doc, and a
    // plain set() would then replace other devices' exclusions on reconnect.
    _writeInBackground(
      () => _exclusionsRef.set({'keys': FieldValue.arrayUnion(keys.toList())}, SetOptions(merge: true)),
      'Could not sync inventory exclusions',
    );
  }

  // --- Firestore (background writes) ---

  final StreamController<String> _writeErrors = StreamController.broadcast();

  /// Messages for background writes the server rejected; the app root shows
  /// them in a SnackBar.
  Stream<String> get writeErrors => _writeErrors.stream;

  /// Starts [write] without waiting for it. With offline persistence Firestore
  /// applies a write to its local cache (and so to every snapshot listener)
  /// right away, but the write's future only completes on server ack, so
  /// awaiting it would freeze the UI while offline. If the server rejects the
  /// write, Firestore rolls the local change back and [failure] is reported
  /// on [writeErrors]. So is anything [write] throws synchronously (e.g. from
  /// toJson), instead of escaping to the UI caller.
  void _writeInBackground(Future<void> Function() write, String failure) {
    unawaited(Future.sync(write).catchError((Object e) {
      _log.w('$failure: $e');
      _reportWriteError('$failure: $e');
    }));
  }

  final Map<String, DateTime> _writeErrorShownAt = {};

  /// Drops any message already reported in the last 10 s, so writes that keep
  /// failing (e.g. on every part toggle, even alternating between two
  /// failures) don't queue a SnackBar per tap.
  void _reportWriteError(String message) {
    final now = DateTime.now();
    _writeErrorShownAt.removeWhere((_, at) => now.difference(at) >= const Duration(seconds: 10));
    if (_writeErrorShownAt.containsKey(message)) return;
    _writeErrorShownAt[message] = now;
    _writeErrors.add(message);
  }

  // --- Firestore (Mocs) ---

  CollectionReference get _mocsRef => FirebaseFirestore.instance
      .collection('groups')
      .doc(GroupService.instance.groupCode)
      .collection('mocs');

  Stream<List<Moc>> watchMocs() {
    return _mocsRef.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Moc.fromFirestore(doc)).toList(),
        );
  }

  /// Saves [moc] in the background (see [_writeInBackground]) and returns its
  /// document id, assigning a new one first if the MOC is unsaved.
  ///
  /// There is deliberately no client-side size check: Firestore counts bytes
  /// differently from any local estimate, so a check would either block MOCs
  /// the server accepts or let through ones it rejects. A rejection (e.g. a
  /// document over 1 MiB) is reported like any other.
  String saveMoc(Moc moc) {
    final id = moc.firestoreId ??= _mocsRef.doc().id;
    _writeInBackground(() => _mocsRef.doc(id).set(moc.toJson()), 'Could not save "${moc.name}"');
    return id;
  }

  /// Deletes [moc] in the background (see [_writeInBackground]).
  void deleteMoc(Moc moc) {
    final id = moc.firestoreId;
    if (id == null) return;
    _writeInBackground(() => _mocsRef.doc(id).delete(), 'Could not delete "${moc.name}"');
  }

  // --- Firestore (set sales) ---

  /// One doc per set put up for sale ("Verkauf"), keyed by set number.
  CollectionReference get _setSalesRef => FirebaseFirestore.instance
      .collection('groups')
      .doc(GroupService.instance.groupCode)
      .collection('setSales');

  Stream<SetSale> watchSetSale(String setNum) {
    return _setSalesRef
        .doc(setNum)
        .snapshots()
        .map((doc) => SetSale.fromJson(doc.data() as Map<String, dynamic>?));
  }

  /// Merges the given changes into [setNum]'s sale in the background (see
  /// [_writeInBackground]). Only what changed is written, so two devices
  /// collecting the same set at once don't overwrite each other's counts.
  /// [collected] maps part keys to new counts; 0 removes the entry.
  void updateSetSale(String setNum, {bool? active, bool? hideComplete, Map<String, int> collected = const {}}) {
    final fields = setSaleFields(active: active, hideComplete: hideComplete, collected: collected);
    if (fields.isEmpty) return;
    _writeInBackground(
      () => _setSalesRef.doc(setNum).set(fields, SetOptions(merge: true)),
      'Could not save the Verkauf progress of $setNum',
    );
  }

  /// The fields [updateSetSale] merges into a sale document. [deleteField]
  /// marks an entry to remove; tests pass their own marker.
  static Map<String, Object> setSaleFields({
    bool? active,
    bool? hideComplete,
    Map<String, int> collected = const {},
    Object Function() deleteField = FieldValue.delete,
  }) =>
      {
        if (active != null) 'active': active,
        if (hideComplete != null) 'hideComplete': hideComplete,
        if (collected.isNotEmpty)
          'collected': {for (final e in collected.entries) e.key: e.value > 0 ? e.value : deleteField()},
      };

  // --- Firestore (FilterPresets) ---

  CollectionReference get _presetsRef => FirebaseFirestore.instance
      .collection('groups')
      .doc(GroupService.instance.groupCode)
      .collection('presets');

  Stream<List<FilterPreset>> watchPresets() {
    return _presetsRef.snapshots().map(
          (snapshot) => snapshot.docs.map(FilterPreset.fromFirestore).toList(),
        );
  }

  /// Saves [preset] in the background (see [_writeInBackground]) and returns
  /// its document id, assigning a new one first if the preset is unsaved.
  String savePreset(FilterPreset preset) {
    final id = _presetId(preset);
    _writeInBackground(() => savePresetAndWait(preset), 'Could not save preset "${preset.name}"');
    return id;
  }

  /// Like [savePreset], but waits for the server and throws if it rejects the
  /// write, so it blocks while offline. Only for flows that run in the
  /// background and must know the outcome.
  Future<void> savePresetAndWait(FilterPreset preset) async {
    await _presetsRef.doc(_presetId(preset)).set(preset.toJson());
  }

  /// [preset]'s document id, assigning a new one if it is unsaved.
  String _presetId(FilterPreset preset) => preset.firestoreId ??= _presetsRef.doc().id;

  /// Deletes [preset] in the background (see [_writeInBackground]).
  void deletePreset(FilterPreset preset) {
    final id = preset.firestoreId;
    if (id == null) return;
    _writeInBackground(() => _presetsRef.doc(id).delete(), 'Could not delete preset "${preset.name}"');
  }
}
