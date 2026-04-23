import 'package:brick_collector/common_libs.dart';

part 'collectable_part.g.dart';

@JsonSerializable(explicitToJson: true)
class CollectablePart extends BrickPart {
  CollectablePart(
      {super.part,
      super.color,
      super.quantity,
      super.colorName,
      super.gobricksColor,
      super.bricklinkColor,
      super.bricklinkId,
      super.rgb,
      super.goBrickPart,
      super.name,
      super.details});

  int collectedCount = 0;

  int get remaining => quantity - collectedCount;

  bool get completed => quantity == collectedCount;

  factory CollectablePart.fromJson(Map<String, dynamic> json) => _$CollectablePartFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CollectablePartToJson(this);

  static CollectablePart fromPart(BrickPart part) {
    return CollectablePart(
        part: part.part,
        color: part.color,
        quantity: part.quantity,
        colorName: part.colorName,
        name: part.name,
        gobricksColor: part.gobricksColor,
        goBrickPart: part.goBrickPart,
        bricklinkId: part.bricklinkId,
        bricklinkColor: part.bricklinkColor,
        rgb: part.rgb,
        details: part.details);
  }
}
