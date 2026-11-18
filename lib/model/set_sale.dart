import 'dart:math';

import 'package:brick_collector/model/collectable_part.dart';

/// Progress of collecting one of the user's sets back out of the inventory to
/// sell it ("Verkauf"). Stored per group in Firestore like a MOC, so it follows
/// the user across devices. The parts themselves come from the inventory cache;
/// only the collected counts live here.
class SetSale {
  SetSale({this.active = false, this.hideComplete = false, Map<String, int>? collected})
      : collected = collected ?? {};

  /// Whether the set is in Verkauf mode, i.e. its parts can be collected.
  bool active;

  bool hideComplete;

  /// Collected count per [CollectablePart.partColorKey]; unlisted parts have
  /// none.
  final Map<String, int> collected;

  /// A missing document (a set never put up for sale) reads as a fresh sale.
  factory SetSale.fromJson(Map<String, dynamic>? json) {
    final raw = json?['collected'];
    return SetSale(
      active: json?['active'] == true,
      hideComplete: json?['hideComplete'] == true,
      collected: {
        if (raw is Map)
          for (final e in raw.entries)
            if (e.value is num) '${e.key}': (e.value as num).toInt(),
      },
    );
  }

  Map<String, dynamic> toJson() => {
        'active': active,
        'hideComplete': hideComplete,
        'collected': collected,
      };

  /// Sets each part's collected count from this sale, capped at the part's
  /// quantity in case the set's inventory shrank since it was collected.
  void applyTo(Iterable<CollectablePart> parts) {
    for (final part in parts) {
      part.collectedCount = _shown(part);
    }
  }

  /// Takes the counts the user changed on [parts] into this sale. A count
  /// still showing what [applyTo] set is kept as stored: it may exceed a
  /// quantity that shrank for now, and comes back if the inventory regrows.
  /// Entries for parts not in [parts] are kept too, so a partial or empty
  /// inventory cache can't wipe progress.
  void readFrom(Iterable<CollectablePart> parts) {
    for (final part in parts) {
      if (part.collectedCount == _shown(part)) continue;
      if (part.collectedCount > 0) {
        collected[part.partColorKey] = part.collectedCount;
      } else {
        collected.remove(part.partColorKey);
      }
    }
  }

  int _shown(CollectablePart part) => min(collected[part.partColorKey] ?? 0, part.quantity);
}
