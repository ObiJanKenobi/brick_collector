import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/model/moc.dart';
import 'package:brick_lib/model/rebrickable_part.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toJson leaves part external_ids out of the Firestore MOC document', () {
    // Shape of /api/v3/lego/parts/{part_num}/: one id map per part. A MOC with
    // thousands of parts must not carry these into its single Firestore
    // document (1 MiB limit, shared with imageBase64).
    final details = RebrickablePart.fromJson({
      'part_num': '3001',
      'name': 'Brick 2 x 4',
      'part_img_url': 'https://cdn.rebrickable.com/media/parts/3001.png',
      'external_ids': {
        'BrickLink': ['3001'],
        'BrickOwl': ['771344'],
        'LEGO': ['3001', '300101'],
        'LDraw': ['3001'],
      },
    });
    final moc = Moc(name: 'House')
      ..parts = [CollectablePart(part: '3001', color: '4', quantity: 8, details: details)];

    final json = moc.toJson();

    final partJson = (json['parts'] as List).single as Map<String, dynamic>;
    final detailsJson = partJson['details'] as Map<String, dynamic>;
    expect(detailsJson.containsKey('external_ids'), isFalse);
    // The MOC screens still read the image from the stored details.
    expect(detailsJson['part_img_url'], 'https://cdn.rebrickable.com/media/parts/3001.png');
    expect(details.externalIds, isNotNull, reason: 'in-memory part stays intact');

    final roundTrip = Moc.fromJson(json);
    expect(roundTrip.parts!.single.details!.imgUrl, details.imgUrl);
  });
}
