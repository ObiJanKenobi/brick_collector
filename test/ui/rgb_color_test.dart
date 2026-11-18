import 'package:brick_collector/ui/rgb_color.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('six hex digits make a colour', () {
    expect(colorFromRgb('C91A09'), isNotNull);
    expect(colorFromRgb('c91a09'), isNotNull);
  });

  test('anything else is no colour instead of a crash', () {
    for (final bad in [null, '', 'C91A0', 'C91A09F', '#C91A0', '+FFFFF', '-00000', 'GGGGGG']) {
      expect(colorFromRgb(bad), isNull, reason: '"$bad"');
    }
  });
}
