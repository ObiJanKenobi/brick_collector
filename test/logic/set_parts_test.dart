import 'package:brick_collector/logic/set_parts.dart';
import 'package:brick_collector/model/cached_inventory_item.dart';
import 'package:brick_collector/model/cached_source.dart';
import 'package:flutter_test/flutter_test.dart';

CachedInventoryItem _item(String partNum, int colorId, int qty, {bool spare = false}) => CachedInventoryItem()
  ..sourceType = CachedSourceType.set
  ..sourceExternalId = '31111-1'
  ..partNum = partNum
  ..partName = 'Part $partNum'
  ..colorId = colorId
  ..colorName = 'Color $colorId'
  ..rgb = 'FFFFFF'
  ..quantity = qty
  ..isSpare = spare;

void main() {
  group('SetPartList.fromCache', () {
    test('merges a spare row into its part and colour, and counts it', () {
      final list = SetPartList.fromCache([
        _item('3001', 4, 3),
        _item('3001', 4, 1, spare: true),
        _item('3001', 0, 2),
      ]);

      expect(list.parts, hasLength(2));
      final red = list.parts.firstWhere((p) => p.color == '4');
      expect(red.part, '3001');
      expect(red.name, 'Part 3001');
      expect(red.quantity, 4);
      expect(list.quantity, 6);
      expect(list.spareCount, 1);
    });

    test('divides the owned copies back out to one set', () {
      final list = SetPartList.fromCache([
        _item('3001', 4, 6),
        _item('3001', 4, 2, spare: true),
      ], copies: 2);

      expect(list.parts.single.quantity, 4);
      expect(list.spareCount, 1);
    });

    test('keeps a part whose row is smaller than the copies', () {
      final list = SetPartList.fromCache([_item('3001', 4, 1)], copies: 3);
      expect(list.parts.single.quantity, 1);
    });

    test('treats zero copies as one', () {
      final list = SetPartList.fromCache([_item('3001', 4, 2)], copies: 0);
      expect(list.parts.single.quantity, 2);
    });

    test('sums collected counts', () {
      final list = SetPartList.fromCache([_item('3001', 4, 3), _item('3020', 1, 2)]);
      list.parts[0].collectedCount = 2;
      list.parts[1].collectedCount = 1;
      expect(list.collectedCount, 3);
    });

    test('is empty without cached rows', () {
      final list = SetPartList.fromCache(const []);
      expect(list.parts, isEmpty);
      expect(list.quantity, 0);
      expect(list.spareCount, 0);
    });
  });
}
