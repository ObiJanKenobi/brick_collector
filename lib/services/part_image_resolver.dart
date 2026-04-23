import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/cached_inventory_item.dart';

class NeededColor {
  NeededColor({required this.colorId, required this.qty, this.name});
  final int colorId;
  final int qty;
  final String? name;
}

class PartImageResolver {
  /// Rebrickable CDN URL pattern. Path uses LDraw color ids; Rebrickable ids
  /// align for common colors but may 404 for uncommon ones — the image widget's
  /// errorBuilder should fall back when that happens.
  static String buildCdnUrl(String partNum, int colorId) =>
      'https://cdn.rebrickable.com/media/thumbs/parts/ldraw/$colorId/$partNum.png/85x85p.png';

  static bool debugVerbose = true;

  /// Returns a list of image URL candidates in priority order:
  ///   1. Isar cache rows for needed colors (known-good, by need desc)
  ///   2. Synthesized CDN urls for needed colors not in cache (may 404)
  ///   3. Isar cache rows for any owned color (fallback)
  /// SmartPartImage will try them in order and advance on network failure.
  static Future<List<String>> resolveCandidates(String partNum, List<NeededColor> colorsByNeed) async {
    final urls = <String>[];
    if (partNum.isEmpty || partNum == '-') return urls;

    if (debugVerbose) {
      final needsStr = colorsByNeed.map((c) => '${c.name ?? "#"}(id=${c.colorId}, qty=${c.qty})').join(', ');
      debugPrint('[PartImageResolver] $partNum: needed=[$needsStr]');
    }

    final items = await dbLogic.findItemsForPart(partNum);
    final byColor = <int, List<CachedInventoryItem>>{};
    for (final i in items) {
      byColor.putIfAbsent(i.colorId, () => []).add(i);
    }

    // Synthesized URLs are authoritative when they exist (LDraw model + color), so try
    // them first. Fall back to cached row urls (may be mismatched post-sync for partlist
    // entries where the API returns a generic image), then to API lookup via onExhausted.
    for (final c in colorsByNeed) {
      final synth = buildCdnUrl(partNum, c.colorId);
      if (debugVerbose) {
        debugPrint('[PartImageResolver] $partNum: synth ${c.name ?? "#${c.colorId}"} (id=${c.colorId}) -> $synth');
      }
      urls.add(synth);

      final match = byColor[c.colorId]?.firstWhereOrNull((i) => (i.imgUrl ?? '').isNotEmpty);
      if (match != null) {
        if (debugVerbose) {
          debugPrint('[PartImageResolver] $partNum: cache row for ${c.name ?? "#${c.colorId}"} -> ${match.imgUrl}');
        }
        urls.add(match.imgUrl!);
      }
    }

    return urls;
  }

  // Session-only API lookup cache. Keys: "<partNum>_<colorId>".
  // Value is the resolved URL, or null if the API returned nothing / failed.
  static final Map<String, String?> _apiCache = {};
  static final Map<String, Future<String?>> _apiInFlight = {};

  static String _apiKey(String partNum, int colorId) => '${partNum}_$colorId';

  /// Last-resort API lookup for the real CDN url (handles parts with no LDraw render,
  /// which use `parts/elements/{element_id}.jpg` instead of `parts/ldraw/…`).
  /// Called only after all synthesized URLs have 404'd.
  /// Results cached for the app session.
  static Future<String?> fetchApiUrl(String partNum, int colorId) async {
    final key = _apiKey(partNum, colorId);
    if (_apiCache.containsKey(key)) return _apiCache[key];
    final inFlight = _apiInFlight[key];
    if (inFlight != null) return inFlight;

    final future = _doFetchApi(partNum, colorId, key);
    _apiInFlight[key] = future;
    return future;
  }

  static Future<String?> _doFetchApi(String partNum, int colorId, String key) async {
    try {
      final info = await rbService.getPartColor(partNum, colorId);
      final url = info?.imgUrl;
      if (url != null && url.isNotEmpty) {
        debugPrint('[PartImageResolver] $partNum color $colorId: recovered via API -> $url');
        _apiCache[key] = url;
        return url;
      }
      _apiCache[key] = null;
    } catch (e) {
      debugPrint('[PartImageResolver] $partNum color $colorId: API fallback failed: $e');
      // Don't cache failures — let a retry happen on next attempt.
    } finally {
      _apiInFlight.remove(key);
    }
    return null;
  }
}
