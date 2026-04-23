import 'package:brick_collector/model/cached_inventory_item.dart';
import 'package:brick_collector/model/cached_source.dart';
import 'package:brick_collector/model/filter_preset.dart';
import 'package:brick_collector/model/moc.dart';
import 'package:brick_collector/services/group_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

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

  Future<List<FilterPreset>> getPresets() async {
    final presets = await _isar.filterPresets.where().findAll();
    return presets;
  }

  savePreset(FilterPreset newPreset) async {
    await _isar.writeTxn(() async {
      await _isar.filterPresets.put(newPreset);
    });
  }

  deletePreset(FilterPreset preset) async {
    await _isar.writeTxn(() async {
      await _isar.filterPresets.delete(preset.id);
    });
  }

  // --- Inventory cache ---

  Future<void> clearInventoryCache() async {
    await _isar.writeTxn(() async {
      await _isar.cachedSources.clear();
      await _isar.cachedInventoryItems.clear();
    });
  }

  Future<void> upsertSource(CachedSource source) async {
    await _isar.writeTxn(() async {
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

  Future<List<CachedInventoryItem>> findItemsForPart(String partNum, {int? colorId}) async {
    var query = _isar.cachedInventoryItems.filter().partNumEqualTo(partNum);
    if (colorId != null) {
      return await query.and().colorIdEqualTo(colorId).findAll();
    }
    return await query.findAll();
  }

  Future<CachedSource?> getSource(CachedSourceType type, String externalId) async {
    return await _isar.cachedSources
        .filter()
        .typeEqualTo(type)
        .and()
        .externalIdEqualTo(externalId)
        .findFirst();
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
}
