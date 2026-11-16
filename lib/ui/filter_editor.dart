import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/filter_preset.dart';
import 'package:brick_lib/model/rebrickable_color.dart';
import 'package:brick_lib/model/rebrickable_part_category.dart';

/// Name search + part category + colour picker, shared by preset editing and
/// the All Parts on-demand filter. Edits [filter] in place; the host decides
/// when (and whether) the result is saved or applied.
class FilterEditor extends StatefulWidget {
  const FilterEditor({
    super.key,
    required this.filter,
    required this.appBar,
    this.onSearchSubmitted,
  });

  final FilterPreset filter;

  /// Leading sliver, typically a pinned [SliverAppBar].
  final Widget appBar;

  /// Called when the user presses enter in the search field.
  final VoidCallback? onSearchSubmitted;

  @override
  State<FilterEditor> createState() => _FilterEditorState();
}

class _FilterEditorState extends State<FilterEditor> {
  final TextEditingController _searchController = TextEditingController();

  FilterPreset get _filter => widget.filter;

  @override
  void initState() {
    super.initState();
    _searchController.text = _filter.searchText ?? '';
  }

  @override
  void didUpdateWidget(FilterEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The host swapped in a different filter (e.g. "Clear all"): show its text.
    if (!identical(oldWidget.filter, widget.filter)) {
      _searchController.text = widget.filter.searchText ?? '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _sectionHeader(String title) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: AppColors.surface,
      automaticallyImplyLeading: false,
      title: Text(title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [
      widget.appBar,
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Search (name contains)',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              floatingLabelStyle: TextStyle(color: AppColors.highlightColor),
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
            ),
            textInputAction: widget.onSearchSubmitted == null ? null : TextInputAction.search,
            onChanged: (val) => _filter.searchText = val.trim().isEmpty ? null : val.trim(),
            onSubmitted: widget.onSearchSubmitted == null ? null : (_) => widget.onSearchSubmitted!(),
          ),
        ),
      ),
      SliverMainAxisGroup(slivers: [
        _sectionHeader('Part Categories'),
        StreamBuilder<List<RebrickablePartCategory>>(
          stream: partsLogic.outPartCategories,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            final items = snapshot.data ?? const [];
            if (items.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(padding: EdgeInsets.all(16), child: Text('No categories')),
              );
            }
            return SliverList.builder(
              itemBuilder: (context, index) => _buildCategoryTile(items[index], index),
              itemCount: items.length,
            );
          },
        ),
      ]),
      SliverMainAxisGroup(slivers: [
        _sectionHeader('Colors'),
        StreamBuilder<List<RebrickableColor>>(
          stream: partsLogic.outColors,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            final items = snapshot.data ?? const [];
            if (items.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(padding: EdgeInsets.all(16), child: Text('No colors')),
              );
            }
            final bool tablet = context.isTablet;
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: tablet ? 240 : 180,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: tablet ? 2.2 : 2.5,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildColorTile(items[index]),
                  childCount: items.length,
                ),
              ),
            );
          },
        ),
      ]),
      const SliverToBoxAdapter(child: SizedBox(height: 120)),
    ]);
  }

  Widget _buildCategoryTile(RebrickablePartCategory data, int index) {
    final selected = _filter.categories?.any((e) => e.id == data.id) ?? false;
    return ListTile(
      // Alternating stripe so a switch is easy to match to its category row.
      tileColor: index.isEven ? null : AppColors.surface,
      // Desktop hover feedback; also lets a click anywhere on the row toggle it.
      hoverColor: AppColors.highlightColor.withValues(alpha: 0.1),
      onTap: () => _setCategory(data, !selected),
      title: Text(data.name),
      trailing: Switch(
        value: selected,
        onChanged: (val) => _setCategory(data, val),
      ),
    );
  }

  void _setCategory(RebrickablePartCategory data, bool selected) {
    setState(() {
      if (selected) {
        _filter.addCategory(data);
      } else {
        _filter.removeCategory(data.id);
      }
    });
  }

  Widget _buildColorTile(RebrickableColor color) {
    final selected = _filter.hasColor(color.id);
    final swatch = HexColor.fromHex('#${color.rgb}');
    final isDark = swatch.computeLuminance() < 0.45;
    final double scale = context.colorChipScale;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _filter.removeColor(color.id);
          } else {
            _filter.addColor(color);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: swatch,
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? Border.all(color: AppColors.highlightColor, width: 3)
              : Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
        child: Row(
          children: [
            if (selected)
              Icon(Icons.check_circle, size: 16 * scale, color: isDark ? Colors.white : Colors.black87),
            if (selected) SizedBox(width: 6 * scale),
            Expanded(
              child: Text(
                color.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
