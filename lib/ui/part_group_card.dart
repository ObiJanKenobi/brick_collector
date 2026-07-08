import 'package:brick_collector/model/CollectablePartGroup.dart';
import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/notifications/save_moc_notification.dart';
import 'package:brick_collector/services/part_image_resolver.dart';
import 'package:brick_collector/ui/app_colors.dart';
import 'package:brick_collector/ui/color_count_chip.dart';
import 'package:brick_collector/ui/modals/collect_modal.dart';
import 'package:brick_collector/ui/smart_part_image.dart';
import 'package:brick_collector/ui/StripedContainer.dart';
import 'package:brick_collector/common_libs.dart';

class PartGroupCard extends StatefulWidget {
  final CollectablePartGroup group;
  final Moc? moc;
  final bool positiveQuantity;

  const PartGroupCard(
    this.group,
    this.moc, {
    this.positiveQuantity = false,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => PartGroupCardState();
}

final Map<String, List<String>> _candidatesCache = {};
final Map<String, Future<List<String>>> _candidatesInFlight = {};

String _cacheKey(String partNum, List<NeededColor> colorsByNeed) {
  final ids = colorsByNeed.map((c) => c.colorId).join(',');
  return '$partNum|$ids';
}

class PartGroupCardState extends State<PartGroupCard> {
  CollectablePartGroup get group => widget.group;
  Moc? get moc => widget.moc;
  bool get _positive => widget.positiveQuantity;

  bool get _isComplete => group.collectedCount >= group.quantity;

  bool get _shopping => moc?.shoppingMode == true;
  bool get _gobricksAvailable =>
      group.parts.isNotEmpty && group.parts.any((p) => !p.noMapping);

  List<String> _candidates = const [];
  NeededColor? _topNeed;
  String? _lastKey;

  /// Owned quantity from the local inventory cache, keyed by "part_color".
  /// Only populated in shopping mode so the user sees how many they already
  /// have next to the needed count without opening the part.
  final Map<String, int> _inventoryCounts = {};
  bool _inventoryLoading = false;

  String _inventoryKey(CollectablePart part) => "${part.part}_${part.color}";

  @override
  void initState() {
    super.initState();
    _reload();
    _maybeLoadInventoryCounts();
  }

  @override
  void didUpdateWidget(PartGroupCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.partNum != group.partNum || !_sameColors(oldWidget.group.parts, group.parts)) {
      _reload();
      _inventoryCounts.clear();
    }
    // Shopping mode toggles in-place on the same Moc instance, so initState
    // won't re-run for an already-built card. Trigger the load lazily here too.
    _maybeLoadInventoryCounts();
  }

  /// Loads owned counts once when shopping mode is (or becomes) active, using
  /// the same indexed per-part lookup the detail screen uses.
  void _maybeLoadInventoryCounts() {
    if (!_shopping || _inventoryLoading || _inventoryCounts.isNotEmpty) return;
    _loadInventoryCounts();
  }

  Future<void> _loadInventoryCounts() async {
    _inventoryLoading = true;
    final counts = await Future.wait(group.parts.map((part) async {
      final partNum = part.part;
      final colorId = int.tryParse(part.color ?? '');
      if (partNum == null || colorId == null) {
        return MapEntry(_inventoryKey(part), 0);
      }
      final items = await dbLogic.findItemsForPart(partNum, colorId: colorId);
      final count = items.fold<int>(0, (sum, i) => sum + i.quantity);
      return MapEntry(_inventoryKey(part), count);
    }));

    if (!mounted) {
      _inventoryLoading = false;
      return;
    }
    setState(() {
      for (final entry in counts) {
        _inventoryCounts[entry.key] = entry.value;
      }
      _inventoryLoading = false;
    });
  }

  bool _sameColors(List a, List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].color != b[i].color || a[i].quantity != b[i].quantity) return false;
    }
    return true;
  }

  void _reload() {
    final colorsByNeed = _computeColorsByNeed();
    _topNeed = colorsByNeed.isEmpty ? null : colorsByNeed.first;
    final key = _cacheKey(group.partNum, colorsByNeed);
    _lastKey = key;
    if (_candidatesCache.containsKey(key)) {
      setState(() => _candidates = _candidatesCache[key]!);
    } else {
      _candidates = const [];
      _resolveCandidates(colorsByNeed, key);
    }
  }

  List<NeededColor> _computeColorsByNeed() {
    final needs = <int, NeededColor>{};
    for (final p in group.parts) {
      final cid = int.tryParse(p.color ?? '');
      if (cid == null) continue;
      final prev = needs[cid];
      needs[cid] = NeededColor(
        colorId: cid,
        qty: (prev?.qty ?? 0) + p.quantity,
        name: p.colorName ?? prev?.name,
      );
    }
    return needs.values.toList()..sort((a, b) => b.qty.compareTo(a.qty));
  }

  Future<void> _resolveCandidates(List<NeededColor> colorsByNeed, String key) async {
    final partNum = group.partNum;
    if (partNum.isEmpty || partNum == '-') return;

    final future = _candidatesInFlight[key] ?? _doResolve(partNum, colorsByNeed, key);
    _candidatesInFlight[key] = future;

    final result = await future;
    if (!mounted || _lastKey != key) return;
    if (result.isNotEmpty) {
      setState(() => _candidates = result);
    }
  }

  Future<List<String>> _doResolve(String partNum, List<NeededColor> colorsByNeed, String key) async {
    try {
      final urls = await PartImageResolver.resolveCandidates(partNum, colorsByNeed);
      _candidatesCache[key] = urls;
      return urls;
    } finally {
      _candidatesInFlight.remove(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = <CollectablePart>[...group.parts];
    sorted.sort((a, b) =>
        (a.colorName ?? '').toLowerCase().compareTo((b.colorName ?? '').toLowerCase()));

    final dim = _shopping && !_gobricksAvailable;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final m = moc;
          if (m != null) {
            context.push(ScreenPaths.partGroup(group.partNum), extra: PartRouteData(group, m));
          } else if (group.parts.isNotEmpty) {
            // Tapping the card header opens the part summary scoped to exactly
            // the colours visible on this card (i.e. the preset's filter). With
            // no colour info the query falls back to "all colours".
            final colorIds = group.parts
                .map((p) => int.tryParse(p.color ?? ''))
                .whereType<int>()
                .toSet();
            final query = colorIds.isEmpty
                ? '?all=1'
                : '?colors=${colorIds.join(',')}';
            context.push(
              '${ScreenPaths.partSummary(group.partNum)}$query',
              extra: group.parts.first,
            );
          }
        },
        child: Opacity(
          opacity: dim ? 0.55 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: _positive ? _buildCompactLayout(sorted) : _buildMocLayout(sorted),
          ),
        ),
      ),
    );
  }

  Widget _partImage(double size, double iconSize) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Hero(
          tag: "part-img-${group.partNum}",
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SmartPartImage(
                candidates: _candidates.isNotEmpty
                    ? _candidates
                    : (group.imgUrl.isNotEmpty ? [group.imgUrl] : const []),
                onExhausted: _topNeed == null
                    ? null
                    : () => PartImageResolver.fetchApiUrl(group.partNum, _topNeed!.colorId),
                fallback: Icon(Icons.widgets_outlined, color: AppColors.textSecondary, size: iconSize),
              ),
            ),
          ),
        ),
        if (_shopping)
          Positioned(
            top: -4,
            right: -4,
            child: _gobricksBadge(_gobricksAvailable),
          ),
      ],
    );
  }

  Widget _gobricksBadge(bool available) {
    final Color color = available ? const Color(0xFF7BC043) : AppColors.textSecondary;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
      ),
      child: Icon(
        available ? Icons.check : Icons.close,
        size: 12,
        color: Colors.white,
      ),
    );
  }

  /// Shows how many of this part/color the user already owns (from the local
  /// inventory cache). Green once the owned quantity covers what's still needed.
  Widget _ownedBadge(CollectablePart part) {
    final key = _inventoryKey(part);
    final owned = _inventoryCounts[key];
    if (owned == null) {
      return const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 1.5),
      );
    }
    final bool covered = owned >= part.remaining;
    final Color color = covered ? Colors.greenAccent : AppColors.highlightColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inventory_2_outlined, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          '$owned',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }

  Widget _buildMocLayout(List<CollectablePart> sorted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _partImage(70, 20),
        const SizedBox(width: 10),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                group.partName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                '${group.collectedCount}/${group.quantity}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _isComplete ? Colors.greenAccent : AppColors.highlightColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: sorted.map((part) => _buildColorChip(context, part)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout(List<CollectablePart> sorted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _partImage(60, 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    group.partName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${group.partNum} · ${group.quantity} total',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.highlightColor),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: sorted.map((part) => _buildColorChip(context, part)).toList(),
        ),
      ],
    );
  }

  Widget _buildColorChip(BuildContext context, CollectablePart part) {
    final bool anyColor = part.color == "9999" || part.colorName == "No Color/Any Color";

    // Preset detail layout uses the shared swatch + fixed-width name chip so it
    // matches the part detail screen's "by colour" view. Tapping opens the part
    // summary for this colour.
    if (_positive) {
      return ColorCountChip(
        quantity: part.quantity,
        rgb: part.rgb,
        colorName: part.colorName,
        anyColor: anyColor,
        onTap: () => context.push(ScreenPaths.partSummary(part.part ?? ''), extra: part),
      );
    }

    final Color color = anyColor ? Colors.grey : HexColor.fromHex(part.rgb!);
    final bool completed = part.completed;
    final bool isDark = color.computeLuminance() < 0.4;
    final String label = completed ? '\u2713' : '-${part.remaining}';

    return GestureDetector(
      onTap: () {
        if (_shopping) {
          context.push(ScreenPaths.partSummary(part.part ?? ''), extra: part);
        } else {
          _showCollectModal(part);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                part.colorName ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
            if (_shopping) ...[
              const SizedBox(width: 6),
              _ownedBadge(part),
            ],
            const SizedBox(width: 6),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: completed ? color.withValues(alpha: 0.35) : color,
                borderRadius: BorderRadius.circular(6),
                border: completed
                    ? Border.all(color: Colors.greenAccent.withValues(alpha: 0.6), width: 1.5)
                    : Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Center(
                child: anyColor && !completed
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          const SizedBox(width: 30, height: 30, child: DiagonalStripePatternView()),
                          Text(label,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        ],
                      )
                    : Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: completed ? Colors.greenAccent : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCollectModal(CollectablePart part) async {
    await showModalBottomSheet(
        context: context,
        builder: (context) {
          return CollectModal(part);
        });
    if (!mounted) return;
    const SaveMocNotification().dispatch(context);
  }
}
