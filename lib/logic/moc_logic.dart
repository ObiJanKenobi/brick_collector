import 'package:brick_collector/model/CollectablePartGroup.dart';
import 'package:brick_collector/model/moc.dart';

import 'package:brick_collector/common_libs.dart';
import 'package:rxdart/rxdart.dart';

class MocLogic {
  ///
  /// User favorites
  ///
  final BehaviorSubject<List<Moc>> _mocListController = BehaviorSubject.seeded([]);

  Sink<List<Moc>> get _inMocs => _mocListController.sink;

  Stream<List<Moc>> get outMocs => _mocListController.stream;

  final List<Moc> _mocs = [];

  List<Moc> get mocs => _mocs;

  Future<void> bootstrap() async {
    _mocs.addAll(await dbLogic.getMocs());
    _inMocs.add(_mocs);
  }

  Future<Moc> addNewMoc(String name) async {
    final newMoc = Moc(name: name);

    await saveMoc(newMoc);

    _mocs.add(newMoc);
    _inMocs.add(_mocs);

    return newMoc;
  }

  Future<Moc> saveMoc(Moc moc) async {
    await dbLogic.saveMoc(moc);

    return moc;
  }

  deleteMoc(Moc moc) async {
    await dbLogic.deleteMoc(moc);
    _mocs.remove(moc);
    _inMocs.add(mocs);
  }

  Future<void> deletePart(Moc moc, CollectablePartGroup group, BrickPart part) async {
    group.parts.remove(part);
    moc.parts?.remove(part);

    await saveMoc(moc);
  }
}
