import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/list_provider.dart';
import '../models/list_item.dart';
import '../theme/app_theme.dart';
import 'agile_chip_selector.dart';

class FluidEditSheet extends StatefulWidget {
  const FluidEditSheet({Key? key}) : super(key: key);

  @override
  State<FluidEditSheet> createState() => _FluidEditSheetState();
}

class _FluidEditSheetState extends State<FluidEditSheet> {
  late TextEditingController _titleController;
  final FocusNode _titleFocus = FocusNode();

  ListItem? _draftItem;
  final List<String> _units = ['pcs', 'lbs', 'oz', 'gal', 'pk', 'box', 'bag'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();

    _titleFocus.addListener(() {
      if (_titleFocus.hasFocus) {
        context.read<ListProvider>().setFullEditRequest(true);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _syncDraftWithProvider(ListProvider provider) {
    if (provider.selectedItemIds.length == 1) {
      final selectedId = provider.selectedItemIds.first;
      if (_draftItem?.id != selectedId) {
        final realItem = provider.activeItems.firstWhere((i) => i.id == selectedId);
        _draftItem = realItem.copyWith(quantity: provider.getDraftQuantity(selectedId));
        _titleController.text = _draftItem!.title;
      }
    } else {
      _draftItem = null;
      _titleFocus.unfocus();
    }
  }

  void _saveDraft(ListProvider provider) {
    if (_draftItem != null && _titleController.text.trim().isNotEmpty) {
      provider.editItem(
        _draftItem!.id,
        _titleController.text.trim(),
        _draftItem!.attributeRows,
        _draftItem!.type,
        _draftItem!.category,
        _draftItem!.quantity,
        _draftItem!.unit,
      );
    }
    provider.clearSelection();
  }

  Widget _buildPillButton(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final fgColor = color ?? Theme.of(context).textTheme.titleMedium?.color;
    final bgColor = (color ?? Theme.of(context).dividerColor).withOpacity(0.1);

    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListProvider>();
    _syncDraftWithProvider(provider);

    final bool isVisible = provider.selectedItemIds.isNotEmpty;
    final bool isMulti = provider.selectedItemIds.length > 1;
    final bool isFull = provider.isFullEditRequested;

    final double screenHeight = MediaQuery.of(context).size.height;

    // Base structural height prevents RenderFlex crushing during dismissal
    double sheetHeight = 280.0 + MediaQuery.of(context).padding.bottom;

    if (isMulti) {
      sheetHeight = 180.0 + MediaQuery.of(context).padding.bottom;
    } else if (isFull) {
      sheetHeight = screenHeight * 0.70;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      left: 0,
      right: 0,
      bottom: isVisible ? 0 : -(sheetHeight + 50),
      height: sheetHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: Column(
          children: [
            // TOP BAR: Cancel | Drag Handle | Save
            GestureDetector(
              behavior: HitTestBehavior.opaque, // MASSIVE HITBOX for easy swiping
              onVerticalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0.0;

                if (velocity > 200) { // Swift swipe down
                  if (isFull) {
                    provider.setFullEditRequest(false);
                    _titleFocus.unfocus();
                  } else {
                    _titleFocus.unfocus();
                    provider.clearSelection();
                  }
                } else if (velocity < -200 && !isMulti) { // Swift swipe up
                  provider.setFullEditRequest(true);
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0, bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        _titleFocus.unfocus();
                        provider.clearSelection();
                      },
                      child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16)),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 50, height: 5,
                          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _saveDraft(provider),
                      child: const Text('Save', style: TextStyle(color: AppColors.primaryAction, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: isFull ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
                child: isMulti
                    ? _buildBatchView(provider)
                    : _buildSingleEditView(provider, isFull),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchView(ListProvider provider) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          decoration: BoxDecoration(color: AppColors.primaryAction.withOpacity(0.15), borderRadius: BorderRadius.circular(50.0)),
          child: Text('${provider.selectedItemIds.length} Items Selected', style: const TextStyle(color: AppColors.primaryAction, fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            _buildPillButton(Icons.checklist_rounded, 'Check All', () => provider.checkSelectedItems(), color: AppColors.successAction),
            const SizedBox(width: 12),
            _buildPillButton(Icons.copy_rounded, 'Copy', () => provider.copySelectedItems()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildPillButton(Icons.delete_outline_rounded, 'Delete Selected', () => provider.deleteSelectedItems(), color: AppColors.destructiveAction),
          ],
        ),
      ],
    );
  }

  Widget _buildSingleEditView(ListProvider provider, bool isFull) {
    if (_draftItem == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _titleController,
          focusNode: _titleFocus,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Item Name',
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: AppColors.primaryAction, width: 2.0)),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.0)),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() => _draftItem = _draftItem!.copyWith(quantity: (_draftItem!.quantity - 1).clamp(1, 99)))),
                  SizedBox(width: 24, child: Text('${_draftItem!.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _draftItem = _draftItem!.copyWith(quantity: (_draftItem!.quantity + 1).clamp(1, 99)))),
                ],
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.0)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _draftItem!.unit,
                    isExpanded: true,
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                    onChanged: (val) { if (val != null) setState(() => _draftItem = _draftItem!.copyWith(unit: val)); },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (!isFull)
          Row(
            children: [
              _buildPillButton(Icons.edit_rounded, 'Edit', () {
                provider.setFullEditRequest(true);
                _titleFocus.requestFocus();
              }, color: AppColors.primaryAction),
              const SizedBox(width: 8),
              _buildPillButton(Icons.copy_rounded, 'Copy', () {
                provider.copySelectedItems();
              }),
              const SizedBox(width: 8),
              _buildPillButton(Icons.delete_outline_rounded, 'Delete', () {
                provider.deleteSelectedItems();
              }, color: AppColors.destructiveAction),
            ],
          ),

        if (isFull) ...[
          AgileChipSelector(
            title: 'Category',
            dictionary: provider.activeCategoryDictionary,
            initialSelections: _draftItem!.category != 'Everything Else' ? [_draftItem!.category] : [],
            isMultiSelect: false,
            onSelectionChanged: (vals) => setState(() => _draftItem = _draftItem!.copyWith(category: vals.isNotEmpty ? vals.first : '')),
          ),
          const SizedBox(height: 16),
          AgileChipSelector(
            title: 'Store',
            dictionary: provider.activeStoreDictionary,
            initialSelections: _draftItem!.type != 'Any' ? [_draftItem!.type] : [],
            isMultiSelect: false,
            onSelectionChanged: (vals) => setState(() => _draftItem = _draftItem!.copyWith(type: vals.isNotEmpty ? vals.first : '')),
          ),
          const SizedBox(height: 16),
          AgileChipSelector(
            title: 'Tags',
            dictionary: provider.activeTagDictionary,
            initialSelections: _draftItem!.attributeRows,
            isMultiSelect: true,
            onSelectionChanged: (vals) => setState(() => _draftItem = _draftItem!.copyWith(attributeRows: vals)),
          ),
        ]
      ],
    );
  }
}