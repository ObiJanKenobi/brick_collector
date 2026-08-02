import 'dart:async';

import 'package:brick_collector/common_libs.dart';
import 'package:brick_lib/model/rebrickable_set.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Bottom sheet for adding a set to the user's Rebrickable collection.
///
/// Searches the Rebrickable set catalogue (number or name both work) and POSTs
/// the pick to `/users/{token}/sets/`. The set is added remotely, so it shows
/// up on rebrickable.com too — this is not a local-only record.
///
/// Pops the added [RebrickableSet] on success, or null if cancelled.
class AddSetModal extends StatefulWidget {
  const AddSetModal({super.key});

  @override
  State<AddSetModal> createState() => _AddSetModalState();
}

class _AddSetModalState extends State<AddSetModal> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<RebrickableSet>? _results;
  bool _searching = false;
  String? _addingSetNum;
  String? _error;
  int _quantity = 1;

  /// Guards against an earlier, slower search overwriting a later one.
  int _searchSeq = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = null;
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String query) async {
    final seq = ++_searchSeq;
    final results = await rbService.searchSets(query);
    if (!mounted || seq != _searchSeq) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  Future<void> _add(RebrickableSet set) async {
    setState(() {
      _addingSetNum = set.setNum;
      _error = null;
    });
    try {
      await rbService.addUserSet(set.setNum, quantity: _quantity);
      if (!mounted) return;
      Navigator.of(context).pop(set);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _addingSetNum = null;
        _error = 'Could not add ${set.setNum}: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final loggedIn = rbService.loggedIn;

    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Add set',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            if (!loggedIn)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Log in to Rebrickable to add sets to your collection.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: _onQueryChanged,
                  onSubmitted: (v) {
                    _debounce?.cancel();
                    if (v.trim().isNotEmpty) _search(v);
                  },
                  decoration: InputDecoration(
                    hintText: 'Set number or name, e.g. 75192 or Falcon',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onQueryChanged('');
                            },
                          ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    const Text('Quantity', style: TextStyle(color: AppColors.textSecondary)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed:
                          _quantity > 1 ? () => setState(() => _quantity--) : null,
                    ),
                    Text('$_quantity',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.highlightColor, fontSize: 12)),
                ),
              Expanded(child: _buildResults(results, scrollController)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResults(List<RebrickableSet>? results, ScrollController controller) {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (results == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Search the Rebrickable catalogue to add a set.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    if (results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No sets found.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    return ListView.builder(
      controller: controller,
      itemCount: results.length,
      itemBuilder: (context, index) => _buildResult(results[index]),
    );
  }

  Widget _buildResult(RebrickableSet set) {
    final busy = _addingSetNum == set.setNum;
    final anyBusy = _addingSetNum != null;
    final meta = <String>[
      set.setNum,
      if (set.year > 0) '${set.year}',
      '${set.numParts} parts',
    ].join(' · ');

    return ListTile(
      leading: SizedBox(
        width: 52,
        height: 52,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(4),
            child: (set.setImgUrl != null && set.setImgUrl!.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: set.setImgUrl!,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.widgets_outlined, color: AppColors.textSecondary),
                  )
                : const Icon(Icons.widgets_outlined, color: AppColors.textSecondary),
          ),
        ),
      ),
      title: Text(set.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(meta, style: const TextStyle(fontSize: 11)),
      trailing: busy
          ? const SizedBox(
              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.add_circle_outline, color: AppColors.highlightColor),
      onTap: anyBusy ? null : () => _add(set),
    );
  }
}
