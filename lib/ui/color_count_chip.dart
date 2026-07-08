import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/ui/StripedContainer.dart';

/// A colour swatch stamped with a quantity, followed by the colour name in a
/// fixed-width column.
///
/// Shared by the preset detail page ([PartGroupCard]'s compact layout) and the
/// part detail screen's "by colour" view so both lay colours out identically:
/// because every chip is the same width, they line up into columns inside a
/// [Wrap].
class ColorCountChip extends StatelessWidget {
  const ColorCountChip({
    required this.quantity,
    this.rgb,
    this.colorName,
    this.anyColor = false,
    this.onTap,
    this.nameWidth = 140,
    super.key,
  });

  final int quantity;

  /// 6-digit hex (no leading `#`), e.g. `05131D`. Ignored when [anyColor].
  final String? rgb;
  final String? colorName;

  /// LEGO's "No Color/Any Color" — rendered as a diagonal stripe pattern.
  final bool anyColor;
  final VoidCallback? onTap;

  /// Width of the name column. Keep this the same across all chips in a [Wrap]
  /// so they align into columns.
  final double nameWidth;

  @override
  Widget build(BuildContext context) {
    final Color color = anyColor
        ? Colors.grey
        : ((rgb != null && rgb!.length == 6)
            ? HexColor.fromHex(rgb!)
            : AppColors.surfaceLight);
    final bool isDark = color.computeLuminance() < 0.4;
    final String label = '$quantity';

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Center(
                child: anyColor
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          const SizedBox(
                              width: 30,
                              height: 30,
                              child: DiagonalStripePatternView()),
                          Text(label,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary)),
                        ],
                      )
                    : Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: nameWidth,
              child: Text(
                colorName ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
