import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/ui/StripedContainer.dart';

/// Bottom sheet for changing how many of a part/colour are *needed*
/// (`part.quantity`). Mirrors [CollectModal], but edits the target count rather
/// than the collected count. Pops `true` when the quantity was saved.
class EditQuantityModal extends StatefulWidget {
  final CollectablePart part;

  const EditQuantityModal(this.part, {super.key});

  @override
  State<StatefulWidget> createState() => EditQuantityModalState();
}

class EditQuantityModalState extends State<EditQuantityModal> {
  CollectablePart get part => widget.part;

  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  int _count = 0;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _count = part.quantity;
    _syncInput();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _grabber(),
              const SizedBox(height: 12),
              _header(),
              const SizedBox(height: 18),
              _counter(),
              const SizedBox(height: 10),
              _collectedHint(),
              const SizedBox(height: 18),
              _saveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grabber() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _header() {
    final bool anyColor = part.color == "9999" || part.colorName == "No Color/Any Color";
    final Color swatchColor = anyColor || part.rgb == null ? AppColors.surfaceLight : HexColor.fromHex(part.rgb!);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: swatchColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: anyColor
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: const DiagonalStripePatternView(),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                part.name ?? part.part ?? 'Part',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Needed · ${part.colorName ?? '—'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _counter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepperButton(
          icon: Icons.remove,
          enabled: _count > 0,
          onTap: _decrease,
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 110,
          child: _editing
              ? TextField(
                  controller: _inputController,
                  focusNode: _inputFocus,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.0,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                  onChanged: _onTyped,
                  onSubmitted: (_) => _stopEditing(),
                  onTapOutside: (_) => _stopEditing(),
                )
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _startEditing,
                  child: Center(
                    child: Text(
                      '$_count',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 18),
        _stepperButton(
          icon: Icons.add,
          enabled: true,
          onTap: _increase,
        ),
      ],
    );
  }

  Widget _collectedHint() {
    if (part.collectedCount <= _count) return const SizedBox.shrink();
    return Text(
      'Collected count will drop to $_count',
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 12, color: AppColors.highlightColor),
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: enabled
          ? AppColors.highlightColor.withValues(alpha: 0.15)
          : AppColors.surfaceLight,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Icon(
            icon,
            size: 32,
            color: enabled ? AppColors.highlightColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _saveButton() {
    final unchanged = _count == part.quantity;
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.highlightColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.surfaceLight,
        disabledForegroundColor: AppColors.textSecondary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      onPressed: unchanged ? null : _save,
      child: Text(unchanged ? 'No changes' : 'Save'),
    );
  }

  void _startEditing() {
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputController.selection = TextSelection(baseOffset: 0, extentOffset: _inputController.text.length);
    });
  }

  void _stopEditing() {
    if (!_editing) return;
    final parsed = int.tryParse(_inputController.text);
    final clamped = parsed == null ? _count : (parsed < 0 ? 0 : parsed);
    setState(() {
      _count = clamped;
      _editing = false;
      _syncInput();
    });
  }

  void _onTyped(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) return;
    setState(() => _count = parsed < 0 ? 0 : parsed);
  }

  void _decrease() {
    if (_count <= 0) return;
    setState(() {
      _count -= 1;
      _syncInput();
    });
  }

  void _increase() {
    setState(() {
      _count += 1;
      _syncInput();
    });
  }

  void _save() {
    part.quantity = _count;
    // Never leave more collected than needed.
    if (part.collectedCount > _count) {
      part.collectedCount = _count;
    }
    Navigator.of(context).pop(true);
  }

  void _syncInput() {
    _inputController.text = '$_count';
  }
}
