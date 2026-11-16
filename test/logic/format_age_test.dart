import 'package:brick_collector/util/format_age.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 16, 12);

  test('formatAge buckets by minutes, hours and days', () {
    expect(formatAge(now.subtract(const Duration(seconds: 30)), now: now), 'just now');
    expect(formatAge(now.subtract(const Duration(minutes: 5)), now: now), '5m ago');
    expect(formatAge(now.subtract(const Duration(hours: 3)), now: now), '3h ago');
    expect(formatAge(now.subtract(const Duration(days: 2, hours: 5)), now: now), '2d ago');
  });
}
