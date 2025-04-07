import 'package:brick_collector/model/CollectablePartGroup.dart';
import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/notifications/save_moc_notification.dart';
import 'package:brick_collector/router.dart';
import 'package:brick_collector/ui/app_colors.dart';
import 'package:brick_collector/ui/collect_group_colors.dart';
import 'package:brick_collector/ui/modals/collect_modal.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:brick_collector/common_libs.dart';

class PartGroupCard extends StatefulWidget {
  final CollectablePartGroup group;
  final Moc moc;

  const PartGroupCard(this.group, this.moc, {super.key});

  @override
  State<StatefulWidget> createState() => PartGroupCardState();
}

class PartGroupCardState extends State<PartGroupCard> {
  PartGroupCardState();

  CollectablePartGroup get group => widget.group;

  Moc get moc => widget.moc;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        clipBehavior: Clip.antiAlias,
        color: Theme.of(context).colorScheme.secondary,
        elevation: 3,
        child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              context.push(ScreenPaths.partGroup(group.partNum), extra: PartRouteData(group, moc));
            },
            child: Stack(
              children: [
                Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.only(top: 12, left: 3, right: 3, bottom: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.navItemBgColor,
                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(12), topLeft: Radius.circular(12)),
                      ),
                      child: Column(
                        children: [
                          Hero(
                            tag: "part-img-${group.partNum}",
                            child: Container(
                                color: Colors.white,
                                child: AspectRatio(aspectRatio: 1.5, child: CachedNetworkImage(imageUrl: group.imgUrl))),
                            // CircleAvatar(
                            //   radius: 30,
                            //   backgroundColor: Colors.white,
                            //   foregroundImage: CachedNetworkImageProvider(group.imgUrl),
                            // )
                          ),
                          Text("${group.collectedCount}/${group.quantity}",
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                        ],
                      ),
                    )),
                Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 90, top: 10),
                    child: Text(group.partName, maxLines: 2, style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const Spacer(),
                  SizedBox(
                      height: 42,
                      child: CollectGroupColors(group, (CollectablePart part) {
                        _showCollectModal(part);
                      })),
                  const SizedBox(
                    height: 14,
                  )
                ]),
              ],
            )));
  }

  void _showCollectModal(CollectablePart part) async {
    await showModalBottomSheet(
        context: context,
        builder: (context) {
          return CollectModal(part);
        });

    const SaveMocNotification().dispatch(context);
  }
}
