class RebrickableUrlParseResult {
  final String mocId;
  final String displayName;
  final String originalUrl;
  final String imageUrl;

  RebrickableUrlParseResult({
    required this.mocId,
    required this.displayName,
    required this.originalUrl,
    required this.imageUrl,
  });
}

class RebrickableUrlParser {
  /// Tries to parse a Rebrickable MOC URL like:
  /// https://rebrickable.com/mocs/MOC-257725/The_Astral_J/scary-space-monster/
  static RebrickableUrlParseResult? tryParse(String input) {
    final trimmed = input.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.host.endsWith('rebrickable.com')) return null;

    // Path segments: ['mocs', 'MOC-257725', 'The_Astral_J', 'scary-space-monster', '']
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 4 || segments[0] != 'mocs') return null;

    final mocSegment = segments[1]; // e.g. "MOC-257725"
    if (!mocSegment.startsWith('MOC-')) return null;

    final mocId = mocSegment.substring(4); // "257725"
    final nameSlug = segments[3]; // "scary-space-monster"

    final displayName = nameSlug
        .split('-')
        .map((word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');

    return RebrickableUrlParseResult(
      mocId: mocId,
      displayName: displayName,
      originalUrl: trimmed,
      imageUrl: 'https://cdn.rebrickable.com/media/mocs/moc-$mocId.jpg',
    );
  }

  /// Quick check if input looks like a URL.
  static bool looksLikeUrl(String input) => input.trimLeft().startsWith('http');
}
