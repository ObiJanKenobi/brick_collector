import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart';

/// Tablet-aware sizing helpers.
///
/// The app has no design-system dimension constants — colour-swatch sizes are
/// hard-coded literals at each call site. On tablets (iPad, large Android
/// tablets) those swatches are too small to tap comfortably with a finger, so
/// scale them up. Phones and desktop (precise mouse input) are left unchanged.
extension ResponsiveSizing on BuildContext {
  /// True on tablet-class touch devices.
  ///
  /// Gated on a touch OS so resizable desktop windows (macOS/Windows), which
  /// can easily exceed the size threshold, keep their compact swatches. Uses
  /// the shortest side so it holds in both orientations — 600dp is the
  /// standard Material tablet breakpoint.
  bool get isTablet {
    final platform = defaultTargetPlatform;
    final isTouchOs =
        platform == TargetPlatform.iOS || platform == TargetPlatform.android;
    return isTouchOs && MediaQuery.of(this).size.shortestSide >= 600;
  }

  /// Multiplier for colour-swatch tap targets — larger on tablets, 1.0
  /// everywhere else.
  double get colorChipScale => isTablet ? 1.5 : 1.0;

  /// Scale a swatch dimension by [colorChipScale].
  double chip(double size) => size * colorChipScale;
}
