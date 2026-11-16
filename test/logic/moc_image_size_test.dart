import 'dart:convert';

import 'package:brick_collector/logic/db_logic.dart';
import 'package:brick_collector/logic/moc_logic.dart';
import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/model/moc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image/image.dart' as img;

/// Records saves instead of writing to Firestore.
class _FakeDbLogic extends DbLogic {
  final saved = <Moc>[];

  @override
  String saveMoc(Moc moc) {
    saved.add(moc);
    return moc.firestoreId ??= 'm1';
  }
}

/// A MOC whose parts and settings take at least [bytes] of its document.
Moc _mocTaking(int bytes) {
  final moc = Moc(name: 'Castle')
    ..imageBase64 = 'previous'
    ..parts = [];
  while (moc.documentBytesWithoutImage < bytes) {
    final n = moc.parts!.length;
    moc.parts!.addAll(List.generate(
      200,
      (i) => CollectablePart(part: 'part${n + i}', color: '${i % 200}', quantity: 1, name: 'Some part name ${n + i}'),
    ));
  }
  return moc;
}

/// A gradient with fine stripes: photo-like JPEG sizes, unlike flat colour
/// (tiny) or noise (huge).
List<int> _photoJpeg(int size) {
  final image = img.Image(width: size, height: size);
  for (final p in image) {
    final stripe = (p.x ~/ 3 + p.y ~/ 5).isEven ? 40 : 0;
    p
      ..r = (p.x * 215 ~/ size) + stripe
      ..g = (p.y * 215 ~/ size) + stripe
      ..b = ((p.x + p.y) * 107 ~/ size) + stripe;
  }
  return img.encodeJpg(image, quality: 92);
}

void main() {
  late _FakeDbLogic db;

  setUp(() {
    db = _FakeDbLogic();
    GetIt.I.registerSingleton<DbLogic>(db);
  });
  tearDown(() => GetIt.I.reset());

  test('an image is shrunk until it fits the room the parts leave', () async {
    final moc = _mocTaking(Moc.maxDocumentBytes - 110 * 1000);
    final jpeg = _photoJpeg(1600);

    await MocLogic().setMocImageFromBytes(moc, jpeg);

    expect(db.saved, [same(moc)]);
    expect(moc.imageBase64, isNot('previous'));
    // Fits, with room left for the parts to grow.
    expect(moc.documentBytes, lessThanOrEqualTo(Moc.maxDocumentBytes - 40 * 1000));
    final width = img.decodeJpg(base64Decode(moc.imageBase64!))!.width;
    expect(width, lessThan(1280), reason: 'the full-size encode must not have fit, or the shrink loop went untested');
    expect(width, greaterThanOrEqualTo(160));
  });

  test('no image is attempted when the parts leave no room', () async {
    final moc = _mocTaking(Moc.maxDocumentBytes - 60 * 1000);

    await expectLater(
      MocLogic().setMocImageFromBytes(moc, img.encodeJpg(img.Image(width: 8, height: 8))),
      throwsA(isA<MocTooLargeException>().having((e) => e.message, 'message', contains('no room for an image'))),
    );
    expect(moc.imageBase64, 'previous', reason: 'the MOC must stay unchanged');
    expect(db.saved, isEmpty);
  });

}
