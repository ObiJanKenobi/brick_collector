import 'dart:async';

import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/filter_preset.dart';
import 'package:brick_collector/ui/nav_menu.dart';
import 'package:brick_lib/model/rebrickable_color.dart';
import 'package:brick_lib/model/rebrickable_part_category.dart';

class PartsFilterScreen extends StatefulWidget {
  const PartsFilterScreen(this.presetId, {super.key});

  final String presetId;

  @override
  State<StatefulWidget> createState() => PartsFilterScreenState();
}

class PartsFilterScreenState extends State<PartsFilterScreen> {
  FilterPreset? _preset;
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<List<FilterPreset>>? _presetsSub;

  @override
  void initState() {
    super.initState();
    _resolvePreset(partsLogic.presets);
    _presetsSub = partsLogic.outPresets.listen(_resolvePreset);
  }

  void _resolvePreset(List<FilterPreset> presets) {
    if (_preset != null) return; // first emission to land wins; don't replace mid-edit
    final found = presets.cast<FilterPreset?>().firstWhere(
          (p) => p!.firestoreId == widget.presetId,
          orElse: () => null,
        );
    if (found == null) return;
    _searchController.text = found.searchText ?? '';
    setState(() => _preset = found);
  }

  @override
  void dispose() {
    _presetsSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Widget _sectionHeader(String title) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: AppColors.surface,
      title: Text(title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preset = _preset;
    if (preset == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      drawer: const Drawer(child: NavMenu()),
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.bg,
          title: Text(preset.name),
        ),
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
              onChanged: (val) => preset.searchText = val.trim().isEmpty ? null : val.trim(),
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
                itemBuilder: (context, index) => _buildCategoryTile(preset, items[index], index),
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
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 2.5,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildColorTile(preset, items[index]),
                    childCount: items.length,
                  ),
                ),
              );
            },
          ),
        ]),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ]),
      extendBody: true,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            IconButton(onPressed: _saveAndView, icon: const Icon(Icons.save), tooltip: 'Save'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(FilterPreset preset, RebrickablePartCategory data, int index) {
    final selected = preset.categories?.any((e) => e.id == data.id) ?? false;
    return ListTile(
      // Alternating stripe so a switch is easy to match to its category row.
      tileColor: index.isEven ? null : AppColors.surface,
      // Desktop hover feedback; also lets a click anywhere on the row toggle it.
      hoverColor: AppColors.highlightColor.withValues(alpha: 0.1),
      onTap: () => _setCategory(preset, data, !selected),
      title: Text(data.name),
      trailing: Switch(
        value: selected,
        onChanged: (val) => _setCategory(preset, data, val),
      ),
    );
  }

  void _setCategory(FilterPreset preset, RebrickablePartCategory data, bool selected) {
    setState(() {
      if (selected) {
        preset.addCategory(data);
      } else {
        preset.removeCategory(data.id);
      }
    });
  }

  Widget _buildColorTile(FilterPreset preset, RebrickableColor color) {
    final selected = preset.hasColor(color.id);
    final swatch = HexColor.fromHex('#${color.rgb}');
    final isDark = swatch.computeLuminance() < 0.45;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            preset.removeColor(color.id);
          } else {
            preset.addColor(color);
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            if (selected)
              Icon(Icons.check_circle, size: 16, color: isDark ? Colors.white : Colors.black87),
            if (selected) const SizedBox(width: 6),
            Expanded(
              child: Text(
                color.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
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

  Future<void> _saveAndView() async {
    final preset = _preset;
    if (preset == null) return;
    await partsLogic.savePreset(preset);
    if (!mounted) return;
    context.go(ScreenPaths.presetPage(preset.firestoreId!));
  }
}
