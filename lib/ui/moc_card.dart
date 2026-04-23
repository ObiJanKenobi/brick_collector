import 'package:cached_network_image/cached_network_image.dart';
import 'package:brick_collector/common_libs.dart';

class MocCard extends StatefulWidget {
  final Moc moc;

  const MocCard(this.moc, {super.key});

  @override
  State<StatefulWidget> createState() => MocCardState();
}

class MocCardState extends State<MocCard> {
  Moc get moc => widget.moc;

  double get _progress {
    if (moc.quantity == 0) return 0;
    return moc.collectedCount / moc.quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          context.go(ScreenPaths.mocPage(moc.firestoreId), extra: moc);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background: image or fallback
            if (moc.imageUrl != null)
              CachedNetworkImage(
                imageUrl: moc.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.navItemBgColor,
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => _buildFallbackBackground(),
              )
            else
              _buildFallbackBackground(),

            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black54,
                    Colors.black87,
                  ],
                  stops: [0.3, 0.7, 1.0],
                ),
              ),
            ),

            // Stats chip at top-right
            if (moc.parts != null && moc.parts!.isNotEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${moc.collectedCount}/${moc.quantity}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // Bottom content: name + progress
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    moc.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (moc.parts != null && moc.parts!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: _progress,
                              minHeight: 4,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _progress >= 1.0
                                    ? Colors.greenAccent
                                    : AppColors.highlightColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${moc.parts!.length} parts',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackBackground() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(
          Icons.widgets_outlined,
          size: 48,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
