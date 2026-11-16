import 'package:brick_collector/model/filter_preset.dart';
import 'package:brick_lib/model/rebrickable_color.dart';
import 'package:brick_lib/model/rebrickable_part_category.dart';
import 'package:flutter_test/flutter_test.dart';

bool containsNestedList(Object? value, {bool insideList = false}) {
  if (value is List) {
    if (insideList) return true;
    return value.any((e) => containsNestedList(e, insideList: true));
  }
  if (value is Map) {
    return value.values.any((e) => containsNestedList(e));
  }
  return false;
}

void main() {
  test('toJson drops color external_ids so Firestore accepts the preset', () {
    // Shape of /api/v3/lego/colors/ — ext_descrs is a list of lists, which
    // Firestore rejects with "Nested arrays are not supported".
    final color = RebrickableColor.fromJson({
      'id': 0,
      'name': 'Black',
      'rgb': '05131D',
      'is_trans': false,
      'external_ids': {
        'BrickLink': {
          'ext_ids': [11],
          'ext_descrs': [
            ['Black'],
          ],
        },
      },
    });
    final preset = FilterPreset(name: 'Dark')..addColor(color);

    final json = preset.toJson();

    expect(containsNestedList(json), isFalse);
    final colorJson = (json['colors'] as List).single as Map<String, dynamic>;
    expect(colorJson.containsKey('external_ids'), isFalse);
    expect(colorJson['id'], 0);
    expect(colorJson['name'], 'Black');
    expect(colorJson['rgb'], '05131D');
    expect(color.externalIds, isNotNull, reason: 'in-memory color stays intact');
  });

  test('copy is independent of the original but keeps its document id', () {
    final original = FilterPreset(name: 'Dark')
      ..firestoreId = 'abc'
      ..imageUrl = 'https://example.com/x.png'
      ..searchText = 'plate'
      ..addCategory(RebrickablePartCategory(id: 11, name: 'Bricks'))
      ..addColor(RebrickableColor(id: 0, name: 'Black', rgb: '05131D'));

    final copy = original.copy()
      ..name = 'Renamed'
      ..searchText = null
      ..addCategory(RebrickablePartCategory(id: 14, name: 'Plates'))
      ..removeColor(0);

    expect(copy.firestoreId, 'abc');
    expect(copy.imageUrl, 'https://example.com/x.png');
    expect(original.name, 'Dark');
    expect(original.searchText, 'plate');
    expect(original.categories!.map((c) => c.id), [11]);
    expect(original.colors!.map((c) => c.id), [0]);
    expect(copy.categories!.map((c) => c.id), [11, 14]);
    expect(copy.colors, isEmpty);
  });

  test('hasSameCriteria ignores name, order and surrounding whitespace', () {
    FilterPreset preset(String name, List<int> cats, List<int> cols, String? search) => FilterPreset(name: name)
      ..categories = [for (final id in cats) RebrickablePartCategory(id: id, name: 'c$id')]
      ..colors = [for (final id in cols) RebrickableColor(id: id, name: 'k$id', rgb: '000000')]
      ..searchText = search;

    final a = preset('A', [11, 14], [0, 4], 'plate');
    expect(a.hasSameCriteria(preset('B', [14, 11], [4, 0], ' plate ')), isTrue);
    expect(preset('A', [], [], null).hasSameCriteria(preset('A', [], [], '  ')), isTrue);
    expect(a.hasSameCriteria(preset('A', [11], [0, 4], 'plate')), isFalse);
    expect(a.hasSameCriteria(preset('A', [11, 14], [0], 'plate')), isFalse);
    expect(a.hasSameCriteria(preset('A', [11, 14], [0, 4], 'brick')), isFalse);
  });
}
