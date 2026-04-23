import 'package:brick_collector/common_libs.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Tries each URL in [candidates] in order; on load failure advances to the next.
/// When the list is exhausted, optionally calls [onExhausted] for one last async
/// URL fetch (e.g. an API lookup) before giving up and rendering [fallback].
class SmartPartImage extends StatefulWidget {
  final List<String> candidates;
  final Future<String?> Function()? onExhausted;
  final BoxFit fit;
  final Widget fallback;

  const SmartPartImage({
    required this.candidates,
    required this.fallback,
    this.onExhausted,
    this.fit = BoxFit.contain,
    super.key,
  });

  @override
  State<SmartPartImage> createState() => _SmartPartImageState();
}

class _SmartPartImageState extends State<SmartPartImage> {
  int _index = 0;
  bool _triedExhausted = false;
  String? _extraUrl;

  List<String> get _all => _extraUrl != null ? [...widget.candidates, _extraUrl!] : widget.candidates;

  @override
  void didUpdateWidget(SmartPartImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.candidates.isNotEmpty &&
        (oldWidget.candidates.isEmpty || widget.candidates.first != oldWidget.candidates.first)) {
      _index = 0;
      _triedExhausted = false;
      _extraUrl = null;
    }
  }

  Future<void> _askExhausted() async {
    _triedExhausted = true;
    final url = await widget.onExhausted?.call();
    if (!mounted) return;
    if (url != null && url.isNotEmpty) {
      setState(() {
        _extraUrl = url;
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _all;
    if (list.isEmpty || _index >= list.length) {
      if (!_triedExhausted && widget.onExhausted != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_triedExhausted) _askExhausted();
        });
      }
      return widget.fallback;
    }
    final url = list[_index];
    return CachedNetworkImage(
      key: ValueKey(url),
      imageUrl: url,
      fit: widget.fit,
      errorWidget: (context, url, error) {
        debugPrint('[SmartPartImage] failed $url: advancing');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _index++);
        });
        return widget.fallback;
      },
    );
  }
}
