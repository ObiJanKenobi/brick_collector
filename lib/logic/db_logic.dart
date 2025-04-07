import 'package:brick_collector/model/filter_preset.dart';
import 'package:brick_collector/model/moc.dart';
import 'package:isar/isar.dart';

import 'package:path_provider/path_provider.dart';

class DbLogic {
  late final Isar _isar;

  Future<void> bootstrap() async {
    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open([MocSchema, FilterPresetSchema], directory: dir.path);
  }

  Future<List<Moc>> getMocs() async {
    final mocs = await _isar.mocs.where().findAll();

    return mocs;
  }

  saveMoc(Moc newMoc) async {
    await _isar.writeTxn(() async {
      await _isar.mocs.put(newMoc);
    });
  }

  deleteMoc(Moc moc) async {
    await _isar.writeTxn(() async {
      await _isar.mocs.delete(moc.id);
    });
  }

  Future<List<FilterPreset>> getPresets() async {
    final presets = await _isar.filterPresets.where().findAll();

    return presets;
  }

  savePreset(FilterPreset newPreset) async {
    await _isar.writeTxn(() async {
      await _isar.filterPresets.put(newPreset);
    });
  }

  deletePreset(FilterPreset preset) async {
    await _isar.writeTxn(() async {
      await _isar.filterPresets.delete(preset.id);
    });
  }
}
