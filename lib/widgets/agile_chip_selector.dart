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
        _commitText();
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
          _isEditing = false;
          _focusNode.unfocus();
        }
      }
    });
    widget.onSelectionChanged(_selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    final query = _textController.text.trim().toLowerCase();

    // The bottom row should only show items that are NOT currently selected
    final unselectedDictionary = widget.dictionary.where(
            (item) => item.toLowerCase().contains(query) && !_selectedItems.contains(item)
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ROW 1: Header + Selected Items (Horizontally Scrollable)
        Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isEditing
                  ? SizedBox(
                width: 140,
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _commitText(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'New ${widget.title}...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                  ),
                ),
              )
                  : GestureDetector(
                onTap: _startEditing,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${widget.title}:', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black54)),
                    const SizedBox(width: 6),
                    const Icon(Icons.add_circle, color: AppColors.primaryAction, size: 20),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),

            // The Selected Chips
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _selectedItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InputChip(
                        label: Text(item, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryAction)),
                        backgroundColor: AppColors.primaryAction.withOpacity(0.12),
                        deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.primaryAction),
                        onDeleted: () => _toggleItem(item), // Tapping the 'X' removes it
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0), side: const BorderSide(color: Colors.transparent)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8.0),

        // ROW 2: Available Dictionary Items (Horizontally Scrollable)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // Show 'None' option for single-select if empty
              if (!widget.isMultiSelect && _selectedItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: const Text('None', style: TextStyle(color: Colors.black54)),
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0), side: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),

              // The Available Chips
              ...unselectedDictionary.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text(item),
                    onPressed: () => _toggleItem(item), // Tapping moves it to the Top Row
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0), side: BorderSide(color: Colors.grey.shade300)),
                  ),
                );
              }).toList(),

              // The Dynamic "+ Create" Chip
              if (_isEditing && query.isNotEmpty && !widget.dictionary.any((c) => c.toLowerCase() == query))
                ActionChip(
                  label: Text('+ Create "$query"'),
                  onPressed: _commitText,
                  backgroundColor: AppColors.primaryAction,
                  labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0), side: const BorderSide(color: Colors.transparent)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12.0), // Bottom padding before the next section
      ],
    );
  }
}