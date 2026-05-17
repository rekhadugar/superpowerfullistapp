import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Required for ScrollDirection
import 'package:provider/provider.dart';
import '../models/list_item.dart';
import '../services/list_provider.dart';
import '../theme/app_theme.dart';
import 'token_search_engine.dart';

class ItemFormModal extends StatefulWidget {
  final String activeListType;
  final ListItem? existingItem;

  const ItemFormModal({
    required this.activeListType,
    this.existingItem,
    super.key,
  });

  @override
  State<ItemFormModal> createState() => _ItemFormModalState();
}

class _ItemFormModalState extends State<ItemFormModal> {
  final TextEditingController _nameController = TextEditingController();

  late String _selectedType;
  late String _selectedCategory;
  late List<String> _selectedLocations;
  late List<String> _selectedTags;

  int _quantity = 1;
  String _unit = 'pcs';
  final List<String> _unitOptions = ['pcs', 'lbs', 'kg', 'oz', 'gal', 'pk', 'box'];

  String? _activeEngine;
  bool _isNameValid = false;

  @override
  void initState() {
    super.initState();

    _nameController.addListener(() {
      final isValid = _nameController.text.trim().isNotEmpty;
      if (_isNameValid != isValid) {
        setState(() => _isNameValid = isValid);
      }
    });

    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _nameController.text = item.name;
      _selectedType = item.type;
      _selectedCategory = item.category;
      _selectedLocations = List.from(item.locations);

      _selectedTags = item.context.isNotEmpty
          ? item.context.split(',').map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList()
          : [];

      _quantity = item.quantity;
      _unit = 'pcs';
      _isNameValid = true;
    }
    else {
      _selectedType = widget.activeListType == 'All Items' ? 'Groceries' : widget.activeListType;
      _selectedCategory = 'Uncategorized';
      _selectedLocations = ['Anywhere'];
      _selectedTags = [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleEngineToggle(String engineName, bool isOpen) {
    setState(() {
      _activeEngine = isOpen ? engineName : null;
    });

    if (!isOpen) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) return;

    final provider = context.read<ListProvider>();

    if (widget.existingItem != null) {
      provider.updateItem(
        id: widget.existingItem!.id,
        name: _nameController.text.trim(),
        type: _selectedType,
        category: _selectedCategory,
        locations: _selectedLocations,
        contextString: _selectedTags.join(', '),
        quantity: _quantity,
        unit: _unit,
      );
    } else {
      provider.addItem(
        name: _nameController.text.trim(),
        type: _selectedType,
        category: _selectedCategory,
        locations: _selectedLocations,
        context: _selectedTags.join(', '),
        quantity: _quantity,
        unit: _unit,
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditMode = widget.existingItem != null;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
        bottom: bottomInset > 0 ? bottomInset + 16 : 32,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditMode ? 'Edit Item' : 'Add New Item',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: NotificationListener<UserScrollNotification>(
              onNotification: (UserScrollNotification notification) {
                if (_activeEngine != null) {
                  // NATIVE UX FIX: Only dismiss the keyboard when pulling DOWN (reverse).
                  // Pushing UP (forward) keeps the keyboard open so the user can scroll
                  // into the runway and reach lower elements without the UI glitching.
                  if (notification.direction == ScrollDirection.reverse) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() => _activeEngine = null);
                  }
                }
                return false;
              },
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      autofocus: !isEditMode,
                      textInputAction: TextInputAction.next,
                      onTap: () {
                        if (_activeEngine != null) {
                          setState(() => _activeEngine = null);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'e.g., Paper Towels',
                        filled: true,
                        fillColor: AppTheme.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Container(
                          height: 48,
                          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1),
                              ),
                              SizedBox(
                                width: 30,
                                child: Text('$_quantity', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => setState(() => _quantity++),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _unit,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
                                items: _unitOptions.map((String unit) {
                                  return DropdownMenuItem<String>(
                                    value: unit,
                                    child: Text(unit, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) setState(() => _unit = newValue);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    TokenSearchEngine(
                      title: 'Category',
                      subtitle: 'Produce, Dairy...',
                      isMultiSelect: false,
                      knownTokens: const ['Produce', 'Dairy', 'Bakery', 'Pantry', 'Frozen', 'Tools', 'Fasteners', 'Kids'],
                      initialSelected: _selectedCategory != 'Uncategorized' ? [_selectedCategory] : [],
                      onChanged: (tokens) => setState(() => _selectedCategory = tokens.isNotEmpty ? tokens.first : 'Uncategorized'),
                      isExpanded: _activeEngine == 'Category',
                      onToggle: (isOpen) => _handleEngineToggle('Category', isOpen),
                    ),
                    const SizedBox(height: 16),

                    TokenSearchEngine(
                      title: 'Stores',
                      subtitle: 'Costco, Target...',
                      isMultiSelect: true,
                      knownTokens: const ['Costco', 'Tonys', 'Woodmans', 'Target', 'Home Depot', 'Walgreens'],
                      initialSelected: _selectedLocations.where((loc) => loc != 'Anywhere').toList(),
                      onChanged: (tokens) => setState(() => _selectedLocations = tokens.isNotEmpty ? tokens : ['Anywhere']),
                      isExpanded: _activeEngine == 'Stores',
                      onToggle: (isOpen) => _handleEngineToggle('Stores', isOpen),
                    ),
                    const SizedBox(height: 16),

                    TokenSearchEngine(
                      title: 'Tags',
                      subtitle: 'vegan, urgent...',
                      isMultiSelect: true, forceLowercase: true, smallPills: true,
                      knownTokens: const ['vegan', 'urgent', 'bulk', 'low sodium', 'sale'],
                      initialSelected: _selectedTags,
                      onChanged: (tokens) => setState(() => _selectedTags = tokens),
                      isExpanded: _activeEngine == 'Tags',
                      onToggle: (isOpen) => _handleEngineToggle('Tags', isOpen),
                    ),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      height: _activeEngine != null ? 300 : 24,
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_activeEngine == null)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.textSecondary.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isNameValid ? _submit : null,
                child: Text(
                    isEditMode ? 'Update Item' : 'Save Item',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _isNameValid ? AppTheme.surface : AppTheme.textSecondary,
                    )
                ),
              ),
            ),
        ],
      ),
    );
  }
}