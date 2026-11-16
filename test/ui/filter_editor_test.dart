import 'package:brick_collector/logic/parts_logic.dart';
import 'package:brick_collector/model/filter_preset.dart';
import 'package:brick_collector/ui/filter_editor.dart';
import 'package:brick_lib/model/rebrickable_color.dart';
import 'package:brick_lib/model/rebrickable_part_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';

/// Serves a fixed category/colour catalogue instead of the Rebrickable API.
/// Subjects, like the real PartsLogic, so StreamBuilder sees an equal stream
/// on every rebuild instead of resubscribing.
class _FakePartsLogic extends PartsLogic {
  final _categories = BehaviorSubject.seeded([RebrickablePartCategory(id: 11, name: 'Bricks')]);
  final _colors = BehaviorSubject.seeded([RebrickableColor(id: 0, name: 'Black', rgb: '05131D')]);

  @override
  Stream<List<RebrickablePartCategory>> get outPartCategories => _categories.stream;

  @override
  Stream<List<RebrickableColor>> get outColors => _colors.stream;
}

FilterPreset _empty() => FilterPreset(name: 'draft')
  ..categories = []
  ..colors = [];

Future<void> _pump(WidgetTester tester, FilterPreset filter, {VoidCallback? onSubmitted}) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: FilterEditor(
        filter: filter,
        appBar: const SliverAppBar(pinned: true, title: Text('Filter')),
        onSearchSubmitted: onSubmitted,
      ),
    ),
  ));
}

void main() {
  setUp(() => GetIt.I.registerSingleton<PartsLogic>(_FakePartsLogic()));
  tearDown(() => GetIt.I.reset());

  testWidgets('toggling a category and a colour edits the filter in place', (tester) async {
    final filter = _empty();
    await _pump(tester, filter);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bricks'));
    await tester.tap(find.text('Black'));
    await tester.pump();

    expect(filter.categories!.map((c) => c.id), [11]);
    expect(filter.colors!.map((c) => c.id), [0]);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await tester.tap(find.text('Bricks'));
    await tester.pump();
    expect(filter.categories, isEmpty);
  });

  testWidgets('search text is trimmed into the filter; enter submits', (tester) async {
    final filter = _empty();
    var submitted = 0;
    await _pump(tester, filter, onSubmitted: () => submitted++);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  plate ');
    expect(filter.searchText, 'plate');

    await tester.enterText(find.byType(TextField), '   ');
    expect(filter.searchText, isNull);

    await tester.testTextInput.receiveAction(TextInputAction.search);
    expect(submitted, 1);
  });

  testWidgets('swapping in a different filter shows its search text', (tester) async {
    await _pump(tester, _empty()..searchText = 'tile');
    await tester.pumpAndSettle();
    expect(find.text('tile'), findsOneWidget);

    await _pump(tester, _empty());
    await tester.pump();
    expect(find.text('tile'), findsNothing);
  });
}
