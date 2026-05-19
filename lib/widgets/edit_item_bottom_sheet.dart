// Location: lib/widgets/edit_item_bottom_sheet.dart

import 'package:flutter/material.dart';
import '../models/list_item.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';

class EditItemBottomSheet extends StatefulWidget {
  final ListItem item;
  final Function(String newTitle, List<String> newAttributes) onSave;

  const EditItemBottomSheet({
    Key? key,
    required this.item,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditItemBottomSheet> createState() => _EditItemBottomSheetState();
}

class _EditItemBottomSheetState extends State<EditItemBottomSheet> {
  late TextEditingController _titleController;
  late TextEditingController _attributesController;
  final FocusNode _titleFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);

    // Join existing attributes with a comma for simple editing
    _attributesController = TextEditingController(text: widget.item.attributeRows.join(', '));

    // Auto-focus the title field when the sheet opens for a premium native feel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _attributesController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _handleSave() {
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) return;

    // Split by comma and clean up whitespace for the pill badges
    final newAttributes = _attributesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    widget.onSave(newTitle, newAttributes);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      // Dynamic padding handles the keyboard overlap gracefully
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
        left: AppConstants.horizontalPadding,
        right: AppConstants.horizontalPadding,
        top: 16.0,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // iOS-style drag handle
          Center(
            child: Container(
              width: 40.0,
              height: 4.0,
              margin: const EdgeInsets.only(bottom: 24.0),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),

          Text(
            'EDIT ITEM',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: theme.textTheme.titleMedium?.color?.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12.0),

          // Item Title TextField
          TextField(
            controller: _titleController,
            focusNode: _titleFocus,
            maxLines: null,
            textInputAction: TextInputAction.next,
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 16.0, height: 1.25),
            decoration: InputDecoration(
              hintText: 'Item name...',
              border: InputBorder.none,
              filled: true,
              fillColor: theme.cardColor,
              contentPadding: const EdgeInsets.all(16.0),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: AppColors.primaryAction, width: 2.0),
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Attributes TextField
          TextField(
            controller: _attributesController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSave(),
            style: theme.textTheme.labelSmall?.copyWith(fontSize: 14.0),
            decoration: InputDecoration(
              hintText: 'Tags (comma separated)...',
              border: InputBorder.none,
              filled: true,
              fillColor: theme.cardColor,
              contentPadding: const EdgeInsets.all(16.0),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: AppColors.primaryAction, width: 2.0),
              ),
              prefixIcon: Icon(Icons.sell_outlined, size: 18.0, color: theme.dividerColor),
            ),
          ),
          const SizedBox(height: 24.0),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: theme.textTheme.titleMedium?.color, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAction,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}