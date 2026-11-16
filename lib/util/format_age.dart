/// Compact age of [dt] relative to [now] (default: the current time), e.g.
/// "just now", "5m ago", "3h ago", "2d ago".
String formatAge(DateTime dt, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
