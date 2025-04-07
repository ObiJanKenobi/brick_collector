import 'package:brick_collector/model/CollectablePartGroup.dart';
import 'package:brick_collector/model/filter_preset.dart';
import 'package:brick_collector/model/moc.dart';

import 'package:brick_collector/common_libs.dart';
import 'package:brick_lib/model/rebrickable_color.dart';
import 'package:brick_lib/model/rebrickable_part_category.dart';
import 'package:rxdart/rxdart.dart';

class PartsLogic {
  ///
  /// Filter presets
  ///
  final BehaviorSubject<List<FilterPreset>> _presetListController = BehaviorSubject.seeded([]);

  Sink<List<FilterPreset>> get _inPresets => _presetListController.sink;

  Stream<List<FilterPreset>> get outPresets => _presetListController.stream;

  final List<FilterPreset> _presets = [];

  List<FilterPreset> get presets => _presets;

  ///
  /// Part categories
  ///
  final BehaviorSubject<List<RebrickablePartCategory>> _partCategoriesListController = BehaviorSubject.seeded([]);

  Sink<List<RebrickablePartCategory>> get _inPartCategories => _partCategoriesListController.sink;

  Stream<List<RebrickablePartCategory>> get outPartCategories => _partCategoriesListController.stream;

  final List<RebrickablePartCategory> _partCategories = [];

  List<RebrickablePartCategory> get partCategories => _partCategories;

  ///
  /// Colors
  ///
  final BehaviorSubject<List<RebrickableColor>> _colorsListController = BehaviorSubject.seeded([]);

  Sink<List<RebrickableColor>> get _inColors => _colorsListController.sink;

  Stream<List<RebrickableColor>> get outColors => _colorsListController.stream;

  final List<RebrickableColor> _colors = [];

  List<RebrickableColor> get colors => _colors;

  Future<void> bootstrap() async {
    _presets.addAll(await dbLogic.getPresets());
    _partCategories.addAll(await rbService.getPartCategories());
    _colors.addAll(await rbService.getColors());

    _inPresets.add(_presets);
    _inPartCategories.add(_partCategories);
    _inColors.add(_colors);
  }

  Future<FilterPreset> addNewPreset(String name) async {
    final newPreset = FilterPreset(name: name)
      ..categories = []
      ..colors = [];

    await savePreset(newPreset);

    _presets.add(newPreset);
    _inPresets.add(_presets);

    return newPreset;
  }

  FilterPreset getPresetById(int id) {
    final newPreset = _presets.where((e) => e.id == id).first;

    return newPreset;
  }

  Future<FilterPreset> savePreset(FilterPreset preset) async {
    await dbLogic.savePreset(preset);

    return preset;
  }

  deletePreset(FilterPreset preset) async {
    await dbLogic.deletePreset(preset);
    _presets.remove(preset);
    _inPresets.add(_presets);
  }

  loadParts(FilterPreset preset) async {
    await rbService.getUserParts();
    _presets.remove(preset);
    _inPresets.add(_presets);
  }
}
