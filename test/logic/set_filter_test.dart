import 'package:brick_collector/logic/set_filter.dart';
import 'package:brick_collector/model/cached_source.dart';
import 'package:flutter_test/flutter_test.dart';

CachedSource _set(String number, String name, {bool excluded = false}) => CachedSource()
  ..type = CachedSourceType.set
  ..externalId = number
  ..name = name
  ..excludeFromInventory = excluded;

void main() {
  test('filterSets matches name or number, case-insensitively, and can drop uncounted sets', () {
    final falcon = _set('75192-1', 'Millennium Falcon');
    final treeHouse = _set('21318-1', 'Tree House', excluded: true);
    final castle = _set('10305-1', "Lion Knights' Castle");
    final sets = [falcon, treeHouse, castle];

    expect(filterSets(sets), sets);
    expect(filterSets(sets, query: '  FALCON '), [falcon]);
    expect(filterSets(sets, query: '21318'), [treeHouse]);
    expect(filterSets(sets, countedOnly: true), [falcon, castle]);
    expect(filterSets(sets, query: 'tree', countedOnly: true), isEmpty);
  });
}
