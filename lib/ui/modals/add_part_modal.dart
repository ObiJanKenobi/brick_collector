import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/collectable_part.dart';

/// Bottom sheet for manually adding a part (or extra colours of a part) to a
/// MOC. When [fixedPartId] is set the part number is locked and the sheet only
/// collects colours — used from the part detail screen to "quickly add a new
/// colour". Otherwise the user types a part number too.
///
/// Pops a `List<CollectablePart>` (one per colour) on save, or null if cancelled.
class AddPartModal extends StatefulWidget {
  final String? fixedPartId;
  final String? partName;

  /// Rebrickable colour ids ("4", "72", …) already present on the part, so the
  /// colour picker can hide them and avoid duplicates.
  final Set<String> existingColorIds;

  /// Part numbers already in the MOC. Used to block adding a duplicate part
  /// (only relevant when the user types a part number, i.e. not [fixedPartId]).
  final Set<String> existingPartIds;

  const AddPartModal({
    this.fixedPartId,
    this.partName,
    this.existingColorIds = const {},
    this.existingPartIds = const {},
    super.key,
  });

  @override
  State<AddPartModal> createState() => _AddPartModalState();
}

class _ColorEntry {
  _ColorEntry(this.color, this.qty);
  final BrickColor color;
  int qty;
  bool editing = false;
  final TextEditingController controller = TextEditingController();
}

class _AddPartModalState extends State<AddPartModal> {
  final TextEditingController _partIdController = TextEditingController();
  final List<_ColorEntry> _entries = [];
  bool _saving = false;
  String? _error;

  bool get _fixedPart => widget.fixedPartId != null;
  String get _partId => (widget.fixedPartId ?? _partIdController.text).trim();

  @override
  void dispose() {
    _partIdController.dispose();
    for (final e in _entries) {
      e.controller.dispose();
    }
    super.dispose();
  }

  Set<String> get _usedColorIds =>
      {...widget.existingColorIds, ..._entries.map((e) => e.color.rebrickableColor)};

  /// True when the typed part number is already in the MOC (duplicates blocked).
  bool get _isDuplicate => !_fixedPart && _partId.isNotEmpty && widget.existingPartIds.contains(_partId);

  bool get _canSave =>
      _partId.isNotEmpty && !_isDuplicate && _entries.isNotEmpty && _entries.every((e) => e.qty > 0);

