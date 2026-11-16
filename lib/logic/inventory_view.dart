import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/logic/db_logic.dart';
import 'package:brick_collector/model/CollectablePartGroup.dart';
import 'package:brick_collector/model/filter_preset.dart';
import 'package:brick_collector/services/collection_sync_service.dart';
import 'package:brick_collector/util/format_age.dart';

/// The synced inventory narrowed by a filter, grouped by part and sorted by
/// quantity: what the preset and All Parts screens list.
class InventoryView {
  InventoryView(List<AggregatedInventoryRow> rows, this.lastSync)
      : partCount = rows.length,
        totalQty = rows.fold(0, (sum, r) => sum + r.quantity),
        groups = appLogic.groupParts(rows.map((r) => r.toCollectablePart()).toList()).values.toList()
          ..sort((a, b) => b.quantity.compareTo(a.quantity));

  final List<CollectablePartGroup> groups;

  /// Distinct part + colour combinations.
  final int partCount;
  final int totalQty;
  final DateTime? lastSync;

  /// E.g. "12 parts · 340 total · inventory 3h ago".
  String get summary {
    final age = lastSync == null ? 'never synced' : 'inventory ${formatAge(lastSync!)}';
    return '$partCount parts · $totalQty total · $age';
  }

  static Future<InventoryView> load(FilterPreset filter) async {
    // Independent reads, run together. Future.wait handles both errors and
    // rethrows the first, so a second failure can't go unhandled.
    final results = await Future.wait([
      dbLogic.filterInventoryFor(filter),
      collectionSyncService.getLastSyncAt(),
    ]);
    return InventoryView(results[0] as List<AggregatedInventoryRow>, results[1] as DateTime?);
  }
}
