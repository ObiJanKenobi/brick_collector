import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/CollectablePartGroup.dart';
import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/services/group_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _rbTokenKey = 'rb_user_token';
const _rbUsernameKey = 'rb_username';
const _cacheSchemaKey = 'inventory_cache_schema_version';
const _cacheSchemaVersion = 3;

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

    // Keep set/partlist exclusions in sync across devices (same pattern as
    // the preset stream in PartsLogic).
    _resubscribeExclusions();
    GroupService.instance.activeGroupNotifier.addListener(_resubscribeExclusions);

    isBootstrapComplete = true;

    appRouter.go(ScreenPaths.home);
  }

  StreamSubscription<Set<String>?>? _exclusionsSub;

  void _resubscribeExclusions() {
    _exclusionsSub?.cancel();
    _exclusionsSub = null;
    if (!GroupService.instance.hasGroup) return;

    _exclusionsSub = dbLogic.watchExcludedSourceKeys().listen((keys) async {
      if (keys == null) {
        // Doc doesn't exist yet for this group: seed it from whatever this
        // device has excluded locally (no-op when nothing is excluded).
        await dbLogic.pushLocalExclusionsToFirestore();
        return;
      }
      await dbLogic.applyExcludedSourceKeys(keys);
    }, onError: (Object e) => log.w('exclusions stream error: $e'));
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      // .io is a LEGO Studio project (a ZIP holding an LDraw model); .csv is a
      // Rebrickable or Studio part-list export.
      allowedExtensions: ['csv', 'io'],
      allowMultiple: true,
    );
    if (result == null) {
      // User canceled the picker
      return null;
    }

    final allParts = <BrickPart>[];
    for (final fileRef in result.files) {
      log.i("Loading parts from ${fileRef.name}");
      try {
        final parts = fileRef.name.toLowerCase().endsWith('.io')
            ? await _parseStudioIoFile(fileRef)
            : await _parseCsvFile(fileRef);
        allParts.addAll(parts);
      } catch (e) {
        log.w("Failed to import ${fileRef.name}: $e");
      }
    }

    return allParts;
  }

  Future<List<BrickPart>> _parseCsvFile(PlatformFile fileRef) async {
    final content = await _readAsString(fileRef);
    final csvLines = const LineSplitter().convert(content);
    return brickConverterLogic.parseParts(csvLines);
  }

  /// A Studio `.io` file is a ZIP archive; `model.ldr` inside it is the LDraw
  /// representation of the build, which [BrickConverterLogic.parseLdr] flattens
  /// into a part list.
  Future<List<BrickPart>> _parseStudioIoFile(PlatformFile fileRef) async {
    final bytes = await _readAsBytes(fileRef);
    final archive = ZipDecoder().decodeBytes(bytes);
    final ldr = archive.findFile('model.ldr');
    if (ldr == null) {
      throw const FormatException('Not a Studio model: model.ldr is missing');
    }
    final content = utf8.decode(ldr.content, allowMalformed: true);
    final ldrLines = const LineSplitter().convert(content);
    return brickConverterLogic.parseLdr(ldrLines);
  }

  Future<String> _readAsString(PlatformFile fileRef) async {
    final bytes = fileRef.bytes;
    if (bytes != null) return utf8.decode(bytes, allowMalformed: true);
    return File(fileRef.path!).readAsString();
  }

  Future<List<int>> _readAsBytes(PlatformFile fileRef) async {
    final bytes = fileRef.bytes;
    if (bytes != null) return bytes;
    return File(fileRef.path!).readAsBytes();
  }

  Map<String, CollectablePartGroup> groupParts(List<CollectablePart> parts) {
    final Map<String, CollectablePartGroup> groupedParts = {};

    for (var i = 0; i < parts.length; ++i) {
      final part = parts[i];
      if (groupedParts.containsKey(part.part) == false) {
        groupedParts[part.part!] = CollectablePartGroup();
      }
      // Append directly instead of PartGroup.addPart: addPart merges
      // same-colour duplicates by MUTATING the existing part's quantity.
      // With persisted MOC parts this runs on every rebuild and silently
      // inflates the stored quantity. Duplicates are merged once, properly,
      // by [dedupeMocParts] / [mergeParts] instead.
      groupedParts[part.part]?.parts.add(part);
    }

    return groupedParts;
  }

  /// Merges duplicate part+colour entries in [moc.parts] in place, summing
  /// quantity and collected count. Returns true if anything was merged.
  /// Repairs data corrupted by the old mutate-on-group behaviour.
  bool dedupeMocParts(Moc moc) {
    final parts = moc.parts;
    if (parts == null || parts.isEmpty) return false;

    final byKey = <String, CollectablePart>{};
    final deduped = <CollectablePart>[];
    for (final part in parts) {
      final key = '${part.part}_${part.color}';
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = part;
        deduped.add(part);
      } else {
        existing.quantity += part.quantity;
        existing.collectedCount += part.collectedCount;
      }
    }

    if (deduped.length == parts.length) return false;
    moc.parts = deduped;
    return true;
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
