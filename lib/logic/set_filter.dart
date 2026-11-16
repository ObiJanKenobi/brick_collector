import 'package:brick_collector/model/cached_source.dart';

/// [sets] whose name or set number contains [query] (case-insensitive), and
/// with [countedOnly] only those counted toward inventory.
List<CachedSource> filterSets(List<CachedSource> sets, {String query = '', bool countedOnly = false}) {
  final q = query.trim().toLowerCase();
  return sets
      .where((s) =>
          (!countedOnly || !s.excludeFromInventory) &&
          (q.isEmpty || s.name.toLowerCase().contains(q) || s.externalId.toLowerCase().contains(q)))
      .toList();
}
