import 'package:brick_collector/model/CollectablePartGroup.dart';
import 'package:brick_collector/model/moc.dart';
import 'package:brick_collector/common_libs.dart';

class MocLogic {
  Stream<List<Moc>> get outMocs => dbLogic.watchMocs();

  Future<Moc> addNewMoc(String name, {String? sourceUrl, String? imageUrl}) async {
    final newMoc = Moc(name: name);
    newMoc.sourceUrl = sourceUrl;
    newMoc.imageUrl = imageUrl;
    await saveMoc(newMoc);
    return newMoc;
  }

  Future<Moc> saveMoc(Moc moc) async {
    await dbLogic.saveMoc(moc);
    return moc;
  }

  Future<void> deleteMoc(Moc moc) async {
    await dbLogic.deleteMoc(moc);
  }

  Future<void> deletePart(Moc moc, CollectablePartGroup group, BrickPart part) async {
    group.parts.remove(part);
    moc.parts?.remove(part);
    await saveMoc(moc);
  }
}
