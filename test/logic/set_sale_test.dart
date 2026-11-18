import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/model/set_sale.dart';
import 'package:flutter_test/flutter_test.dart';

CollectablePart _part(String partNum, String color, int quantity, {int collected = 0}) =>
    CollectablePart(part: partNum, color: color, quantity: quantity)..collectedCount = collected;

void main() {
  group('SetSale', () {
    test('a missing document reads as a fresh, inactive sale', () {
      final sale = SetSale.fromJson(null);
      expect(sale.active, isFalse);
      expect(sale.hideComplete, isFalse);
      expect(sale.collected, isEmpty);
    });

    test('round-trips through JSON', () {
      final sale = SetSale(active: true, hideComplete: true, collected: {'3001_4': 3});
      final read = SetSale.fromJson(sale.toJson());
      expect(read.active, isTrue);
      expect(read.hideComplete, isTrue);
      expect(read.collected, {'3001_4': 3});
    });

    test('reads Firestore numbers and skips malformed entries', () {
      final sale = SetSale.fromJson({
        'active': true,
        'collected': {'3001_4': 2.0, '3020_1': 'x'},
      });
      expect(sale.collected, {'3001_4': 2});
    });

    test('applyTo restores counts, capped at the quantity', () {
      final red = _part('3001', '4', 2);
      final blue = _part('3001', '1', 5, collected: 4);
      SetSale(collected: {'3001_4': 5}).applyTo([red, blue]);
      expect(red.collectedCount, 2);
      expect(blue.collectedCount, 0);
    });

    test('readFrom keeps progress capped by a quantity that shrank', () {
      final sale = SetSale(collected: {'3001_4': 4, '3020_1': 3});
      final brick = _part('3001', '4', 2);
      final plate = _part('3020', '1', 2);
      sale.applyTo([brick, plate]);
      expect(brick.collectedCount, 2);

      plate.collectedCount = 1; // the user changes only the plate
      sale.readFrom([brick, plate]);
      expect(sale.collected, {'3001_4': 4, '3020_1': 1});
    });

    test('readFrom stores counts, drops zeros, and keeps unknown parts', () {
      final sale = SetSale(collected: {'3001_4': 1, '3020_1': 2, '9999_0': 7});
      sale.readFrom([
        _part('3001', '4', 3, collected: 3),
        _part('3020', '1', 2),
      ]);
      expect(sale.collected, {'3001_4': 3, '9999_0': 7});
    });
  });
}
