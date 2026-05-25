import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/list_provider.dart';
import '../models/list_item.dart';
import '../theme/app_theme.dart';
import 'horizontal_pill_selector.dart';

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
      if (_titleFocus.hasFocus && mounted) {
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

  // FIXED: Safely sync data before the build phase to prevent UI freezing!
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<ListProvider>();
    _syncDraftWithProvider(provider);
  }

  void _syncDraftWithProvider(ListProvider provider) {
    if (provider.editItemId != null) {
      final itemIndex = provider.displayList.indexWhere((item) => item is ListItem && item.id == provider.editItemId);
      if (itemIndex != -1) {
        final item = provider.displayList[itemIndex] as ListItem;
        // Only override the draft if it's a completely new item selection
        if (_draftItem == null || _draftItem!.id != item.id) {
          _draftItem = item.copyWith();
          _titleController.text = item.title;
        }
      }
    } else if (_draftItem != null) {
      _draftItem = null;
      _titleController.clear();
    }
  }

  // NEW: Dedicated save function for the separated architecture
  void _saveDraft(ListProvider provider) {
    if (_draftItem != null) {
      provider.editItem(
        _draftItem!.id,
        _titleController.text.trim(),
        _draftItem!.attributeRows,
        _draftItem!.type,
        _draftItem!.category,
        _draftItem!.quantity, // Use the local draft quantity
        _draftItem!.unit,
      );
    }
    // Close the sheet gracefully
    provider.setEditItem(null);
    provider.setFullEditRequest(false);
    _titleFocus.unfocus();
  }

  // HELPER: To render the action buttons efficiently
  Widget _buildPillButton(IconData icon, String label, VoidCallback onTap, {Color color = AppColors.primaryAction}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListProvider>();
    final isVisible = provider.editItemId != null;
    final bool isFull = provider.isFullEditRequested;

    final double screenHeight = MediaQuery.of(context).size.height;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double safeBottom = MediaQuery.of(context).padding.bottom;

    double sheetHeight = 280.0 + safeBottom;
    if (isFull) {
      sheetHeight = screenHeight * 0.85;
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
            // TOP BAR: Anchored permanently to the top of the container
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0.0;
                if (velocity > 200) {
                  if (isFull) {
                    provider.setFullEditRequest(false);
                    _titleFocus.unfocus();
                  } else {
                    _titleFocus.unfocus();
                    provider.setEditItem(null); // Safely close sheet
                  }
                } else if (velocity < -200) {
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
                        provider.setEditItem(null); // Cancel closes sheet natively
                        provider.setFullEditRequest(false);
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
                      onPressed: () => _saveDraft(provider), // Triggers specific save execution
                      child: const Text('Save', style: TextStyle(color: AppColors.primaryAction, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              // SHIELD: Stops inner scrolls from bubbling to the background list
              child: NotificationListener<ScrollNotification>(
                onNotification: (_) => true,
                child: SingleChildScrollView(
                  physics: isFull ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  // DYNAMIC PADDING: Pushes contents up above the keyboard natively
                  padding: EdgeInsets.only(left: 20.0, right: 20.0, bottom: keyboardHeight + 20.0),
                  child: _buildSingleEditView(provider, isFull),
                ),
              ),
            ),
          ],
        ),
      ),
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
                  // FIXED: Updates quantity locally on the draft before hitting save
                  IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() => _draftItem = _draftItem!.copyWith(quantity: (_draftItem!.quantity - 1).clamp(0, 99)))),
                  SizedBox(width: 24, child: Text('${_draftItem!.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _draftItem = _draftItem!.copyWith(quantity: (_draftItem!.quantity + 1).clamp(0, 99)))),
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

              // FIXED: Local copy override for separated state
              _buildPillButton(Icons.copy_rounded, 'Copy', () {
                provider.addItem(
                  '${_draftItem!.title} (Copy)', _draftItem!.attributeRows, _draftItem!.type, _draftItem!.category, _draftItem!.quantity, _draftItem!.unit,
                );
                provider.setEditItem(null);
              }),
              const SizedBox(width: 8),

              // FIXED: Local delete override for separated state
              _buildPillButton(Icons.delete_outline_rounded, 'Delete', () {
                final id = provider.deleteItem(_draftItem!.id);
                provider.setEditItem(null);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Item deleted'), behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(label: 'Undo', textColor: AppColors.primaryAction, onPressed: () => provider.restoreItems([id])),
                ));
              }, color: AppColors.destructiveAction),
            ],
          ),

        if (isFull) ...[
          const Divider(height: 32.0, thickness: 1.0),

          HorizontalPillSelector(
            title: 'Category',
            dictionary: provider.activeCategoryDictionary,
            selectedItems: _draftItem!.category != 'Everything Else' ? [_draftItem!.category] : [],
            isMultiSelect: false,
            onSelectionChanged: (vals) => setState(() => _draftItem = _draftItem!.copyWith(category: vals.isNotEmpty ? vals.first : '')),
          ),

          const Divider(height: 32.0, thickness: 1.0),

          HorizontalPillSelector(
            title: 'Store',
            dictionary: provider.activeStoreDictionary,
            selectedItems: _draftItem!.type != 'Any' ? [_draftItem!.type] : [],
            isMultiSelect: false,
            onSelectionChanged: (vals) => setState(() => _draftItem = _draftItem!.copyWith(type: vals.isNotEmpty ? vals.first : '')),
          ),

          const Divider(height: 32.0, thickness: 1.0),

          HorizontalPillSelector(
            title: 'Tags',
            dictionary: provider.activeTagDictionary,
            selectedItems: _draftItem!.attributeRows,
            isMultiSelect: true,
            isTag: true,
            onSelectionChanged: (vals) => setState(() => _draftItem = _draftItem!.copyWith(attributeRows: vals)),
          ),
        ]
      ],
    );
  }
}