import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/list_provider.dart';
import '../theme/app_theme.dart';

class AddItemModal extends StatefulWidget {
  const AddItemModal({super.key});

  @override
  State<AddItemModal> createState() => _AddItemModalState();
}

class _AddItemModalState extends State<AddItemModal> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedCategory = 'Groceries'; // Default per your spec

  // The available categories to choose from
  final List<String> _categories = ['Groceries', 'Hardware', 'Pharmacy', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Reuse your exact color logic for the selection tags
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'groceries': return Colors.orange;
      case 'hardware': return Colors.blueGrey;
      case 'pharmacy': return Colors.redAccent;
      default: return AppTheme.primary;
    }
  }

  void _submit() {
    if (_nameController.text.trim().isNotEmpty) {
      // Send the item AND category to Firestore
      context.read<ListProvider>().addItem(
        _nameController.text.trim(),
        _selectedCategory,
      );
      Navigator.pop(context); // Close the slide-up sheet
    }
  }

  @override
  Widget build(BuildContext context) {
    // This variable tracks the keyboard height so the modal slides up with it
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: bottomInset + 24, // Adds padding for the keyboard
      ),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Wrap tightly around the content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Item',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // 1. The Text Input
          TextField(
            controller: _nameController,
            autofocus: true, // Pops the keyboard open instantly
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'e.g., Paper Towels',
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),

          // 2. The Category Tags
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              final categoryColor = _getCategoryColor(category);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? categoryColor : AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? categoryColor : AppTheme.border,
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.surface : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // 3. The Save Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _submit,
              child: const Text(
                'Save Item',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.surface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}