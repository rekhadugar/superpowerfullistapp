import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/list_item.dart';
import '../providers/list_provider.dart';

import '../theme/app_theme.dart';
import 'horizontal_pill_selector.dart';

class EditItemBottomSheet extends StatefulWidget {
  final ListItem? item;
  final Function(String title, List<String> attributes, String type, String category, int quantity, String unit) onSave;

  const EditItemBottomSheet({
    Key? key,
    this.item,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditItemBottomSheet> createState() => _EditItemBottomSheetState();
}

class _EditItemBottomSheetState extends State<EditItemBottomSheet> {
  late TextEditingController _titleController;
  late int _quantity;
  late String _unit;
  late String _selectedCategory;
  late String _selectedStore;
  late List<String> _selectedTags;

  final List<String> _units = ['pcs', 'lbs', 'oz', 'gal', 'pk', 'box', 'bag'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _quantity = widget.item?.quantity ?? 1;
    _unit = _units.contains(widget.item?.unit) ? (widget.item?.unit ?? 'pcs') : 'pcs';

    _selectedCategory = widget.item?.category.isNotEmpty == true && widget.item!.category != 'Everything Else' ? widget.item!.category : '';
    _selectedStore = widget.item?.type.isNotEmpty == true && widget.item!.type != 'Any' ? widget.item!.type : '';
    _selectedTags = List.from(widget.item?.attributeRows ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fetch dynamic dictionaries from provider
    final provider = context.read<ListProvider>();
    final categoriesDict = provider.activeCategoryDictionary;
    final storesDict = provider.activeStoreDictionary;
    final tagsDict = provider.activeTagDictionary;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0, // Reactive padding for keyboard
        top: 16.0,
        left: 20.0,
        right: 20.0,
      ),
      child: SingleChildScrollView(
        // Swipe down to dismiss keyboard natively
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24.0),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2.0)),
              ),
            ),

            TextField(
              controller: _titleController,
              autofocus: widget.item?.id.isEmpty ?? true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Item Name',
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: AppColors.primaryAction, width: 1.5)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: AppColors.primaryAction.withOpacity(0.5), width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: AppColors.primaryAction, width: 2.0)),
              ),
            ),
            const SizedBox(height: 16.0),

            Row(
              children: [
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: Colors.grey.shade300)),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() => _quantity = (_quantity - 1).clamp(1, 99))),
                      SizedBox(width: 24, child: Text('$_quantity', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _quantity = (_quantity + 1).clamp(1, 99))),
                    ],
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: Colors.grey.shade300)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _unit,
                        isExpanded: true,
                        items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                        onChanged: (val) { if (val != null) setState(() => _unit = val); },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // NEW: Added Dividers and updated to HorizontalPillSelector
            const Divider(height: 32.0, thickness: 1.0),

            HorizontalPillSelector(
              title: 'Category',
              dictionary: categoriesDict,
              selectedItems: _selectedCategory.isNotEmpty ? [_selectedCategory] : [],
              isMultiSelect: false,
              onSelectionChanged: (vals) => setState(() => _selectedCategory = vals.isNotEmpty ? vals.first : ''),
            ),

            const Divider(height: 32.0, thickness: 1.0),

            HorizontalPillSelector(
              title: 'Store',
              dictionary: storesDict,
              selectedItems: _selectedStore.isNotEmpty ? [_selectedStore] : [],
              isMultiSelect: false,
              onSelectionChanged: (vals) => setState(() => _selectedStore = vals.isNotEmpty ? vals.first : ''),
            ),

            const Divider(height: 32.0, thickness: 1.0),

            HorizontalPillSelector(
              title: 'Tags',
              dictionary: tagsDict,
              selectedItems: _selectedTags,
              isMultiSelect: true,
              isTag: true, // NEW: Triggers the compact, boundary-highlighted style
              onSelectionChanged: (vals) => setState(() => _selectedTags = vals),
            ),
            const SizedBox(height: 24.0),

            ElevatedButton(
              onPressed: () {
                if (_titleController.text.trim().isEmpty) return;
                widget.onSave(
                  _titleController.text.trim(),
                  _selectedTags,
                  _selectedStore,
                  _selectedCategory,
                  _quantity,
                  _unit,
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAction,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
              child: const Text('Save Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}