import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/ui/StripedContainer.dart';

/// One selectable colour in the MOC, with how many parts use it.
class ColorFilterOption {
  ColorFilterOption({required this.id, required this.name, required this.rgb, this.count = 0});
  final String id;
  final String name;
  final String rgb;
  int count;

  bool get isAnyColor => id == '9999' || name == 'No Color/Any Color';
}

/// The full set of MOC list filters the modal edits.
class MocFilterResult {
  MocFilterResult({required this.colors, required this.hideCompleted, required this.missingOnly});
  final Set<String> colors;
  final bool hideCompleted;
  final bool missingOnly;
}

/// Bottom sheet to filter the MOC part list: by colour, by completion, and by
/// whether the part is still missing from the synced inventory. Pops a
/// [MocFilterResult] on "Apply", or null if dismissed.
class MocFilterModal extends StatefulWidget {
  final List<ColorFilterOption> options;
  final Set<String> selectedColors;
  final bool hideCompleted;
  final bool missingOnly;

  const MocFilterModal({
    required this.options,
    required this.selectedColors,
    required this.hideCompleted,
    required this.missingOnly,
    super.key,
  });

  @override
  State<MocFilterModal> createState() => _MocFilterModalState();
}

class _MocFilterModalState extends State<MocFilterModal> {
  late final Set<String> _selected = {...widget.selectedColors};
  late bool _hideCompleted = widget.hideCompleted;
  late bool _missingOnly = widget.missingOnly;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Filter',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ),
                  TextButton(
                    onPressed: _hasAnyFilter ? _clearAll : null,
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  SwitchListTile(
                    value: _hideCompleted,
                    onChanged: (v) => setState(() => _hideCompleted = v),
                    activeColor: AppColors.highlightColor,
                    dense: true,
                    secondary: const Icon(Icons.check_circle_outline, color: AppColors.textSecondary),
                    title: const Text('Hide completed', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    subtitle: const Text('Only show parts you still need',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ),
                  SwitchListTile(
                    value: _missingOnly,
                    onChanged: (v) => setState(() => _missingOnly = v),
                    activeColor: AppColors.highlightColor,
                    dense: true,
                    secondary: const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary),
                    title: const Text('Missing from inventory only',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    subtitle: const Text('Hide parts your synced inventory can cover',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ),
                  const Divider(height: 8),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('Colours',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        ),
                        TextButton(
                          onPressed: _selected.isEmpty ? null : () => setState(_selected.clear),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                  if (widget.options.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No colours', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  else
                    ...widget.options.map(_buildColorRow),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.highlightColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => Navigator.of(context).pop(MocFilterResult(
                    colors: _selected,
                    hideCompleted: _hideCompleted,
                    missingOnly: _missingOnly,
                  )),
                  child: const Text('Apply'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasAnyFilter => _selected.isNotEmpty || _hideCompleted || _missingOnly;

  void _clearAll() => setState(() {
        _selected.clear();
        _hideCompleted = false;
        _missingOnly = false;
      });

  Widget _buildColorRow(ColorFilterOption option) {
    final checked = _selected.contains(option.id);
    return CheckboxListTile(
      value: checked,
      onChanged: (v) => setState(() {
        if (v == true) {
          _selected.add(option.id);
        } else {
          _selected.remove(option.id);
        }
      }),
      activeColor: AppColors.highlightColor,
      controlAffinity: ListTileControlAffinity.trailing,
      dense: true,
      secondary: _swatch(option),
      title: Text(option.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      subtitle: Text('${option.count} part${option.count == 1 ? "" : "s"}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
    );
  }

  Widget _swatch(ColorFilterOption option) {
    Widget inner;
    if (option.isAnyColor) {
      inner = const DiagonalStripePatternView();
    } else {
      Color c = AppColors.surfaceLight;
      if (option.rgb.isNotEmpty) {
        try {
          c = HexColor.fromHex(option.rgb);
        } catch (_) {}
      }
      inner = ColoredBox(color: c);
    }
    return Container(
      width: 28,
      height: 28,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: inner,
    );
  }
}
