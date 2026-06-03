import 'dart:async';

import 'package:brick_collector/model/filter_preset.dart';
import 'package:brick_collector/services/group_service.dart';

import 'package:brick_collector/common_libs.dart';
import 'package:brick_lib/model/rebrickable_color.dart';
import 'package:brick_lib/model/rebrickable_part_category.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _presetMigrationFlag = 'presets_migrated_v1';

class PartsLogic {
  final Logger _log = getLogger('PartsLogic');

  ///
  /// Filter presets — sourced from Firestore (per-group). The BehaviorSubject
  /// caches the latest list so screens that need synchronous access (e.g. the
  /// router resolving /preset/:id) don't have to wait for a fresh emission.
  ///
  final BehaviorSubject<List<FilterPreset>> _presetListController = BehaviorSubject.seeded([]);

  Stream<List<FilterPreset>> get outPresets => _presetListController.stream;

  List<FilterPreset> get presets => _presetListController.value;

  StreamSubscription<List<FilterPreset>>? _presetsSub;

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
    _partCategories.addAll(await rbService.getPartCategories());
    _colors.addAll(await rbService.getColors());

    _inPartCategories.add(_partCategories);
    _inColors.add(_colors);

    _resubscribePresets();
    // Re-point the preset stream whenever the active group changes (or one is
    // created/joined for the first time). Also drives the legacy-preset
    // migration check.
    GroupService.instance.activeGroupNotifier.addListener(_resubscribePresets);
  }

  void _resubscribePresets() {
    _presetsSub?.cancel();
    if (!GroupService.instance.hasGroup) {
      _presetListController.add(const []);
      return;
    }
    // Fire and forget — migration runs once per install, gated by a prefs flag.
    unawaited(_maybeMigrateLegacyPresets());
    _presetsSub = dbLogic.watchPresets().listen(
      _presetListController.add,
      onError: (e, st) => _log.w('preset stream error: $e'),
    );
  }

  Future<void> _maybeMigrateLegacyPresets() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_presetMigrationFlag) == true) return;
    if (!GroupService.instance.hasGroup) return;

    final legacy = await dbLogic.readLegacyLocalPresets();
    if (legacy.isEmpty) {
      await prefs.setBool(_presetMigrationFlag, true);
      return;
    }

    for (final p in legacy) {
      p.firestoreId = null; // force a fresh Firestore doc
      try {
        await dbLogic.savePreset(p);
      } catch (e) {
        _log.w('failed to migrate legacy preset "${p.name}": $e');
        return; // leave flag unset so we retry on the next bootstrap
      }
    }
    await dbLogic.clearLegacyLocalPresets();
    await prefs.setBool(_presetMigrationFlag, true);
    _log.i('migrated ${legacy.length} legacy preset(s) to Firestore');
  }

  Future<FilterPreset> addNewPreset(String name) async {
    final newPreset = FilterPreset(name: name)
      ..categories = []
      ..colors = [];

    await savePreset(newPreset);
    return newPreset;
  }

  FilterPreset? getPresetById(String firestoreId) {
    return presets.cast<FilterPreset?>().firstWhere(
          (p) => p!.firestoreId == firestoreId,
          orElse: () => null,
        );
  }

  Future<FilterPreset> savePreset(FilterPreset preset) async {
    await dbLogic.savePreset(preset);
    return preset;
  }

  Future<void> deletePreset(FilterPreset preset) async {
    await dbLogic.deletePreset(preset);
  }
}
