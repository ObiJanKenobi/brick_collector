import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/cached_inventory_item.dart';
import 'package:brick_collector/model/cached_source.dart';
import 'package:brick_lib/model/rebrickable_part_list.dart';
import 'package:brick_lib/model/rebrickable_set.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncFailure {
  SyncFailure(this.label, this.error);
  final String label;
  final String error;
}

class SyncProgress {
  SyncProgress({
    required this.done,
    required this.total,
    required this.label,
    this.finished = false,
    this.failed = false,
    this.error,
    this.failures = const [],
  });

  final int done;
  final int total;
  final String label;
  final bool finished;
  final bool failed;
  final String? error;
  final List<SyncFailure> failures;

  double get fraction => total == 0 ? 0 : done / total;
}

class CollectionSyncService {
  static const _lastSyncKey = 'collection_last_sync_at';

  final Logger _log = getLogger("CollectionSyncService");
  final BehaviorSubject<SyncProgress?> _progress = BehaviorSubject.seeded(null);
  bool _running = false;

  Stream<SyncProgress?> get progressStream => _progress.stream;
  SyncProgress? get current => _progress.value;
  bool get isRunning => _running;

  Future<DateTime?> getLastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastSyncKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<bool> isFresh({Duration maxAge = const Duration(hours: 24)}) async {
    final last = await getLastSyncAt();
    if (last == null) return false;
    return DateTime.now().difference(last) < maxAge;
  }

  Future<void> syncAll() async {
    if (_running) return;
    if (!appLogic.loggedIn) {
      _progress.add(SyncProgress(done: 0, total: 0, label: 'Not logged in', failed: true, finished: true, error: 'login_required'));
      return;
    }
    _running = true;
    final failures = <SyncFailure>[];

    try {
      _progress.add(SyncProgress(done: 0, total: 1, label: 'Fetching sets & lists…'));

      List<RebrickableUserSet> sets = [];
      List<RebrickablePartList> lists = [];
      try {
        final raw = await rbService.getUserSets();
        sets = _collapseDuplicateSets(raw);
      } catch (e) {
        failures.add(SyncFailure('User sets', e.toString()));
      }
      try {
        lists = await rbService.getUserPartLists() ?? <RebrickablePartList>[];
      } catch (e) {
        failures.add(SyncFailure('User part lists', e.toString()));
      }

      final total = sets.length + lists.length;
      var done = 0;

      for (final userSet in sets) {
        _progress.add(SyncProgress(
          done: done,
          total: total,
          label: 'Set ${done + 1}/${sets.length}: ${userSet.set.name}',
          failures: List.unmodifiable(failures),
        ));
        try {
          await _syncSet(userSet);
        } catch (e) {
          _log.w('Set ${userSet.set.setNum} failed: $e');
          failures.add(SyncFailure('${userSet.set.setNum} · ${userSet.set.name}', e.toString()));
        }
        done++;
      }

      for (final list in lists) {
        _progress.add(SyncProgress(
          done: done,
          total: total,
          label: 'List ${done - sets.length + 1}/${lists.length}: ${list.name}',
          failures: List.unmodifiable(failures),
        ));
        try {
          await _syncPartList(list);
        } catch (e) {
          _log.w('Partlist ${list.id} failed: $e');
          failures.add(SyncFailure('List · ${list.name}', e.toString()));
        }
        done++;
      }

      if (sets.isNotEmpty) {
        await dbLogic.pruneOrphanSources(
          CachedSourceType.set,
          sets.map((s) => s.set.setNum).toSet(),
        );
      }
      if (lists.isNotEmpty) {
        await dbLogic.pruneOrphanSources(
          CachedSourceType.partlist,
          lists.map((l) => l.id.toString()).toSet(),
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);

      _progress.add(SyncProgress(
        done: total,
        total: total,
        label: failures.isEmpty
            ? 'Done'
            : 'Done — ${failures.length} source${failures.length == 1 ? "" : "s"} failed',
        finished: true,
        failures: List.unmodifiable(failures),
      ));
    } catch (e, st) {
      _log.e('Sync failed: $e\n$st');
      _progress.add(SyncProgress(
        done: 0,
        total: 0,
        label: 'Sync failed',
        finished: true,
        failed: true,
        error: e.toString(),
        failures: List.unmodifiable(failures),
      ));
    } finally {
      _running = false;
    }
  }

  List<RebrickableUserSet> _collapseDuplicateSets(List<RebrickableUserSet> raw) {
    final byNum = <String, RebrickableUserSet>{};
    for (final u in raw) {
      final existing = byNum[u.set.setNum];
      if (existing == null) {
        byNum[u.set.setNum] = u;
      } else {
        existing.quantity += u.quantity;
      }
    }
    return byNum.values.toList();
  }

  Future<void> _syncSet(RebrickableUserSet userSet) async {
    final source = CachedSource()
      ..type = CachedSourceType.set
      ..externalId = userSet.set.setNum
      ..name = userSet.set.name
      ..imgUrl = userSet.set.setImgUrl
      ..numParts = userSet.set.numParts
      ..ownedQuantity = userSet.quantity
      ..year = userSet.set.year;
    await dbLogic.upsertSource(source);

    final parts = await rbService.getSetParts(userSet.set.setNum);
    final items = parts
        .where((p) => p.part.partNum != null)
        .map((p) {
          return CachedInventoryItem()
            ..sourceType = CachedSourceType.set
            ..sourceExternalId = userSet.set.setNum
            ..partNum = p.part.partNum!
            ..partName = p.part.name
            ..partCategoryId = p.part.partCatId
            ..colorId = p.color.id
            ..colorName = p.color.name
            ..rgb = p.color.rgb
            ..imgUrl = p.part.imgUrl
            ..quantity = p.quantity * userSet.quantity
            ..isSpare = false;
        })
        .toList();
    await dbLogic.replaceSourceItems(CachedSourceType.set, userSet.set.setNum, items);
  }

  Future<void> _syncPartList(RebrickablePartList list) async {
    final source = CachedSource()
      ..type = CachedSourceType.partlist
      ..externalId = list.id.toString()
      ..name = list.name
      ..numParts = list.partCount;
    await dbLogic.upsertSource(source);

    final parts = await rbService.getPartListItems(list.id);
    final items = parts
        .where((p) => p.part.partNum != null)
        .map((p) {
          return CachedInventoryItem()
            ..sourceType = CachedSourceType.partlist
            ..sourceExternalId = list.id.toString()
            ..partNum = p.part.partNum!
            ..partName = p.part.name
            ..partCategoryId = p.part.partCatId
            ..colorId = p.color.id
            ..colorName = p.color.name
            ..rgb = p.color.rgb
            ..imgUrl = p.part.imgUrl
            ..quantity = p.quantity
            ..isSpare = false;
        })
        .toList();
    await dbLogic.replaceSourceItems(CachedSourceType.partlist, list.id.toString(), items);
  }
}

CollectionSyncService get collectionSyncService => GetIt.I.get<CollectionSyncService>();
