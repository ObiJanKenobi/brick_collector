import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:brick_collector/common_libs.dart';

class MocCard extends StatefulWidget {
  final Moc moc;

  const MocCard(this.moc, {super.key});

  @override
  State<StatefulWidget> createState() => MocCardState();
}

class MocCardState extends State<MocCard> {
  MocCardState();

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
              context.go(ScreenPaths.mocPage(moc.id), extra: moc);
            },
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 70,
                    height: 70,
                    alignment: Alignment.center,
                    child: Hero(
                        tag: "part-img-${moc.name}",
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.navItemBgColor,
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            // foregroundImage: CachedNetworkImageProvider(moc.imgUrl),
                          ),
                        )),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text("Gesamtanzahl: ${moc.parts?.length ?? 0}", style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        moc.name,
                        maxLines: 2,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ]),
                  )
                ]),
              ),
              const Spacer(),
              const SizedBox(
                height: 20,
              )
            ])));
  }
}
