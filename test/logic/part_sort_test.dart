import 'package:brick_collector/logic/part_sort.dart';
import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/model/moc.dart';
import 'package:flutter_test/flutter_test.dart';

CollectablePart _colour(String? name, int quantity, {int collected = 0}) =>
    CollectablePart(part: '3001', color: name, colorName: name, quantity: quantity)..collectedCount = collected;

void main() {
  test('colours sort by name, with a missing name first instead of crashing', () {
    final colours = [_colour('Red', 1), _colour(null, 1), _colour('Blue', 1)]
      ..sort((a, b) => compareColors(a, b, PartSort.nameAsc));
    expect(colours.map((c) => c.colorName), [null, 'Blue', 'Red']);
  });

  test('colours sort by quantity and by collected count', () {
    final few = _colour('Red', 1, collected: 1);
    final many = _colour('Blue', 5);
    expect(([many, few]..sort((a, b) => compareColors(a, b, PartSort.quantityAsc))).first, few);
    expect(([few, many]..sort((a, b) => compareColors(a, b, PartSort.collectedAsc))).first, many);
    expect(([few, many]..sort((a, b) => compareColors(a, b, PartSort.nameDesc))).first, few);
  });
}
