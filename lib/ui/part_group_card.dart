import 'package:brick_collector/model/CollectablePartGroup.dart';
import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/notifications/save_moc_notification.dart';
import 'package:brick_collector/services/part_image_resolver.dart';
import 'package:brick_collector/ui/app_colors.dart';
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

  List<String> _candidates = const [];
  NeededColor? _topNeed;
  String? _lastKey;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(PartGroupCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.partNum != group.partNum || !_sameColors(oldWidget.group.parts, group.parts)) {
      _reload();
    }
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
    sorted.sort((a, b) => _positive
        ? b.quantity.compareTo(a.quantity)
        : (a.colorName ?? '').compareTo(b.colorName ?? ''));

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
            context.push(ScreenPaths.partSummary(group.partNum), extra: group.parts.first);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: _positive ? _buildCompactLayout(sorted) : _buildMocLayout(sorted),
        ),
      ),
    );
  }

  Widget _partImage(double size, double iconSize) {
    return Hero(
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
    final Color color = anyColor ? Colors.grey : HexColor.fromHex(part.rgb!);
    final bool completed = _positive ? false : part.completed;
    final bool isDark = color.computeLuminance() < 0.4;
    final String label = _positive ? '${part.quantity}' : (completed ? '\u2713' : '-${part.remaining}');

    return GestureDetector(
      onTap: () {
        if (_positive) {
          context.push(ScreenPaths.partSummary(part.part ?? ''), extra: part);
        } else {
          _showCollectModal(part);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _positive
              ? [
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
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 140,
                    child: Text(
                      part.colorName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ]
              : [
                  Flexible(
                    child: Text(
                      part.colorName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
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
