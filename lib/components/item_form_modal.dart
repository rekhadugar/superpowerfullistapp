import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../models/list_item.dart';
import '../services/list_provider.dart';
import '../theme/app_constants.dart';
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
  bool _showValidationErrors = false;
  bool _isHandlingScrollCollapse = false;

  @override
  void initState() {
    super.initState();

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
    }
    else {
      _selectedType = widget.activeListType == 'All Items' ? 'Groceries' : widget.activeListType;
      _selectedCategory = '';
      _selectedLocations = [];
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
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _showValidationErrors = true);
      return;
    }

    final provider = context.read<ListProvider>();

    if (widget.existingItem != null) {
      provider.updateItem(
        id: widget.existingItem!.id,
        name: name,
        type: _selectedType,
        category: _selectedCategory.isEmpty ? 'Uncategorized' : _selectedCategory,
        locations: _selectedLocations.isEmpty ? ['Anywhere'] : _selectedLocations,
        contextString: _selectedTags.join(', '),
        quantity: _quantity,
        unit: _unit,
      );
    } else {
      provider.addItem(
        name: name,
        type: _selectedType,
        category: _selectedCategory.isEmpty ? 'Uncategorized' : _selectedCategory,
        locations: _selectedLocations.isEmpty ? ['Anywhere'] : _selectedLocations,
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

    final hasNameError = _showValidationErrors && _nameController.text.trim().isEmpty;
    final showListSelector = widget.activeListType == 'All Items' || isEditMode;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: EdgeInsets.only(
        left: 20, right: 20,
        top: 12, // Adjusted to accommodate the handle
        bottom: bottomInset > 0 ? bottomInset + 16 : 32,
      ),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: AppConstants.modalRadius, // Parameterized
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NEW: The visual drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Expanded(
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                // Manually catch swipes to dismiss without triggering scroll layout math
                if (_activeEngine != null) {
                  if (details.primaryDelta != null && details.primaryDelta!.abs() > 2) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() {
                      _activeEngine = null;
                      _isHandlingScrollCollapse = false;
                    });
                  }
                }
              },
              child: SingleChildScrollView(
                // Lock the scroll when an engine is focused to prevent layout thrashing
                physics: _activeEngine != null
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    TextField(
                      controller: _nameController,
                      autofocus: !isEditMode,
                      textInputAction: TextInputAction.next,
                      textAlign: TextAlign.left,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
                      onChanged: (_) {
                        if (hasNameError) setState(() {});
                      },
                      onTap: () {
                        if (_activeEngine != null) {
                          setState(() => _activeEngine = null);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: hasNameError ? 'Item Name is required' : 'Item Name',
                        hintStyle: TextStyle(color: hasNameError ? Colors.red.shade400 : Colors.black45),
                        filled: true,
                        fillColor: AppTheme.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: hasNameError
                              ? const BorderSide(color: Colors.red, width: 1.5)
                              : BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: hasNameError
                              ? const BorderSide(color: Colors.red, width: 1.5)
                              : const BorderSide(color: AppTheme.primary, width: 1.5),
                        ),
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
                      emptyPlaceholder: 'None',
                      isMultiSelect: false,
                      knownTokens: const ['Produce', 'Dairy', 'Bakery', 'Pantry', 'Frozen', 'Tools', 'Fasteners', 'Kids'],
                      initialSelected: _selectedCategory.isNotEmpty ? [_selectedCategory] : [],
                      onChanged: (tokens) => setState(() => _selectedCategory = tokens.isNotEmpty ? tokens.first : ''),
                      isExpanded: _activeEngine == 'Category',
                      onToggle: (isOpen) => _handleEngineToggle('Category', isOpen),
                    ),
                    const SizedBox(height: 16),

                    TokenSearchEngine(
                      title: 'Stores',
                      emptyPlaceholder: 'Any',
                      isMultiSelect: true,
                      knownTokens: const ['Costco', 'Tonys', 'Woodmans', 'Target', 'Home Depot', 'Walgreens'],
                      initialSelected: _selectedLocations,
                      onChanged: (tokens) => setState(() => _selectedLocations = tokens),
                      isExpanded: _activeEngine == 'Stores',
                      onToggle: (isOpen) => _handleEngineToggle('Stores', isOpen),
                    ),
                    const SizedBox(height: 16),

                    TokenSearchEngine(
                      title: 'Tags',
                      emptyPlaceholder: 'None',
                      isMultiSelect: true, forceLowercase: true, smallPills: true,
                      knownTokens: const ['vegan', 'urgent', 'bulk', 'low sodium', 'sale'],
                      initialSelected: _selectedTags,
                      onChanged: (tokens) => setState(() => _selectedTags = tokens),
                      isExpanded: _activeEngine == 'Tags',
                      onToggle: (isOpen) => _handleEngineToggle('Tags', isOpen),
                    ),

                    if (showListSelector) ...[
                      const SizedBox(height: 16),
                      TokenSearchEngine(
                        title: 'Save to List',
                        removable: false,
                        isMultiSelect: false,
                        knownTokens: const ['Groceries', 'Hardware', 'Pharmacy', 'Clothing'],
                        initialSelected: [_selectedType],
                        onChanged: (tokens) => setState(() => _selectedType = tokens.isNotEmpty ? tokens.first : 'Groceries'),
                        isExpanded: _activeEngine == 'List',
                        onToggle: (isOpen) => _handleEngineToggle('List', isOpen),
                      ),
                    ],

                    AnimatedContainer(
                      // NEW: Slowed down closing animation using AppConstants
                      duration: AppConstants.animStandard,
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _submit,
                child: Text(
                    isEditMode ? 'Update Item' : 'Save Item',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.surface,
                    )
                ),
              ),
            ),
        ],
      ),
    );
  }
}