import 'dart:async';

import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/ui/preset_save.dart';
import 'package:brick_collector/model/filter_preset.dart';
import 'package:brick_collector/ui/filter_editor.dart';
import 'package:brick_collector/ui/nav_menu.dart';

class PartsFilterScreen extends StatefulWidget {
  const PartsFilterScreen(this.presetId, {super.key});

  final String presetId;

  @override
  State<StatefulWidget> createState() => PartsFilterScreenState();
}

class PartsFilterScreenState extends State<PartsFilterScreen> {
  FilterPreset? _preset;
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
    setState(() => _preset = found);
  }

  @override
  void dispose() {
    _presetsSub?.cancel();
    super.dispose();
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
      body: FilterEditor(
        filter: preset,
        appBar: SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.bg,
          title: Text(preset.name),
        ),
      ),
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

  void _saveAndView() {
    final preset = _preset;
    if (preset == null) return;
    savePresetInBackground(context, preset);
    context.go(ScreenPaths.presetPage(preset.firestoreId!));
  }
}
