import 'package:brick_collector/common_libs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'collectable_part.dart';

part 'moc.g.dart';

@JsonSerializable(explicitToJson: true)
class Moc {
  Moc({required this.name});

  @JsonKey(includeFromJson: false, includeToJson: false)
  String? firestoreId;

  String name;
  String? imageUrl;
  String? sourceUrl;

  List<CollectablePart>? parts;

  PartSort sort = PartSort.nameAsc;
  PartSort groupSort = PartSort.nameAsc;

  @JsonKey(defaultValue: false)
  bool hideComplete = false;
  @JsonKey(defaultValue: false)
  bool hideCompleteGroup = false;

  int get quantity => parts?.fold(0, (previousValue, element) => (previousValue ?? 0) + element.quantity) ?? 0;

  int get collectedCount => parts?.fold(0, (previousValue, element) => (previousValue ?? 0) + element.collectedCount) ?? 0;

  factory Moc.fromJson(Map<String, dynamic> json) => _$MocFromJson(json);

  Map<String, dynamic> toJson() => _$MocToJson(this);

  factory Moc.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final moc = Moc.fromJson(data);
    moc.firestoreId = doc.id;
    return moc;
  }
}

enum PartSort {
  // color,
  nameDesc,
  nameAsc,
  collectedAsc,
  collectedDesc,
  quantityAsc,
  quantityDesc,
}
