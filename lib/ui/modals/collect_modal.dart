import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/ui/StripedContainer.dart';

class CollectModal extends StatefulWidget {
  final CollectablePart part;

  const CollectModal(this.part, {super.key});

  @override
  State<StatefulWidget> createState() => CollectModalState();
}

class CollectModalState extends State<CollectModal> {
  CollectablePart get part => widget.part;

  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  int _count = 0;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _count = part.collectedCount;
    _syncInput();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  bool get _isComplete => _count >= part.quantity && part.quantity > 0;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final progress = part.quantity == 0 ? 0.0 : (_count / part.quantity).clamp(0.0, 1.0);

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
              const SizedBox(height: 16),
              _progressBar(progress),
              const SizedBox(height: 18),
              _counter(),
              const SizedBox(height: 16),
              _quickRow(),
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
                '${part.colorName ?? '—'} · ${part.part ?? ''}',
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

  Widget _progressBar(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              _isComplete ? 'Complete' : '$_count of ${part.quantity} collected',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isComplete ? Colors.greenAccent : AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            if (!_isComplete)
              Text(
                '${part.quantity - _count} left',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(
              _isComplete ? Colors.greenAccent : AppColors.highlightColor,
            ),
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
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: _isComplete ? Colors.greenAccent : AppColors.textPrimary,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 18),
        _stepperButton(
          icon: Icons.add,
          enabled: _count < part.quantity,
          onTap: _increase,
        ),
      ],
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

  Widget _quickRow() {
    return Row(
      children: [
        Expanded(
          child: _quickChip(
            label: 'Clear',
            icon: Icons.refresh,
            onTap: _count == 0 ? null : _clear,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickChip(
            label: 'Collect all',
            icon: Icons.archive_outlined,
            onTap: _isComplete ? null : _collectAll,
          ),
        ),
      ],
    );
  }

  Widget _quickChip({required String label, required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    final color = enabled ? AppColors.textPrimary : AppColors.textSecondary;
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _saveButton() {
    final unchanged = _count == part.collectedCount;
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
    final clamped = parsed == null ? _count : parsed.clamp(0, part.quantity);
    setState(() {
      _count = clamped;
      _editing = false;
      _syncInput();
    });
  }

  void _onTyped(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) return;
    setState(() => _count = parsed.clamp(0, part.quantity));
  }

  void _decrease() {
    if (_count <= 0) return;
    setState(() {
      _count -= 1;
      _syncInput();
    });
  }

  void _increase() {
    if (_count >= part.quantity) return;
    setState(() {
      _count += 1;
      _syncInput();
    });
  }

  void _clear() {
    setState(() {
      _count = 0;
      _syncInput();
    });
  }

  void _collectAll() {
    setState(() {
      _count = part.quantity;
      _syncInput();
    });
  }

  void _save() {
    part.collectedCount = _count;
    Navigator.of(context).pop(true);
  }

  void _syncInput() {
    _inputController.text = '$_count';
  }
}
