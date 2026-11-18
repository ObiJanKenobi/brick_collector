import 'package:brick_collector/common_libs.dart';

/// [rgb] (e.g. "C91A09") as a colour, or null when it is missing or not six
/// hex digits, so a bad value from an import or the cache can't crash a build.
Color? colorFromRgb(String? rgb) => rgb != null && _sixHexDigits.hasMatch(rgb) ? HexColor.fromHex(rgb) : null;

final _sixHexDigits = RegExp(r'^[0-9a-fA-F]{6}$');
