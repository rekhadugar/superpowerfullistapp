import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/list_provider.dart';
import '../theme/app_theme.dart';

class AddItemModal extends StatefulWidget {
  final String activeListType; // Receives the current tab from the Main Screen

  const AddItemModal({required this.activeListType, super.key});

  @override
  State<AddItemModal> createState() => _AddItemModalState();
}

class _AddItemModalState extends State<AddItemModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contextController = TextEditingController();

  late String _selectedType;
  late String _selectedCategory;

  // Master Lists (Types)
  final List<String> _types = ['Groceries', 'Hardware', 'Pharmacy', 'Clothing'];

  // ---> THE MISSING PIECE: Dynamic Categories based on the selected Type <---
  List<String> get _currentCategories {
    switch (_selectedType) {
      case 'Groceries': return ['Produce', 'Dairy', 'Bakery', 'Pantry', 'Frozen', 'Uncategorized'];
      case 'Hardware': return ['Tools', 'Fasteners', 'Paint', 'Electrical', 'Uncategorized'];
      case 'Clothing': return ['Kids', 'Adults', 'Winter', 'Uncategorized'];
      default: return ['General', 'Uncategorized'];
    }
  }

  @override
  void initState() {
    super.initState();
    // Smart Default Logic: Lock to the active tab, unless viewing "All Items"
    if (widget.activeListType == 'All Items') {
      _selectedType = 'Groceries';
    } else {
      _selectedType = widget.activeListType;
    }
    _selectedCategory = 'Uncategorized';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'groceries': return Colors.orange;
      case 'hardware': return Colors.blueGrey;
      case 'pharmacy': return Colors.redAccent;
      case 'clothing': return Colors.purpleAccent;
      default: return AppTheme.primary;
    }
  }

  void _submit() {
    if (_nameController.text.trim().isNotEmpty) {
      String rawLocations = _locationController.text.trim();
      List<String> locationList = rawLocations.isEmpty
          ? ['Anywhere']
          : rawLocations.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      context.read<ListProvider>().addItem(
        name: _nameController.text.trim(),
        type: _selectedType,
        category: _selectedCategory,
        locations: locationList,
        context: _contextController.text.trim(),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final typeColor = _getTypeColor(_selectedType);
    final isViewingAllItems = widget.activeListType == 'All Items';

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
        bottom: bottomInset > 0 ? bottomInset + 16 : 32,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Item',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
            ),
            const SizedBox(height: 20),

            // 1. Name Input
            TextField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: 'e.g., Paper Towels or Viaan\'s Snacks',
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Type (Master List) - ONLY shows if you are in the "All Items" view
            if (isViewingAllItems) ...[
              const Text('Master List', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _types.map((type) {
                    final isSelected = _selectedType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        selectedColor: _getTypeColor(type),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedType = type;
                              _selectedCategory = 'Uncategorized';
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 3. Category (Sub-group)
            const Text('Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _currentCategories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      selectedColor: typeColor.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? typeColor : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = category);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // 4. Location & Context (Notes)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Stores', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _locationController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'Fresh Farms, Target...',
                          filled: true,
                          fillColor: AppTheme.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _contextController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: 'e.g., Low sodium',
                          filled: true,
                          fillColor: AppTheme.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 5. Submit Button
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
                child: const Text('Save Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.surface)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}