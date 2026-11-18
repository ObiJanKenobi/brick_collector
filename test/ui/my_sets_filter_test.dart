import 'package:brick_collector/logic/db_logic.dart';
import 'package:brick_collector/model/cached_source.dart';
import 'package:brick_collector/screens/my_sets_screen.dart';
import 'package:brick_collector/ui/modals/alternate_builds_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

CachedSource _set(String number, String name, {bool excluded = false}) => CachedSource()
  ..type = CachedSourceType.set
  ..externalId = number
  ..name = name
  ..excludeFromInventory = excluded;

/// Serves a fixed set list instead of the Isar cache.
class _FakeDbLogic extends DbLogic {
  _FakeDbLogic(this.sets);

  final List<CachedSource> sets;

  @override
  Future<List<CachedSource>> getSourcesByType(CachedSourceType type) async => sets;

  @override
  Future<void> setSourceExcluded(int id, bool excluded) async {}
}

void main() {
  group('My Sets screen', () {
    // Fresh per test: the screen flips excludeFromInventory in place.
    setUp(() => GetIt.I.registerSingleton<DbLogic>(_FakeDbLogic([
          _set('75192-1', 'Millennium Falcon'),
          _set('21318-1', 'Tree House', excluded: true),
          _set('10305-1', 'Lion Knights\' Castle'),
        ])));
    tearDown(() => GetIt.I.reset());

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MySetsScreen()));
      await tester.pumpAndSettle();
    }

    testWidgets('the name filter narrows the list', (tester) async {
      await pump(tester);
      expect(find.text('Millennium Falcon'), findsOneWidget);
      expect(find.text('Tree House'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('mySetsSearch')), 'castle');
      await tester.pump();

      expect(find.text('Lion Knights\' Castle'), findsOneWidget);
      expect(find.text('Millennium Falcon'), findsNothing);
      expect(find.text('Showing 1 of 3 sets · 2 counted'), findsOneWidget);
    });

    testWidgets('the switch hides sets not counted in inventory; clear filters restores all', (tester) async {
      await pump(tester);

      await tester.tap(find.byKey(const Key('mySetsCountedOnly')));
      await tester.pump();
      expect(find.text('Tree House'), findsNothing);
      expect(find.text('Millennium Falcon'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('mySetsSearch')), 'tree');
      await tester.pump();
      expect(find.text('No sets match the filter.'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pump();
      expect(find.text('Tree House'), findsOneWidget);
      expect(find.text('Millennium Falcon'), findsOneWidget);
      expect(find.text('2 of 3 sets counted toward inventory'), findsOneWidget);
    });

    testWidgets('switching a set off under the counted-only filter offers an undo', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('mySetsCountedOnly')));
      await tester.pump();

      final falconRow = find.ancestor(of: find.text('Millennium Falcon'), matching: find.byType(Card));
      await tester.tap(find.descendant(of: falconRow, matching: find.byType(Switch)));
      await tester.pump();
      expect(find.text('Millennium Falcon'), findsNothing);
      expect(find.text('Millennium Falcon is no longer counted'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500)); // let the SnackBar slide in
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Millennium Falcon'), findsOneWidget);
    });
  });

  group('My Sets row', () {
    setUp(() => GetIt.I.registerSingleton<DbLogic>(_FakeDbLogic([_set('75192-1', 'Millennium Falcon')])));
    tearDown(() => GetIt.I.reset());

    /// With a router, so a row tap can push the set's parts page (stubbed).
    Future<void> pump(WidgetTester tester) async {
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const MySetsScreen()),
        GoRoute(path: '/set/:setNum', builder: (_, s) => Text('Parts of ${s.pathParameters['setNum']}')),
      ]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
    }

    Finder inRow(Finder matching) => find.descendant(
        of: find.ancestor(of: find.text('Millennium Falcon'), matching: find.byType(Card)), matching: matching);

    testWidgets('tapping the row opens the set\'s parts', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Millennium Falcon'));
      await tester.pumpAndSettle();
      expect(find.text('Parts of 75192-1'), findsOneWidget);
    });

    testWidgets('the switch still toggles counting without opening the set', (tester) async {
      await pump(tester);
      await tester.tap(inRow(find.byType(Switch)));
      await tester.pump();
      expect(find.text('Not counted in inventory'), findsOneWidget);
      expect(find.textContaining('Parts of'), findsNothing);
    });

    testWidgets('the alternate builds button still opens its sheet without opening the set', (tester) async {
      await pump(tester);
      await tester.tap(inRow(find.byTooltip('Alternate builds')));
      await tester.pump();
      expect(find.byType(AlternateBuildsModal), findsOneWidget);
      expect(find.textContaining('Parts of'), findsNothing);
    });
  });
}
