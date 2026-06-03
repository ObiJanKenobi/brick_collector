import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/ui/modals/collect_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CollectablePart darkGrayBrick({int quantity = 4, int collected = 0}) {
  final p = CollectablePart(
    part: '3004',
    color: '72',
    quantity: quantity,
    colorName: 'Dark Bluish Gray',
    name: 'Brick 1 x 2',
    rgb: '6C6E68',
  );
  p.collectedCount = collected;
  return p;
}

/// Pumps a host screen with a button that opens [CollectModal] as a bottom
/// sheet, mirroring how PartGroupCard presents it.
Future<void> openModal(WidgetTester tester, CollectablePart part) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (_) => CollectModal(part),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('plus stepper + Save increments collectedCount only',
      (tester) async {
    final part = darkGrayBrick(quantity: 4, collected: 1);
    await openModal(tester, part);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(part.collectedCount, 2);
    expect(part.quantity, 4, reason: 'collecting must never change quantity');
  });

  testWidgets('dismissing without saving leaves the part untouched',
      (tester) async {
    final part = darkGrayBrick(quantity: 4, collected: 1);
    await openModal(tester, part);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    // Swipe the sheet away instead of saving.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(part.collectedCount, 1);
    expect(part.quantity, 4);
  });

  testWidgets('Collect all sets collectedCount to quantity', (tester) async {
    final part = darkGrayBrick(quantity: 4, collected: 0);
    await openModal(tester, part);

    await tester.tap(find.text('Collect all'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(part.collectedCount, 4);
    expect(part.quantity, 4);
  });

  testWidgets('cannot collect past the needed quantity', (tester) async {
    final part = darkGrayBrick(quantity: 2, collected: 2);
    await openModal(tester, part);

    // Counter is full: + must be a no-op and there is nothing to save.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('No changes'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('Clear resets the counter to zero', (tester) async {
    final part = darkGrayBrick(quantity: 4, collected: 3);
    await openModal(tester, part);

    await tester.tap(find.text('Clear'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(part.collectedCount, 0);
    expect(part.quantity, 4);
  });
}
