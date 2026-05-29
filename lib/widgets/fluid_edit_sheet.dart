// Location: lib/widgets/fluid_edit_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/list_provider.dart';
import '../providers/macro_list_provider.dart';
import '../providers/settings_provider.dart';
import '../models/list_item.dart';
import '../theme/app_constants.dart';
import '../theme/app_theme.dart';

class FluidEditSheet extends StatefulWidget {
  const FluidEditSheet({super.key});

  @override
  State<FluidEditSheet> createState() => _FluidEditSheetState();
}

class _FluidEditSheetState extends State<FluidEditSheet> {
  ListItem? _originalItem;
  ListItem? _draftItem;

  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  final TextEditingController _tagInputController = TextEditingController();
  final FocusNode _tagFocus = FocusNode();

  bool _isFullScreen = false;
  double _dragOffset = 0.0;

  final List<String> _hardcodedUnits = ['pcs', 'lbs', 'oz', 'gal', 'pk', 'box', 'bag'];

  @override
  void initState() {
    super.initState();

    _nameController.addListener(() {
      if (_nameController.text.isEmpty && _originalItem != null) {
        _nameController.value = TextEditingValue(
          text: _originalItem!.title,
          selection: TextSelection(baseOffset: 0, extentOffset: _originalItem!.title.length),
        );
      } else if (_draftItem != null && _draftItem!.title != _nameController.text) {
        setState(() => _draftItem = _draftItem!.copyWith(title: _nameController.text));
      }
    });

    _quantityController.addListener(() {
      if (_draftItem == null) return;
      final val = int.tryParse(_quantityController.text);
      if (val != null && val != _draftItem!.quantity) {
        setState(() => _draftItem = _draftItem!.copyWith(quantity: val));
      }
    });

    _unitController.addListener(() {
      if (_draftItem != null && _draftItem!.unit != _unitController.text) {
        setState(() => _draftItem = _draftItem!.copyWith(unit: _unitController.text));
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _tagInputController.dispose();
    _tagFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<ListProvider>();
    _syncDraftWithProvider(provider);
  }

  void _syncDraftWithProvider(ListProvider provider) {
    if (provider.editItemId != null) {
      if (_originalItem == null || _originalItem!.id != provider.editItemId) {
        final item = _findItem(provider, provider.editItemId!);
        if (item != null) {
          _originalItem = item;
          _draftItem = item.copyWith();
          _nameController.text = item.title;
          _quantityController.text = item.quantity.toString();
          _unitController.text = item.unit;
          _isFullScreen = provider.isFullEditRequested;
          _dragOffset = 0.0;
        }
      } else if (provider.isFullEditRequested && !_isFullScreen) {
        _isFullScreen = true;
      }
    } else if (_originalItem != null) {
      _originalItem = null;
      _draftItem = null;
      _nameController.clear();
      _quantityController.clear();
      _unitController.clear();
      _tagInputController.clear();
      _isFullScreen = false;
    }
  }

  ListItem? _findItem(ListProvider provider, String id) {
    int index = provider.displayList.indexWhere((i) => i is ListItem && i.id == id);
    if (index != -1) return provider.displayList[index] as ListItem;

    index = provider.checkedDisplayList.indexWhere((i) => i is ListItem && i.id == id);
    if (index != -1) return provider.checkedDisplayList[index] as ListItem;

    index = provider.shoppingModeItems.indexWhere((i) => i.id == id);
    if (index != -1) return provider.shoppingModeItems[index];

    return null;
  }

  bool get _hasModifications {
    if (_originalItem == null || _draftItem == null) return false;
    if (_originalItem!.title != _draftItem!.title) return true;
    if (_originalItem!.quantity != _draftItem!.quantity) return true;
    if (_originalItem!.unit != _draftItem!.unit) return true;
    if (_originalItem!.category != _draftItem!.category) return true;
    if (_originalItem!.type != _draftItem!.type) return true;

    final origTags = List<String>.from(_originalItem!.attributeRows)..sort();
    final draftTags = List<String>.from(_draftItem!.attributeRows)..sort();
    return origTags.join(',') != draftTags.join(',');
  }

  // FIXED: Unconditionally triggers provider.setEditItem(null) to close the sheet
  void _saveAndClose() {
    if (_draftItem == null || _originalItem == null) return;

    final provider = context.read<ListProvider>();
    FocusScope.of(context).unfocus();

    if (_hasModifications) {
      provider.editItem(
        _originalItem!.id,
        _draftItem!.title.trim().isEmpty ? _originalItem!.title : _draftItem!.title.trim(),
        _draftItem!.attributeRows,
        _draftItem!.type,
        _draftItem!.category,
        _draftItem!.quantity,
        _draftItem!.unit,
      );
    }

    provider.setEditItem(null);
  }

  void _discardAndClose() {
    context.read<ListProvider>().setEditItem(null);
    FocusScope.of(context).unfocus();
  }

  void _confirmDelete() {
    if (_originalItem == null) return;
    final provider = context.read<ListProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to delete "${_originalItem!.title}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteItem(_originalItem!.id);
              provider.setEditItem(null);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.destructiveAction, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // FIXED: Pulling up anywhere on the collapsed sheet instantly snaps it to full screen
  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isFullScreen && details.delta.dy < 0) {
      setState(() {
        _isFullScreen = true;
        _dragOffset = 0;
      });
    } else {
      setState(() => _dragOffset += details.delta.dy);
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;

    if (velocity > 500 || _dragOffset > 100) {
      if (_isFullScreen && _dragOffset > 150) {
        setState(() {
          _isFullScreen = false;
          _dragOffset = 0;
        });
        FocusScope.of(context).unfocus();
      } else {
        _saveAndClose();
      }
    } else if (velocity < -500 || _dragOffset < -50) {
      setState(() {
        _isFullScreen = true;
        _dragOffset = 0;
      });
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  List<String> _getPopularList(ListProvider provider, String propertyType, List<String> baseSettings) {
    final dict = provider.searchSmartDictionary('');
    final results = List<String>.from(baseSettings);

    for (var item in dict) {
      String val = '';
      if (propertyType == 'store') val = item.store;
      if (propertyType == 'category') val = item.category;

      if (val.isNotEmpty && val != 'Any' && val != 'Everything Else' && !results.contains(val)) {
        results.add(val);
      }
    }
    return results.take(7).toList();
  }

  List<String> _getPopularTags(ListProvider provider) {
    final dict = provider.searchSmartDictionary('');
    final List<String> tags = [];
    for (var item in dict) {
      for (var t in item.tags) {
        if (!tags.contains(t)) tags.add(t);
      }
    }
    return tags.take(15).toList();
  }

  List<String> _getPopularUnits(ListProvider provider) {
    final dict = provider.searchSmartDictionary('');
    final List<String> dynamicUnits = [];
    for (var item in dict) {
      if (item.unit.isNotEmpty && !_hardcodedUnits.contains(item.unit) && !dynamicUnits.contains(item.unit)) {
        dynamicUnits.add(item.unit);
      }
    }
    return [..._hardcodedUnits, ...dynamicUnits];
  }

  void _addTag(String tag) {
    final clean = tag.trim().toLowerCase();
    if (clean.isNotEmpty && !_draftItem!.attributeRows.contains(clean)) {
      setState(() {
        _draftItem = _draftItem!.copyWith(attributeRows: [..._draftItem!.attributeRows, clean]);
        _tagInputController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListProvider>();
    if (_draftItem == null) return const SizedBox.shrink();

    final isVisible = provider.editItemId != null;
    final screenHeight = MediaQuery.of(context).size.height;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    if (keyboardHeight > 0 && !_isFullScreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _isFullScreen = true));
    }

    final double targetHeight = _isFullScreen
        ? screenHeight * 0.90
        : 340.0 + safeBottom;

    final theme = Theme.of(context);
    final geometry = FluidGeometry(MediaQuery.textScalerOf(context).scale(1.0));

    final macroProvider = context.watch<MacroListProvider>();
    final settings = context.watch<SettingsProvider>();
    final typeId = macroProvider.activeList?.typeId ?? 'sys_shopping';
    final appType = settings.getTypeById(typeId);

    // FIXED: Strips out empty states from the base settings before generating the chips
    final axis1Base = settings.getAxis1Groups(typeId).map((g) => g.name).where((n) => n != 'Any' && n != 'Everything Else').toList();
    final axis2Base = settings.getAxis2Groups(typeId).map((g) => g.name).where((n) => n != 'Any' && n != 'Everything Else').toList();

    final popularStores = _getPopularList(provider, 'store', axis1Base);
    final popularCategories = _getPopularList(provider, 'category', axis2Base);
    final popularTags = _getPopularTags(provider);
    final allUnits = _getPopularUnits(provider);

    return AnimatedPositioned(
      duration: _dragOffset == 0 ? const Duration(milliseconds: 300) : Duration.zero,
      curve: Curves.easeOutCubic,
      left: 0,
      right: 0,
      bottom: isVisible ? -_dragOffset.clamp(0.0, double.infinity) : -(targetHeight + 50),
      height: targetHeight,
      child: GestureDetector(
        onVerticalDragUpdate: _handleVerticalDragUpdate,
        onVerticalDragEnd: _handleVerticalDragEnd,
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, -5))],
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                  width: 40, height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: geometry.horizontalPadding, vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_hasModifications)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 28),
                        color: AppColors.destructiveAction,
                        onPressed: _discardAndClose,
                      )
                    else
                      const SizedBox(width: 40),

                    const SizedBox(width: 8.0),

                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saveAndClose(),
                        minLines: 1,
                        maxLines: 3,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'Item Name',
                          filled: true, fillColor: theme.cardColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: const BorderSide(color: AppColors.primaryAction, width: 2.0)),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8.0),

                    IconButton(
                      icon: const Icon(Icons.check_rounded, size: 28),
                      color: AppColors.successAction,
                      onPressed: _saveAndClose,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: NotificationListener<ScrollUpdateNotification>(
                  // FIXED: Adding top-edge pull down detection to allow dismissing from full screen
                  onNotification: (notification) {
                    if (_isFullScreen && notification.metrics.pixels <= 0 && notification.scrollDelta != null && notification.scrollDelta! < 0) {
                      setState(() => _dragOffset -= notification.scrollDelta!);
                      return true;
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    // FIXED: Restricts scrolling when collapsed, passing swipes to parent gesture detector
                    physics: _isFullScreen ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.only(left: geometry.horizontalPadding, right: geometry.horizontalPadding, bottom: keyboardHeight + safeBottom + 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        // FIXED: Rebuilt layout strictly matching [Quantity Text] -> [Unit Dropdown] -> [-] -> [+]
                        Row(
                          children: [
                            SizedBox(
                              width: 70,
                              child: TextField(
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  filled: true, fillColor: theme.cardColor,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: DropdownMenu<String>(
                                initialSelection: _draftItem!.unit,
                                controller: _unitController,
                                enableFilter: true,
                                enableSearch: true,
                                textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                inputDecorationTheme: InputDecorationTheme(
                                  filled: true, fillColor: theme.cardColor,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                ),
                                dropdownMenuEntries: allUnits.map((u) => DropdownMenuEntry(value: u, label: u)).toList(),
                                onSelected: (val) { if (val != null) setState(() => _draftItem = _draftItem!.copyWith(unit: val)); },
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Container(
                              decoration: BoxDecoration(color: theme.cardColor, shape: BoxShape.circle),
                              child: IconButton(
                                  icon: const Icon(Icons.remove_rounded, color: AppColors.destructiveAction),
                                  onPressed: () {
                                    final newQ = (_draftItem!.quantity - 1).clamp(0, 9999);
                                    _quantityController.text = newQ.toString();
                                  }
                              ),
                            ),
                            const SizedBox(width: 6.0),
                            Container(
                              decoration: BoxDecoration(color: theme.cardColor, shape: BoxShape.circle),
                              child: IconButton(
                                  icon: const Icon(Icons.add_rounded, color: AppColors.successAction),
                                  onPressed: () {
                                    final newQ = (_draftItem!.quantity + 1).clamp(0, 9999);
                                    _quantityController.text = newQ.toString();
                                  }
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24.0),

                        Text(appType.axis2Label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.hintColor)),
                        const SizedBox(height: 8.0),
                        Wrap(
                          spacing: 8.0, runSpacing: 8.0,
                          children: [
                            ...popularCategories.map((cat) => _buildChip(
                              label: cat,
                              isSelected: _draftItem!.category == cat,
                              onTap: () {
                                // FIXED: Tapping an active chip deselects it
                                if (_draftItem!.category == cat) {
                                  setState(() => _draftItem = _draftItem!.copyWith(category: 'Everything Else'));
                                } else {
                                  setState(() => _draftItem = _draftItem!.copyWith(category: cat));
                                }
                              },
                              theme: theme,
                            )),
                            _buildChip(label: '+ Add', isSelected: false, isAction: true, theme: theme, onTap: () {
                              print("Navigate to Full Axis 2 Selector");
                            }),
                          ],
                        ),

                        const SizedBox(height: 24.0),

                        Text(appType.axis1Label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.hintColor)),
                        const SizedBox(height: 8.0),
                        Wrap(
                          spacing: 8.0, runSpacing: 8.0,
                          children: [
                            ...popularStores.map((store) => _buildChip(
                              label: store,
                              isSelected: _draftItem!.type == store,
                              onTap: () {
                                // FIXED: Tapping an active chip deselects it
                                if (_draftItem!.type == store) {
                                  setState(() => _draftItem = _draftItem!.copyWith(type: 'Any'));
                                } else {
                                  setState(() => _draftItem = _draftItem!.copyWith(type: store));
                                }
                              },
                              theme: theme,
                            )),
                            _buildChip(label: '+ Add', isSelected: false, isAction: true, theme: theme, onTap: () {
                              print("Navigate to Full Axis 1 Selector");
                            }),
                          ],
                        ),

                        const SizedBox(height: 24.0),

                        Text('Tags', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.hintColor)),
                        const SizedBox(height: 8.0),

                        // FIXED: Opaque GestureDetector absorbs taps anywhere inside the container to focus the text field
                        GestureDetector(
                          onTap: () => _tagFocus.requestFocus(),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 120.0), // FIXED: Taller text area footprint
                            width: double.infinity,
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                            ),
                            child: Wrap(
                              spacing: 8.0, runSpacing: 8.0,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ..._draftItem!.attributeRows.map((tag) => Chip(
                                  label: Text(tag, style: const TextStyle(color: AppColors.primaryAction, fontWeight: FontWeight.bold)),
                                  backgroundColor: AppColors.primaryAction.withValues(alpha: 0.1),
                                  deleteIconColor: AppColors.primaryAction,
                                  side: BorderSide.none,
                                  onDeleted: () {
                                    final newTags = List<String>.from(_draftItem!.attributeRows)..remove(tag);
                                    setState(() => _draftItem = _draftItem!.copyWith(attributeRows: newTags));
                                  },
                                )),
                                IntrinsicWidth(
                                  child: TextField(
                                    controller: _tagInputController,
                                    focusNode: _tagFocus,
                                    decoration: const InputDecoration(hintText: 'add tag...', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
                                    onSubmitted: _addTag,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12.0),
                        Wrap(
                          spacing: 8.0, runSpacing: 8.0,
                          children: popularTags.where((t) => !_draftItem!.attributeRows.contains(t)).map((tag) => _buildChip(
                            label: tag,
                            isSelected: false,
                            theme: theme,
                            onTap: () => _addTag(tag),
                          )).toList(),
                        ),

                        const SizedBox(height: 48.0),

                        if (_isFullScreen)
                          Center(
                            child: TextButton.icon(
                              onPressed: _confirmDelete,
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.destructiveAction),
                              label: const Text('Delete Item', style: TextStyle(color: AppColors.destructiveAction, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip({required String label, required bool isSelected, required ThemeData theme, required VoidCallback onTap, bool isAction = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryAction : (isAction ? Colors.transparent : theme.cardColor),
          border: isAction ? Border.all(color: AppColors.primaryAction.withValues(alpha: 0.5)) : null,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? Colors.white : (isAction ? AppColors.primaryAction : theme.textTheme.bodyMedium?.color),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}