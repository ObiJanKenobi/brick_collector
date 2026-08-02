import 'package:brick_collector/common_libs.dart';
import 'package:brick_lib/model/rebrickable_moc.dart';
import 'package:brick_lib/request/GetBuildMatch.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

/// Alternate builds for one owned set - MOCs whose parts are all contained in
/// that set, the same list as the set's "Alternate Builds" tab on rebrickable.
///
/// Rebrickable exposes no MOC inventory endpoint, so an alternate's part list
/// cannot be imported directly. Tapping a row opens the MOC page, where the
/// part list can be exported as CSV and then loaded through the app's normal
/// MOC import.
class AlternateBuildsModal extends StatefulWidget {
  const AlternateBuildsModal({required this.setNum, required this.setName, super.key});

  final String setNum;
  final String setName;

  @override
  State<AlternateBuildsModal> createState() => _AlternateBuildsModalState();
}

class _AlternateBuildsModalState extends State<AlternateBuildsModal> {
  /// How many alternates get a Build Match lookup. Each one is a throttled
  /// request, so a set with dozens of alternates would otherwise stall.
  static const _matchLimit = 25;

  List<RebrickableMoc>? _alternates;
  String? _error;

  final Map<String, BuildMatch> _matches = {};
  bool _checkingMatches = false;
  int _matchesSkipped = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final alternates = await rbService.getSetAlternates(widget.setNum);
      if (!mounted) return;
      setState(() => _alternates = alternates);
      _loadMatches(alternates);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  /// Fetches Build Match percentages one at a time, updating rows as they
  /// arrive so the list stays usable while this runs.
  Future<void> _loadMatches(List<RebrickableMoc> alternates) async {
    if (!rbService.loggedIn || alternates.isEmpty) return;
    final targets = alternates.take(_matchLimit).toList();
    setState(() {
      _checkingMatches = true;
      _matchesSkipped = alternates.length - targets.length;
    });
    for (final moc in targets) {
      final match = await rbService.getBuildMatch(moc.setNum);
      if (!mounted) return;
      if (match != null && match.hasMatch) {
        setState(() => _matches[moc.setNum] = match);
      }
    }
    if (mounted) setState(() => _checkingMatches = false);
  }

  Future<void> _openMoc(RebrickableMoc moc) async {
    final url = moc.mocUrl;
    if (url == null || url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Alternate builds',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(
                        '${widget.setNum} · ${widget.setName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(child: Text(_statusLine(), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                if (_checkingMatches)
                  const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          ),
          Expanded(child: _buildBody(scrollController)),
        ],
      ),
    );
  }

  String _statusLine() {
    if (_error != null) return 'Could not load alternate builds.';
    final alternates = _alternates;
    if (alternates == null) return 'Loading…';
    if (alternates.isEmpty) return 'No alternate builds for this set.';
    final base = '${alternates.length} alternate build${alternates.length == 1 ? "" : "s"}';
    if (!rbService.loggedIn) return '$base · log in to see what you can build';
    if (_checkingMatches) return '$base · checking what you can build…';
    if (_matchesSkipped > 0) return '$base · build match checked for the first $_matchLimit';
    return base;
  }

  Widget _buildBody(ScrollController controller) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.highlightColor)),
      );
    }
    final alternates = _alternates;
    if (alternates == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (alternates.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Rebrickable lists no MOCs that can be built\nfrom this set alone.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: controller,
      itemCount: alternates.length,
      itemBuilder: (context, index) => _buildAlternate(alternates[index]),
    );
  }

  Widget _buildAlternate(RebrickableMoc moc) {
    final match = _matches[moc.setNum];
    final meta = <String>[
      '${moc.numParts} parts',
      if (moc.year > 0) '${moc.year}',
      if (moc.designerName != null && moc.designerName!.isNotEmpty) 'by ${moc.designerName}',
    ].join(' · ');

    return ListTile(
      leading: SizedBox(
        width: 56,
        height: 56,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(3),
            child: (moc.mocImgUrl != null && moc.mocImgUrl!.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: moc.mocImgUrl!,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.extension_outlined, color: AppColors.textSecondary),
                  )
                : const Icon(Icons.extension_outlined, color: AppColors.textSecondary),
          ),
        ),
      ),
      title: Text(moc.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(meta, style: const TextStyle(fontSize: 11)),
          if (match != null) _buildMatchBadge(match),
        ],
      ),
      trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.textSecondary),
      onTap: () => _openMoc(moc),
    );
  }

  Widget _buildMatchBadge(BuildMatch match) {
    final pct = match.matchPercent!;
    final complete = pct >= 100;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        complete
            ? 'You can build this'
            : '${pct.toStringAsFixed(0)}% of parts in your collection',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: complete ? Colors.greenAccent : AppColors.highlightColor,
        ),
      ),
    );
  }
}
