import 'package:brick_collector/model/cached_inventory_item.dart';
import 'package:brick_collector/model/cached_source.dart';
import 'package:brick_collector/model/filter_preset.dart';
import 'package:brick_collector/model/moc.dart';
import 'package:brick_collector/services/group_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar_community/isar.dart';
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
}

class DbLogic {
  late final Isar _isar;

  Isar get isar => _isar;

  // --- Isar (FilterPresets, inventory cache) ---

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
    // Fire and forget: with offline persistence the Future only completes on
    // server ack, and the local toggle must not hang on connectivity.
    _exclusionsRef.set({
      'keys': excluded
          ? FieldValue.arrayUnion([_sourceKey(s.type, s.externalId)])
          : FieldValue.arrayRemove([_sourceKey(s.type, s.externalId)]),
    }, SetOptions(merge: true)).catchError((Object e) {
      // Local state stays authoritative until the next successful write/sync.
    });
  }

  /// Filter & aggregate the inventory cache by preset criteria. Returns one row
  /// per (partNum, colorId) with quantity summed across every matching source.
  /// Empty [categoryIds] = no category filter; empty [colorIds] = no color filter;
  /// empty/null [searchText] = no name filter.
  Future<List<AggregatedInventoryRow>> filterInventory({
    Set<int> categoryIds = const {},
    Set<int> colorIds = const {},
    String? searchText,
  }) async {
    final rows = await _isar.cachedInventoryItems.where().findAll();
    final excluded = await _loadExcludedSourceKeys();
    final search = (searchText ?? '').trim().toLowerCase();
    final aggregated = <String, AggregatedInventoryRow>{};

    for (final it in rows) {
      if (excluded.contains(_itemSourceKey(it))) continue;
      if (colorIds.isNotEmpty && !colorIds.contains(it.colorId)) continue;
      if (categoryIds.isNotEmpty &&
          (it.partCategoryId == null || !categoryIds.contains(it.partCategoryId!))) continue;
      if (search.isNotEmpty) {
        final name = (it.partName ?? '').toLowerCase();
        if (!name.contains(search)) continue;
      }

      final key = '${it.partNum}_${it.colorId}';
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
    await _exclusionsRef.set({'keys': keys.toList()});
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

  Future<void> saveMoc(Moc moc) async {
    if (moc.firestoreId != null) {
      await _mocsRef.doc(moc.firestoreId).set(moc.toJson());
    } else {
      final docRef = await _mocsRef.add(moc.toJson());
      moc.firestoreId = docRef.id;
    }
  }

  Future<void> deleteMoc(Moc moc) async {
    if (moc.firestoreId != null) {
      await _mocsRef.doc(moc.firestoreId).delete();
    }
  }

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

  Future<void> savePreset(FilterPreset preset) async {
    if (preset.firestoreId != null) {
      await _presetsRef.doc(preset.firestoreId).set(preset.toJson());
    } else {
      final docRef = await _presetsRef.add(preset.toJson());
      preset.firestoreId = docRef.id;
    }
  }

  Future<void> deletePreset(FilterPreset preset) async {
    if (preset.firestoreId != null) {
      await _presetsRef.doc(preset.firestoreId).delete();
    }
  }
}
