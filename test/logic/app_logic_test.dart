import 'package:brick_collector/logic/app_logic.dart';
import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/model/moc.dart';
import 'package:flutter_test/flutter_test.dart';

CollectablePart part(
  String partNum,
  String color, {
  int quantity = 1,
  int collected = 0,
  String? colorName,
}) {
  final p = CollectablePart(
    part: partNum,
    color: color,
    quantity: quantity,
    colorName: colorName ?? 'Color $color',
    rgb: '6C6E68',
  );
  p.collectedCount = collected;
  return p;
}

void main() {
  final appLogic = AppLogic();

  group('groupParts', () {
    test('groups parts by part number', () {
      final parts = [
        part('3004', '72', quantity: 4),
        part('3004', '0', quantity: 2),
        part('3001', '72', quantity: 1),
      ];

      final groups = appLogic.groupParts(parts);

      expect(groups.keys, containsAll(['3004', '3001']));
      expect(groups['3004']!.parts, hasLength(2));
      expect(groups['3004']!.quantity, 6);
      expect(groups['3001']!.quantity, 1);
    });

    test('REGRESSION: repeated grouping must not mutate part quantities', () {
      // The original bug: moc.parts contained two entries with the same
      // part+colour. PartGroup.addPart merged them by MUTATING the first
      // entry's quantity (+= duplicate's quantity). Since the MOC screen
      // groups on every rebuild, each rebuild inflated the persisted
      // quantity further ("needed count grows when I tap a part").
      final dupA = part('3004', '72', quantity: 4);
      final dupB = part('3004', '72', quantity: 3);
      final parts = [dupA, dupB];

      // Simulate many widget rebuilds.
      for (var rebuild = 0; rebuild < 10; rebuild++) {
        appLogic.groupParts(parts);
      }

      expect(dupA.quantity, 4, reason: 'grouping must never mutate parts');
      expect(dupB.quantity, 3, reason: 'grouping must never mutate parts');
    });

    test('grouping is idempotent: same totals on every rebuild', () {
      final parts = [
        part('3004', '72', quantity: 4),
        part('3004', '72', quantity: 3),
        part('3004', '0', quantity: 2),
      ];

      final first = appLogic.groupParts(parts)['3004']!.quantity;
      final second = appLogic.groupParts(parts)['3004']!.quantity;
      final third = appLogic.groupParts(parts)['3004']!.quantity;

      expect(first, 9);
      expect(second, first);
      expect(third, first);
    });

    test('groups reference the original part objects (collect edits persist)',
        () {
      // CollectModal mutates collectedCount on the part it is given; that
      // only persists if the grouped part IS the object inside moc.parts.
      final original = part('3004', '72', quantity: 4);

      final groups = appLogic.groupParts([original]);

      expect(identical(groups['3004']!.parts.single, original), isTrue);
    });
  });

  group('mergeParts', () {
    test('sums quantity for existing part+colour instead of duplicating', () {
      final existing = [part('3004', '72', quantity: 4)];
      final incoming = [part('3004', '72', quantity: 2)];

      final merged = appLogic.mergeParts(existing, incoming);

      expect(merged, hasLength(1));
      expect(merged.single.quantity, 6);
    });

    test('appends genuinely new part+colour combinations', () {
      final existing = [part('3004', '72', quantity: 4)];
      final incoming = [
        part('3004', '0', quantity: 1), // same part, new colour
        part('3001', '72', quantity: 2), // new part
      ];

      final merged = appLogic.mergeParts(existing, incoming);

      expect(merged, hasLength(3));
    });

    test('merges duplicates within the incoming list itself', () {
      final merged = appLogic.mergeParts(
        [],
        [part('3004', '72', quantity: 1), part('3004', '72', quantity: 2)],
      );

      expect(merged, hasLength(1));
      expect(merged.single.quantity, 3);
    });
  });

  group('dedupeMocParts', () {
    test('merges duplicate part+colour entries, summing quantity and collected',
        () {
      final moc = Moc(name: 'test')
        ..parts = [
          part('3004', '72', quantity: 4, collected: 2),
          part('3004', '72', quantity: 3, collected: 1),
          part('3004', '0', quantity: 2),
        ];

      final changed = appLogic.dedupeMocParts(moc);

      expect(changed, isTrue);
      expect(moc.parts, hasLength(2));
      final darkGray = moc.parts!.firstWhere((p) => p.color == '72');
      expect(darkGray.quantity, 7);
      expect(darkGray.collectedCount, 3);
    });

    test('returns false and leaves clean lists untouched', () {
      final moc = Moc(name: 'test')
        ..parts = [
          part('3004', '72', quantity: 4),
          part('3004', '0', quantity: 2),
        ];

      expect(appLogic.dedupeMocParts(moc), isFalse);
      expect(moc.parts, hasLength(2));
    });

    test('handles null and empty part lists', () {
      expect(appLogic.dedupeMocParts(Moc(name: 'test')), isFalse);
      expect(appLogic.dedupeMocParts(Moc(name: 'test')..parts = []), isFalse);
    });

    test('same part number in different colours is never merged', () {
      final moc = Moc(name: 'test')
        ..parts = [
          part('3004', '72', quantity: 4),
          part('3004', '15', quantity: 4),
        ];

      expect(appLogic.dedupeMocParts(moc), isFalse);
    });
  });
}