  /// Inline message: duplicate takes precedence, then any save-time error
  /// (e.g. "part not found").
  String? get _errorText {
    if (_isDuplicate) {
      return 'Part $_partId is already in this collection. Edit it from its detail screen.';
    }
    return _error;
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
              Text(
                _fixedPart ? 'Add colour' : 'Add part',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              _partIdField(),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 14, color: Colors.redAccent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_errorText!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              _colorsSection(),
              const SizedBox(height: 18),
              _saveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grabber() => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _partIdField() {
    if (_fixedPart) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.widgets_outlined, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.partName?.isNotEmpty == true
                    ? '${widget.partName}  ·  ${widget.fixedPartId}'
                    : widget.fixedPartId!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
    return TextField(
      controller: _partIdController,
      autofocus: true,
      textInputAction: TextInputAction.done,
      onChanged: (_) => setState(() => _error = null),
      decoration: const InputDecoration(
        labelText: 'Part number',
        hintText: 'e.g. 3001',
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _colorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('Colours', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickColor,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add colour'),
            ),
          ],
        ),
        if (_entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No colours yet — tap "Add colour".',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          )
        else
          ..._entries.map(_buildEntryRow),
      ],
    );
  }

  Widget _buildEntryRow(_ColorEntry entry) {
    final swatch = _swatch(entry.color.rgb);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: swatch,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.color.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
          _qtyStepper(entry),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
            onPressed: () => setState(() {
              entry.controller.dispose();
              _entries.remove(entry);
            }),
          ),
        ],
      ),
    );
  }

  Widget _qtyStepper(_ColorEntry entry) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniButton(Icons.remove, entry.qty > 1 ? () => setState(() => entry.qty--) : null),
        SizedBox(
          width: 40,
          child: entry.editing
              ? TextField(
                  controller: entry.controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null) setState(() => entry.qty = parsed < 0 ? 0 : parsed);
                  },
                  onSubmitted: (_) => _stopEditingEntry(entry),
                  onTapOutside: (_) => _stopEditingEntry(entry),
                )
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _startEditingEntry(entry),
                  child: Text(
                    '${entry.qty}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ),
        ),
        _miniButton(Icons.add, () => setState(() => entry.qty++)),
      ],
    );
  }

  void _startEditingEntry(_ColorEntry entry) {
    entry.controller.text = '${entry.qty}';
    setState(() => entry.editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      entry.controller.selection =
          TextSelection(baseOffset: 0, extentOffset: entry.controller.text.length);
    });
  }

  void _stopEditingEntry(_ColorEntry entry) {
    if (!entry.editing) return;
    final parsed = int.tryParse(entry.controller.text);
    setState(() {
      entry.qty = (parsed == null || parsed < 1) ? 1 : parsed;
      entry.editing = false;
    });
  }

  Widget _miniButton(IconData icon, VoidCallback? onTap) {
    return Material(
      color: onTap == null ? AppColors.surfaceLight : AppColors.highlightColor.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 18, color: onTap == null ? AppColors.textSecondary : AppColors.highlightColor),
        ),
      ),
    );
  }

  Widget _saveButton() {
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
      onPressed: (_canSave && !_saving) ? _save : null,
      child: _saving
          ? const SizedBox(
              height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(_fixedPart ? 'Add colours' : 'Add part'),
    );
  }

  Future<void> _pickColor() async {
    final color = await showModalBottomSheet<BrickColor>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ColorPickerSheet(excludeColorIds: _usedColorIds),
    );
    if (color == null) return;
    setState(() => _entries.add(_ColorEntry(color, 1)));
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final partId = _partId;

    // Enrich with the part name + image, and for a typed part number this
    // doubles as existence validation — an unknown part returns null and is
    // rejected. Skipped when the part is already known (adding a colour).
    String? name = widget.partName;
    RebrickablePart? detail;
    if (name == null || name.isEmpty) {
      detail = await rbService.getPartDetail(partId);
      if (!mounted) return;
      if (detail == null) {
        setState(() {
          _saving = false;
          _error = 'Part "$partId" not found on Rebrickable. Check the number.';
        });
        return;
      }
      name = detail.name;
    }

    final goBrickPart = brickConverterLogic.legoToGoBricksMap[partId] ?? '';
    final parts = _entries.map((e) {
      final c = e.color;
      return CollectablePart(
        part: partId,
        color: c.rebrickableColor,
        quantity: e.qty,
        colorName: c.name,
        gobricksColor: c.legoColor,
        bricklinkColor: c.bricklinkColor,
        rgb: c.rgb,
        goBrickPart: goBrickPart,
        name: name ?? '',
        details: detail,
      );
    }).toList();

    if (!mounted) return;
    Navigator.of(context).pop(parts);
  }

  static Color _swatch(String rgb) {
    if (rgb.isEmpty) return AppColors.surfaceLight;
    try {
      return HexColor.fromHex(rgb);
    } catch (_) {
      return AppColors.surfaceLight;
    }
  }
}

/// Searchable colour list, returns the picked [BrickColor].
class _ColorPickerSheet extends StatefulWidget {
  final Set<String> excludeColorIds;
  const _ColorPickerSheet({required this.excludeColorIds});

  @override
  State<_ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<_ColorPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final q = _query.trim().toLowerCase();
    final colors = brickConverterLogic.colors
        .where((c) => !widget.excludeColorIds.contains(c.rebrickableColor))
        .where((c) => q.isEmpty || c.name.toLowerCase().contains(q) || c.rebrickableColor.contains(q))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search colour…',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: colors.isEmpty
                  ? const Center(child: Text('No colours', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: colors.length,
                      itemBuilder: (context, i) {
                        final c = colors[i];
                        return ListTile(
                          dense: true,
                          leading: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _AddPartModalState._swatch(c.rgb),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                          ),
                          title: Text(c.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                          subtitle: Text('ID ${c.rebrickableColor}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          onTap: () => Navigator.of(context).pop(c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
