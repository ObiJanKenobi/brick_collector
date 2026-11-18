import 'dart:async';
import 'dart:convert';

import 'package:brick_collector/logic/app_logic.dart';
import 'package:brick_collector/logic/db_logic.dart';
import 'package:brick_collector/model/cached_inventory_item.dart';
import 'package:brick_collector/model/cached_source.dart';
import 'package:brick_collector/model/set_sale.dart';
import 'package:brick_collector/router.dart';
import 'package:brick_collector/screens/part_group_screen.dart';
import 'package:brick_collector/screens/set_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

CachedInventoryItem _item(String partNum, int colorId, int qty, {bool spare = false}) => CachedInventoryItem()
  ..sourceType = CachedSourceType.set
  ..sourceExternalId = '31111-1'
  ..partNum = partNum
  ..partName = 'Part $partNum'
  ..colorId = colorId
  ..colorName = 'Color $colorId'
  ..rgb = 'C91A09'
  ..quantity = qty
  ..isSpare = spare;

/// Serves the set's cached rows and stands in for the Firestore sale doc,
/// merging each write and echoing it back like Firestore's local cache does.
class _FakeDbLogic extends DbLogic {
  /// The current listener's stream. Like Firestore's, it ends after an error,
  /// and a new listen starts with the document as it stands.
  StreamController<SetSale>? _listener;
  bool _hasDoc = false;

  @override
  Future<List<CachedInventoryItem>> getSourceItems(CachedSourceType type, String externalId) async => [
        // Two copies owned: the sync stored every row doubled.
        _item('3001', 4, 6),
        _item('3001', 4, 2, spare: true),
        _item('3020', 0, 2),
      ];

  /// What the cache holds now: two copies, while My Sets still said one.
  @override
  Future<CachedSource?> getSource(CachedSourceType type, String externalId) async => CachedSource()
    ..type = CachedSourceType.set
    ..externalId = '31111-1'
    ..name = 'Cyber Drone'
    ..ownedQuantity = 2;

  @override
  Future<List<CachedInventoryItem>> findItemsForPart(String partNum,
          {int? colorId, bool includeExcluded = false}) async =>
      const [];

  @override
  Stream<SetSale> watchSetSale(String setNum) {
    final listener = _listener = StreamController<SetSale>();
    if (_hasDoc) listener.add(SetSale.fromJson(_doc.toJson()));
    return listener.stream;
  }

  /// The listener fails, as on permission-denied, and ends.
  void fail(Object error) {
    final listener = _listener;
    _listener = null;
    listener?.addError(error);
    listener?.close();
  }

  Future<void> close() async => _listener?.close();

  /// Each merge as the screen sent it.
  final writes = <Map<String, Object>>[];

  /// The doc as Firestore holds it after those merges.
  var _doc = SetSale();

  /// Delivers [sale] as the doc, e.g. as another device left it.
  void emit(SetSale sale) {
    _doc = SetSale.fromJson(jsonDecode(jsonEncode(sale.toJson())) as Map<String, dynamic>);
    _hasDoc = true;
    _listener?.add(SetSale.fromJson(_doc.toJson()));
  }

  @override
  void updateSetSale(String setNum, {bool? active, bool? hideComplete, Map<String, int> collected = const {}}) {
    // The real payload, with a marker standing in for FieldValue.delete().
    final fields = DbLogic.setSaleFields(
        active: active, hideComplete: hideComplete, collected: collected, deleteField: () => _deleted);
    if (fields.isEmpty) return;
    writes.add(fields);
    if (fields['active'] case final bool v) _doc.active = v;
    if (fields['hideComplete'] case final bool v) _doc.hideComplete = v;
    if (fields['collected'] case final Map<String, Object> changes) {
      changes.forEach((key, v) => v == _deleted ? _doc.collected.remove(key) : _doc.collected[key] = v as int);
    }
    emit(_doc); // Firestore echoes local writes straight back
  }

  static const _deleted = #deleted;
}

