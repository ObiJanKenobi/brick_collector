import 'package:brick_collector/logic/parts_logic.dart';
import 'package:brick_collector/model/filter_preset.dart';
import 'package:brick_lib/model/rebrickable_color.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('getPresetById hands out a copy, so abandoned edits never reach the shared list', () {
    final parts = PartsLogic()
      ..presetsForTesting = [
        FilterPreset(name: 'Dark')
          ..firestoreId = 'p1'
          ..categories = []
          ..colors = [],
      ];

    final draft = parts.getPresetById('p1')!
      ..name = 'abandoned'
      ..addColor(RebrickableColor(id: 0, name: 'Black', rgb: '05131D'));

    expect(draft, isNot(same(parts.presets.single)));
    expect(parts.presets.single.name, 'Dark');
    expect(parts.presets.single.colors, isEmpty);
    expect(parts.getPresetById('missing'), isNull);
  });
}
