import 'package:brick_collector/model/filter_preset.dart';
import 'package:brick_lib/model/rebrickable_color.dart';
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
}