void main() {
  late _FakeDbLogic db;
  // As My Sets listed it before a sync raised the copies to two.
  final staleSet = CachedSource()
    ..type = CachedSourceType.set
    ..externalId = '31111-1'
    ..name = 'Cyber Drone'
    ..ownedQuantity = 1;

  setUp(() {
    db = _FakeDbLogic();
    GetIt.I.registerSingleton<DbLogic>(db);
    GetIt.I.registerSingleton<AppLogic>(AppLogic());
  });
  tearDown(() async {
    await db.close();
    await GetIt.I.reset();
  });

  Future<void> pump(WidgetTester tester, {bool withInitial = true}) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => SetScreen('31111-1', initial: withInitial ? staleSet : null)),
      // As in the app router; there is deliberately no part summary route, so
      // opening that instead of the part screen fails the test.
      GoRoute(
        path: '/partgroup/:partNum',
        builder: (_, s) {
          return Scaffold(body: PartGroupScreen(s.extra! as PartRouteData));
        },
      ),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
  }

  TextButton verkaufButton(WidgetTester tester) =>
      tester.widget<TextButton>(find.byKey(const Key('setVerkauf')).first);

  testWidgets('lists one copy of the set, spares included', (tester) async {
    await pump(tester);
    db.emit(SetSale());
    await tester.pump();

    // Divided by the cached two copies, not the stale one it was opened with.
    expect(find.text('31111-1 · 5 parts · incl. 1 spare'), findsOneWidget);
    expect(find.text('Part 3001'), findsOneWidget);
    expect(find.text('3001 · 4 total'), findsOneWidget);
    expect(find.text('Verkauf'), findsOneWidget); // the button, no badge yet
  });

  testWidgets('opens from the set number alone', (tester) async {
    await pump(tester, withInitial: false);
    await tester.pump();

    expect(find.text('Cyber Drone'), findsOneWidget);
    expect(find.text('Part 3001'), findsOneWidget);
  });

  testWidgets('Verkauf waits for the saved progress before it can be toggled', (tester) async {
    await pump(tester);
    expect(verkaufButton(tester).onPressed, isNull);

    db.emit(SetSale());
    await tester.pump();
    expect(verkaufButton(tester).onPressed, isNotNull);
  });

  testWidgets('a failed progress load holds the toggles and collecting until a retry', (tester) async {
    await pump(tester);
    db.emit(SetSale(active: true));
    await tester.pump();

    db.fail('permission-denied');
    await tester.pump();
    expect(verkaufButton(tester).onPressed, isNull, reason: 'no toggling stale progress');
    expect(find.byKey(const Key('setRetrySale')), findsOneWidget, reason: 'retry outlives the SnackBar');

    // A colour now opens the read-only part screen instead of collecting.
    await tester.tap(find.text('-4'));
    await tester.pumpAndSettle();
    expect(find.text('Collect all'), findsNothing);
    expect(find.byType(PartGroupScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('setRetrySale')));
    await tester.pump();
    expect(verkaufButton(tester).onPressed, isNotNull);
    expect(find.byKey(const Key('setRetrySale')), findsNothing);
    expect(db.writes, isEmpty);
  });

  testWidgets('a part screen opened before a failed load refuses to save, and says so', (tester) async {
    await pump(tester);
    db.emit(SetSale(active: true));
    await tester.pump();
    await tester.tap(find.text('Part 3001'));
    await tester.pumpAndSettle();

    db.fail('permission-denied');
    await tester.pump();
    await tester.tap(find.text('Color 4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Collect all'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(db.writes, isEmpty);
    await tester.pump(const Duration(seconds: 5)); // after the "Could not load" SnackBar
    await tester.pumpAndSettle();
    expect(find.textContaining('Not saved'), findsOneWidget);
    expect(find.text('0 / 4'), findsWidgets, reason: 'the count is put back');
  });

  testWidgets('Verkauf switches to collecting, and collected parts are saved', (tester) async {
    await pump(tester);
    db.emit(SetSale());
    await tester.pump();

    await tester.tap(find.byKey(const Key('setVerkauf')));
    await tester.pump();
    expect(db.writes.last['active'], isTrue);
    expect(find.text('0 / 5 collected'), findsOneWidget);
    expect(find.text('Verkauf'), findsNWidgets(2)); // button + app bar badge

    // The red 3001 needs 4 (3 + 1 spare); collect them all.
    await tester.tap(find.text('-4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Collect all'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(db.writes.last['collected'], {'3001_4': 4});
    expect(find.text('4 / 5 collected'), findsOneWidget);
  });

  testWidgets('dismissing the collect sheet without saving writes nothing', (tester) async {
    await pump(tester);
    db.emit(SetSale(active: true));
    await tester.pump();

    await tester.tap(find.text('-4'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10)); // the sheet's barrier
    await tester.pumpAndSettle();

    expect(db.writes, isEmpty);
  });

  testWidgets('a collect writes only that count, keeping another device\'s', (tester) async {
    await pump(tester);
    db.emit(SetSale(active: true, collected: {'3020_0': 1})); // collected on another device
    await tester.pump();

    await tester.tap(find.text('-4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Collect all'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(db.writes.single, {
      'collected': {'3001_4': 4}
    });
    expect(find.text('5 / 5 collected'), findsOneWidget);
  });

  testWidgets('restores saved progress, capped at the set quantity', (tester) async {
    await pump(tester);
    db.emit(SetSale(active: true, collected: {'3001_4': 2, '3020_0': 9}));
    await tester.pump();

    expect(find.text('3 / 5 collected'), findsOneWidget);
    expect(find.text('-2'), findsOneWidget);
  });

  testWidgets('hide completed drops collected parts', (tester) async {
    await pump(tester);
    db.emit(SetSale(active: true, collected: {'3020_0': 1}));
    await tester.pump();
    expect(find.text('Part 3020'), findsOneWidget);

    await tester.tap(find.byTooltip('Hide completed'));
    await tester.pump();
    expect(db.writes.last['hideComplete'], isTrue);
    expect(find.text('Part 3020'), findsNothing);
    expect(find.text('Part 3001'), findsOneWidget);
  });

  testWidgets('a part opens the read-only part screen outside Verkauf', (tester) async {
    await pump(tester);
    db.emit(SetSale());
    await tester.pump();

    await tester.tap(find.text('Part 3001'));
    await tester.pumpAndSettle();

    expect(find.byType(PartGroupScreen), findsOneWidget);
    expect(find.text('4 total'), findsOneWidget);
    expect(find.byTooltip('Add colour'), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);

    // Tapping a colour doesn't open the collect sheet.
    await tester.tap(find.text('Color 4'));
    await tester.pumpAndSettle();
    expect(find.text('Collect all'), findsNothing);
  });

  testWidgets('collecting on the part screen in Verkauf saves to the sale', (tester) async {
    await pump(tester);
    db.emit(SetSale(active: true));
    await tester.pump();

    await tester.tap(find.text('Part 3001'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 4'), findsWidgets);

    await tester.tap(find.text('Color 4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Collect all'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(db.writes.last['collected'], {'3001_4': 4});
    expect(find.text('4 / 4'), findsWidgets);
  });
}
