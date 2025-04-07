import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/ui/stripe_pattern_box_painter.dart';

class StripedDecoration extends Decoration {
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return StripePatternBoxPainter();
  }
}
