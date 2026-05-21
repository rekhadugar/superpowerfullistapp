import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AgileChipSelector extends StatefulWidget {
  final String title;
  final List<String> dictionary;
  final List<String> initialSelections;
  final bool isMultiSelect;
  final Function(List<String>) onSelectionChanged;

  const AgileChipSelector({
    Key? key,
    required this.title,
    required this.dictionary,
    required this.initialSelections,
    this.isMultiSelect = false,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  State<AgileChipSelector> createState() => _AgileChipSelectorState();
}

class _AgileChipSelectorState extends State<AgileChipSelector> {
  late List<String> _selectedItems;
  bool _isEditing = false;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.initialSelections);

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _commitText(); // Auto-commit if user taps away to dismiss keyboard
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _isEditing = true);
    _focusNode.requestFocus();

    // Natively glide this specific widget to the center of the screen above the keyboard
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        Scrollable.ensureVisible(context, alignment: 0.5, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _commitText() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _toggleItem(text, forceAdd: true);
    }
    setState(() {
      _isEditing = false;
      _textController.clear();
    });
  }

  void _toggleItem(String item, {bool forceAdd = false}) {
    setState(() {
      if (widget.isMultiSelect) {
        if (forceAdd && !_selectedItems.contains(item)) {
          _selectedItems.add(item);
        } else if (!forceAdd) {
          _selectedItems.contains(item) ? _selectedItems.remove(item) : _selectedItems.add(item);
        }
      } else {
        _selectedItems = [item];
        if (!forceAdd) {
          _isEditing = false; // Close keyboard if single selecting from chips
          _focusNode.unfocus();
        }
      }
    });
    widget.onSelectionChanged(_selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    final query = _textController.text.trim().toLowerCase();

    // Filter the dictionary based on what they are typing
    final filteredDictionary = widget.dictionary.where((item) => item.toLowerCase().contains(query)).toList();

    // Add any currently selected items to the list so they don't disappear while typing
    final displayChips = <String>{..._selectedItems, ...filteredDictionary}.toList();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The Transforming Header
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isEditing
                ? TextField(
              controller: _textController,
              focusNode: _focusNode,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _commitText(),
              decoration: InputDecoration(
                hintText: 'Type new ${widget.title.toLowerCase()}...',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                border: const UnderlineInputBorder(),
                suffixIcon: IconButton(icon: const Icon(Icons.check, color: AppColors.primaryAction), onPressed: _commitText),
              ),
            )
                : GestureDetector(
              onTap: _startEditing,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Icon(Icons.add_circle, color: AppColors.primaryAction),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12.0),

          // The Dynamic Chip Wrap
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              if (!widget.isMultiSelect)
                ChoiceChip(
                  label: const Text('None'),
                  selected: _selectedItems.isEmpty,
                  onSelected: (_) => setState(() { _selectedItems.clear(); widget.onSelectionChanged(_selectedItems); }),
                  selectedColor: Colors.grey.shade200,
                  backgroundColor: Colors.grey.shade50,
                  labelStyle: TextStyle(color: _selectedItems.isEmpty ? Colors.black87 : Colors.grey.shade600, fontWeight: _selectedItems.isEmpty ? FontWeight.bold : FontWeight.normal),
                ),

              ...displayChips.map((item) {
                final isSelected = _selectedItems.contains(item);
                return widget.isMultiSelect
                    ? FilterChip(
                  label: Text(item),
                  selected: isSelected,
                  onSelected: (_) => _toggleItem(item),
                  selectedColor: AppColors.primaryAction.withOpacity(0.15),
                  backgroundColor: Colors.grey.shade50,
                  checkmarkColor: AppColors.primaryAction,
                  labelStyle: TextStyle(color: isSelected ? AppColors.primaryAction : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0), side: BorderSide(color: isSelected ? AppColors.primaryAction : Colors.grey.shade300)),
                )
                    : ChoiceChip(
                  label: Text(item),
                  selected: isSelected,
                  onSelected: (_) => _toggleItem(item),
                  selectedColor: AppColors.primaryAction.withOpacity(0.15),
                  backgroundColor: Colors.grey.shade50,
                  labelStyle: TextStyle(color: isSelected ? AppColors.primaryAction : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0), side: BorderSide(color: isSelected ? AppColors.primaryAction : Colors.grey.shade300)),
                );
              }).toList(),

              // The Create New Chip (Appears dynamically while typing)
              if (_isEditing && query.isNotEmpty && !displayChips.any((c) => c.toLowerCase() == query))
                ActionChip(
                  label: Text('+ Create "$query"'),
                  onPressed: _commitText,
                  backgroundColor: AppColors.primaryAction,
                  labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}