import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/list_item.dart';
import '../providers/list_provider.dart';
import '../theme/app_theme.dart';
import 'horizontal_pill_selector.dart';
import '../data/mock_global_dictionary.dart';

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
  late FocusNode _titleFocus;

  late int _quantity;
  late String _unit;
  late String _selectedCategory;
  late String _selectedStore;
  late List<String> _selectedTags;

  // SMART PREFILL STATE
  bool _isConfirmationState = false;
  List<SmartItem> _suggestions = [];

  final List<String> _units = ['pcs', 'lbs', 'oz', 'gal', 'pk', 'box', 'bag'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _titleFocus = FocusNode();

    _quantity = widget.item?.quantity ?? 1;
    _unit = _units.contains(widget.item?.unit) ? (widget.item?.unit ?? 'pcs') : 'pcs';
    _selectedCategory = widget.item?.category ?? '';
    _selectedStore = widget.item?.type ?? '';
    _selectedTags = List.from(widget.item?.attributeRows ?? []);

    // If editing an existing item, skip discovery and go straight to full confirmation layout
    _isConfirmationState = widget.item != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isConfirmationState && mounted) {
        setState(() {
          _suggestions = context.read<ListProvider>().searchSmartDictionary(''); // FIX: Updated method name
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    if (mounted) {
      setState(() {
        _suggestions = context.read<ListProvider>().searchSmartDictionary(val); // FIX: Updated method name
      });
    }
  }

  void _selectSuggestion(SmartItem item) {
    final provider = context.read<ListProvider>();

    // 1. Already Active Shortcut
    if (provider.isActiveItem(item.title)) {
      final id = provider.getActiveItemIdByTitle(item.title);
      if (id != null) provider.triggerSequentialFlash(id);
      Navigator.pop(context);
      return;
    }

    // 2. Transition to Confirmation State with prefilled data
    setState(() {
      _titleController.text = item.title;
      _selectedCategory = item.category;
      _selectedStore = item.store;
      _unit = item.unit;
      _isConfirmationState = true;
    });

    _titleFocus.unfocus(); // Dismiss keyboard to bring Save button into full view
  }

  void _instantSave(String val) {
    final title = val.trim();
    if (title.isEmpty) return;

    final provider = context.read<ListProvider>();

    // 1. Already Active Shortcut
    if (provider.isActiveItem(title)) {
      final id = provider.getActiveItemIdByTitle(title);
      if (id != null) provider.triggerSequentialFlash(id);
      Navigator.pop(context);
      return;
    }

    // 2. Background Dictionary Match for quick saving
    final match = provider.getExactDictionaryMatch(title);
    if (match != null) {
      widget.onSave(title, [], match.store, match.category, _quantity, match.unit);
    } else {
      widget.onSave(title, _selectedTags, _selectedStore, _selectedCategory, _quantity, _unit);
    }

    Navigator.pop(context);
  }

  Widget _buildSuggestions(ListProvider provider, ThemeData theme) {
    List<Widget> children = [];
    final query = _titleController.text.trim();

    // 1. "Create New" Prompt (if no exact match)
    final hasExactMatch = _suggestions.any((item) => item.title.toLowerCase() == query.toLowerCase());
    if (query.isNotEmpty && !hasExactMatch) {
      children.add(
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primaryAction.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.add, color: AppColors.primaryAction, size: 20),
            ),
            title: Text('Create "$query"', style: const TextStyle(color: AppColors.primaryAction, fontWeight: FontWeight.bold)),
            onTap: () {
              setState(() => _isConfirmationState = true);
              _titleFocus.unfocus();
            },
          )
      );
    }

    // 2. Global / Popular Suggestions
    children.addAll(_suggestions.map((item) {
      final isActive = provider.isActiveItem(item.title);
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
        leading: Icon(Icons.history, color: theme.dividerColor),
        title: Text(item.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text('${item.category} • ${item.store}', style: theme.textTheme.labelSmall),
        trailing: isActive
            ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.successAction.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Text('On List', style: TextStyle(color: AppColors.successAction, fontSize: 12, fontWeight: FontWeight.bold))
        )
            : Icon(Icons.north_west, color: theme.dividerColor, size: 16),
        onTap: () => _selectSuggestion(item),
      );
    }));

    return Column(children: children);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListProvider>();
    final theme = Theme.of(context);

    final categoriesDict = provider.activeCategoryDictionary;
    final storesDict = provider.activeStoreDictionary;
    final tagsDict = provider.activeTagDictionary;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
        top: 16.0,
        left: 20.0,
        right: 20.0,
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle & Cancel Button Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_isConfirmationState && widget.item == null)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.bold)),
                  )
                else
                  const SizedBox(width: 64),

                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2.0)),
                ),

                const SizedBox(width: 64),
              ],
            ),
            const SizedBox(height: 16.0),

            // Smart Text Input
            TextField(
              controller: _titleController,
              focusNode: _titleFocus,
              autofocus: widget.item == null,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onChanged: _onSearchChanged,
              onSubmitted: _instantSave,
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

            // STATE RENDERING
            if (!_isConfirmationState)
              _buildSuggestions(provider, theme)
            else ...[
              // CONFIRMATION STATE (Full Layout)
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: Colors.grey.shade300)),
                    child: Row(
                      children: [
                        IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() => _quantity = (_quantity - 1).clamp(0, 99))),
                        SizedBox(width: 24, child: Text('$_quantity', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                        IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _quantity = (_quantity + 1).clamp(0, 99))),
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
                isTag: true,
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
            ]
          ],
        ),
      ),
    );
  }
}