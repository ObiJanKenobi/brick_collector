import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:brick_collector/logic/db_logic.dart';
import 'package:brick_collector/model/cached_inventory_item.dart';
import 'package:brick_collector/model/cached_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

/// The libisar.dylib that isar_community_flutter_libs ships for macOS, or null
/// on other hosts. Lets this test run against the real query engine offline.
String? _hostIsarLibrary() {
  if (!Platform.isMacOS) return null;
  final config = jsonDecode(File('.dart_tool/package_config.json').readAsStringSync()) as Map<String, dynamic>;
  final pkg = (config['packages'] as List)
      .cast<Map<String, dynamic>>()
      .firstWhere((p) => p['name'] == 'isar_community_flutter_libs', orElse: () => const {});
  final root = pkg['rootUri'] as String?;
  if (root == null) return null;
  final lib = File.fromUri(Uri.parse('$root/macos/libisar.dylib'));
  return lib.existsSync() ? lib.path : null;
}

CachedInventoryItem _item(String partNum, int colorId, {String? name, int? category, int qty = 1, String source = 's1'}) =>
    CachedInventoryItem()
      ..sourceType = CachedSourceType.set
      ..sourceExternalId = source
      ..partNum = partNum
      ..partName = name
      ..partCategoryId = category
      ..colorId = colorId
      ..quantity = qty;

void main() {
  final library = _hostIsarLibrary();
  late Isar isar;
  late Directory dir;
  late DbLogic db;

  setUpAll(() async {
    if (library == null) return;
    await Isar.initializeIsarCore(libraries: {Abi.current(): library});
  });

  setUp(() async {
    if (library == null) return;
    dir = await Directory.systemTemp.createTemp('filter_inventory_test');
    isar = await Isar.open([CachedSourceSchema, CachedInventoryItemSchema], directory: dir.path);
    await isar.writeTxn(() async {
      await isar.cachedSources.put(CachedSource()
        ..type = CachedSourceType.set
        ..externalId = 'excluded'
        ..name = 'Excluded set'
        ..excludeFromInventory = true);
      await isar.cachedInventoryItems.putAll([
        _item('3001', 4, name: 'Brick 2 x 4', category: 11, qty: 2),
        _item('3001', 4, name: 'Brick 2 x 4', category: 11, qty: 3, source: 's2'),
        _item('3001', 0, name: 'Brick 2 x 4', category: 11, qty: 1),
        _item('3020', 4, name: 'Plate 2 x 4', category: 14, qty: 5),
        _item('3062', 0, category: 20, qty: 7), // no name
        _item('3001', 4, name: 'Brick 2 x 4', category: 11, qty: 100, source: 'excluded'),
      ]);
    });
    db = DbLogic()..useIsar(isar);
  });

  tearDown(() async {
    if (library == null) return;
    await isar.close(deleteFromDisk: true);
    await dir.delete(recursive: true);
  });

  Map<String, int> summarize(List<AggregatedInventoryRow> rows) =>
      {for (final r in rows) '${r.partNum}/${r.colorId}': r.quantity};

  test('no criteria returns everything except excluded sources, summed per part+colour', () async {
    expect(summarize(await db.filterInventory()), {'3001/4': 5, '3001/0': 1, '3020/4': 5, '3062/0': 7});
  }, skip: library == null ? 'needs the macOS libisar.dylib' : false);

  test('criteria combine with AND, values within one criterion with OR', () async {
    expect(summarize(await db.filterInventory(colorIds: {4})), {'3001/4': 5, '3020/4': 5});
    expect(summarize(await db.filterInventory(categoryIds: {11, 20})), {'3001/4': 5, '3001/0': 1, '3062/0': 7});
    expect(summarize(await db.filterInventory(colorIds: {4}, categoryIds: {14})), {'3020/4': 5});
    expect(summarize(await db.filterInventory(colorIds: {0}, categoryIds: {11}, searchText: 'brick')), {'3001/0': 1});
  }, skip: library == null ? 'needs the macOS libisar.dylib' : false);

  test('search is a trimmed, case-insensitive substring match and skips unnamed parts', () async {
    expect(summarize(await db.filterInventory(searchText: '  PLATE ')), {'3020/4': 5});
    expect(summarize(await db.filterInventory(searchText: '2 x 4')), {'3001/4': 5, '3001/0': 1, '3020/4': 5});
    expect(summarize(await db.filterInventory(searchText: '   ')), {'3001/4': 5, '3001/0': 1, '3020/4': 5, '3062/0': 7});
  }, skip: library == null ? 'needs the macOS libisar.dylib' : false);
}
