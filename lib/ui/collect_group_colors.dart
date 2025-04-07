import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/ui/StripedContainer.dart';
import 'package:brick_collector/ui/StripedDecoration.dart';
import 'package:brick_lib/brick_lib.dart';
import 'package:brick_lib/model/part_group.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CollectGroupColors extends StatelessWidget {
  final PartGroup<CollectablePart> group;
  final Function? onColorClick;

  const CollectGroupColors(this.group, this.onColorClick, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sorted = <CollectablePart>[];
    sorted.addAll(group.parts);
    sorted.sort((a, b) {
      if (a.quantity > b.quantity) {
        return -1;
      } else if (b.quantity > a.quantity) {
        return 1;
      }

      return 0;
    });

    return Row(
      children: sorted.map((e) {
        final bool anyColor = e.color == "9999" || e.colorName == "No Color/Any Color";
        final Color hex = anyColor ? Colors.white : HexColor.fromHex(e.rgb!);
        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (onColorClick != null) {
                onColorClick!(e);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  // alignment: Alignment.center,
                  color: hex,
                  height: 20,
                  child: anyColor ? const DiagonalStripePatternView() : const SizedBox(width: 0, height: 0),
                ),
                // Solid text as fill.
                Align(
                  child: Text(
                    e.completed ? "✔" : "-${e.remaining}",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}
