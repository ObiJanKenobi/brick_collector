import 'dart:io';

import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/CollectablePartGroup.dart';
import 'package:brick_collector/model/collectable_part.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _rbTokenKey = 'rb_user_token';
const _rbUsernameKey = 'rb_username';
const _cacheSchemaKey = 'inventory_cache_schema_version';
const _cacheSchemaVersion = 2;

class AppLogic {
  final Logger log = getLogger("AppLogic");

  /// Indicates to the rest of the app that bootstrap has not completed.
  /// The router will use this to prevent redirects while bootstrapping.
  bool isBootstrapComplete = false;

  bool _loggedIn = false;
  String? _username;

  bool get loggedIn => _loggedIn;
  String? get username => _username;

  Future<void> bootstrap() async {
    await brickConverterLogic.load();
    await dbLogic.bootstrap();
    await partsLogic.bootstrap();
    await _migrateCacheIfNeeded();
    await _restoreLogin();

    isBootstrapComplete = true;

    appRouter.go(ScreenPaths.home);
  }

  Future<void> _migrateCacheIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_cacheSchemaKey);
    if (stored == _cacheSchemaVersion) return;

    log.i('Inventory cache schema $stored -> $_cacheSchemaVersion: clearing cache');
    try {
      await dbLogic.clearInventoryCache();
    } catch (e) {
      log.w('Failed to clear inventory cache during migration: $e');
    }
    await prefs.remove('collection_last_sync_at');
    await prefs.setInt(_cacheSchemaKey, _cacheSchemaVersion);
  }

  Future<void> _restoreLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_rbTokenKey);
    if (token != null && token.isNotEmpty) {
      rbService.restoreToken(token);
      _loggedIn = true;
      _username = prefs.getString(_rbUsernameKey);
    }
  }

  reset() {}

  Future<List<BrickPart>?> loadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv'], allowMultiple: true);
    if (result != null) {
      final allParts = <BrickPart>[];
      for (var i = 0; i < result.files.length; ++i) {
        final fileRef = result.files[i];

        File file = File(fileRef.path!);

        log.i("Loading parts from ${fileRef.name}");

        // final filenameWithoutExtension =
        //     result.files.single.name.split(".csv")[0];
        // mocName = filenameWithoutExtension.replaceFirst("rebrickable_parts_", "");

        String content = await file.readAsString();
        List<String> csvLines = content.split("\r\n");
        final List<BrickPart> parts = await brickConverterLogic.parseParts(csvLines);

        allParts.addAll(parts);
      }

      return allParts;
    } else {
      // User canceled the picker
      return null;
    }
  }

  Map<String, CollectablePartGroup> groupParts(List<CollectablePart> parts) {
    final Map<String, CollectablePartGroup> groupedParts = {};

    for (var i = 0; i < parts.length; ++i) {
      final part = parts[i];
      if (groupedParts.containsKey(part.part) == false) {
        groupedParts[part.part!] = CollectablePartGroup();
      }
      groupedParts[part.part]?.addPart(part);
    }

    return groupedParts;
  }

  void orderPart(PartGroup group, BrickPart part) {
    // collectedParts.add(part);
    // group.parts.remove(part);
    //
    // if (group.parts.isEmpty) {
    //   groupedParts.remove(part.part);
    //   updateGroups();
    // }
  }

  void removeFromOrdered(BrickPart part) {
    // collectedParts.remove(part);
    // final group = groupedParts[part.part];
    // group?.addPart(part);
  }

  Future<void> saveOrdered() async {
    // final export = brickConverterLogic.exportParts(collectedParts);
    // final f = DateFormat('yyyy-MM-dd');
    // String? outputFile = await FilePicker.platform.saveFile(
    //   dialogTitle: 'Please select an output file:',
    //   fileName: '${f.format(DateTime.now())}-export-parts-ordered.csv',
    // );
    //
    // if (outputFile != null) {
    //   final file = File(outputFile);
    //   await file.writeAsString(export.join("\r\n"));
    // }
  }

  addPartsToMoc(Moc moc) async {
    final List<BrickPart>? parts = await loadFile();
    if (parts == null) return;
    final List<CollectablePart> partsList = parts.map((e) => CollectablePart.fromPart(e)).toList();

    moc.parts ??= [];

    final merged = mergeParts(moc.parts!, partsList);
    moc.parts = merged;

    await mocLogic.saveMoc(moc);
  }

  List<CollectablePart> mergeParts(List<CollectablePart> parts, List<CollectablePart> partsList) {
    final merged = <CollectablePart>[];
    merged.addAll(parts);

    for (var part in partsList) {
      final index = merged.indexWhere((element) => element.part == part.part && element.color == part.color);
      if (index == -1) {
        merged.add(part);
      } else {
        final existingPart = merged[index];
        existingPart.quantity += part.quantity;
      }
    }

    return merged;
  }

  Future<bool> loginUser(String username, String password) async {
    final token = await rbService.login(username, password);
    if (token == null) {
      _loggedIn = false;
      return false;
    }
    _loggedIn = true;
    _username = username;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rbTokenKey, token);
    await prefs.setString(_rbUsernameKey, username);
    return true;
  }

  Future<void> logout() async {
    _loggedIn = false;
    _username = null;
    rbService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rbTokenKey);
    await prefs.remove(_rbUsernameKey);
    await dbLogic.clearInventoryCache();
  }
}
