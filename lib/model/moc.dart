import 'dart:convert';

import 'package:brick_collector/common_libs.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;

import 'collectable_part.dart';

part 'moc.g.dart';

@JsonSerializable(explicitToJson: true)
class Moc {
  Moc({required this.name});

  @JsonKey(includeFromJson: false, includeToJson: false)
  String? firestoreId;

  String name;
  String? imageUrl;
  String? imageBase64;
  String? sourceUrl;

  List<CollectablePart>? parts;

  PartSort sort = PartSort.nameAsc;
  PartSort groupSort = PartSort.nameAsc;

  @JsonKey(defaultValue: false)
  bool hideComplete = false;
  @JsonKey(defaultValue: false)
  bool hideCompleteGroup = false;
  @JsonKey(defaultValue: false)
  bool shoppingMode = false;

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

  /// Target for sizing the inline image. Firestore rejects documents over
  /// 1 MiB; sizes here are JSON, an estimate of Firestore's count, so this
  /// stays below the real limit.
  static const int maxDocumentBytes = 1000 * 1000;

  /// Approximate size of this MOC's Firestore document.
  int get documentBytes => documentBytesWithoutImage + (imageBase64?.length ?? 0);

  /// [documentBytes] minus the inline image, i.e. what the parts and settings
  /// take. Base64 is ASCII, so the image adds exactly its length.
  int get documentBytesWithoutImage => utf8.encode(jsonEncode(toJson()..remove('imageBase64'))).length;
}

/// A MOC whose Firestore document would exceed [Moc.maxDocumentBytes].
class MocTooLargeException implements Exception {
  MocTooLargeException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Kilobytes for user-facing size messages.
String kilobytes(int bytes) => '${(bytes / 1000).round()} KB';

enum PartSort {
  // color,
  nameDesc,
  nameAsc,
  collectedAsc,
  collectedDesc,
  quantityAsc,
  quantityDesc,
}
