import 'dart:async';

import 'package:brick_collector/common_libs.dart';
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
  /// A copy from [PartsLogic.getPresetById]: edits stay local until Save, so
  /// backing out discards them.
  FilterPreset? _preset;
  StreamSubscription<List<FilterPreset>>? _presetsSub;

  @override
  void initState() {
    super.initState();
    // Resolved now so the editor shows on the first frame; the listener covers
    // a preset that only arrives later (e.g. one created a moment ago).
    _preset = partsLogic.getPresetById(widget.presetId);
    _presetsSub = partsLogic.outPresets.listen((_) => _resolvePreset());
  }

  void _resolvePreset() {
    if (_preset != null) return; // first emission to land wins; don't replace mid-edit
    final found = partsLogic.getPresetById(widget.presetId);
    if (found == null || !mounted) return;
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
      // App bar and drawer so this is never a dead end, e.g. if the preset's
      // creation was rejected by the server and it never shows up.
      return Scaffold(
        appBar: AppBar(title: const Text('Edit filter')),
        drawer: const Drawer(child: NavMenu()),
        body: const Center(child: CircularProgressIndicator()),
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
    context.go(ScreenPaths.presetPage(partsLogic.savePreset(preset)));
  }
}
