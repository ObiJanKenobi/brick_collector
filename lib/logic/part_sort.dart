import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/CollectablePartGroup.dart';
import 'package:brick_collector/model/collectable_part.dart';

/// Orders part groups by [sort]; shared by the MOC and set screens.
int comparePartGroups(CollectablePartGroup a, CollectablePartGroup b, PartSort sort) =>
    _compare(sort, (a.partName, a.quantity, a.collectedCount), (b.partName, b.quantity, b.collectedCount));

/// Orders one part's colours by [sort], for the part screen. A missing colour
/// name sorts as empty.
int compareColors(CollectablePart a, CollectablePart b, PartSort sort) => _compare(
    sort, (a.colorName ?? '', a.quantity, a.collectedCount), (b.colorName ?? '', b.quantity, b.collectedCount));

int _compare(PartSort sort, (String, int, int) a, (String, int, int) b) {
  final (aName, aQuantity, aCollected) = a;
  final (bName, bQuantity, bCollected) = b;
  switch (sort) {
    case PartSort.nameAsc:
      return aName.compareTo(bName);
    case PartSort.nameDesc:
      return bName.compareTo(aName);
    case PartSort.quantityAsc:
      return aQuantity.compareTo(bQuantity);
    case PartSort.quantityDesc:
      return bQuantity.compareTo(aQuantity);
    case PartSort.collectedAsc:
      return aCollected.compareTo(bCollected);
    case PartSort.collectedDesc:
      return bCollected.compareTo(aCollected);
  }
}

/// Asks for a sort order, preselecting [current]. Null if dismissed.
Future<PartSort?> showPartSortDialog(BuildContext context, PartSort current) {
  return showConfirmationDialog<PartSort>(
    context: context,
    title: 'Select sort order',
    message: 'How to sort the parts',
    actions: PartSort.values.map((e) => AlertDialogAction(label: getLabel(e), key: e)).toList(),
    initialSelectedActionKey: current,
  );
}
