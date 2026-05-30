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
  final FocusNode _quantityFocus = FocusNode();

  final TextEditingController _unitController = TextEditingController();
  final FocusNode _unitFocus = FocusNode();

  final TextEditingController _tagInputController = TextEditingController();
  final FocusNode _tagFocus = FocusNode();

  bool _isFullScreen = false;
  double _dragHeightDelta = 0.0;

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
      final val = int.tryParse(_quantityController.text) ?? 0;
      if (val != _draftItem!.quantity) {
        setState(() => _draftItem = _draftItem!.copyWith(quantity: val));
      }
    });

    _unitController.addListener(() {
      if (_draftItem != null && _draftItem!.unit != _unitController.text) {
        setState(() => _draftItem = _draftItem!.copyWith(unit: _unitController.text));
      }
    });

    _unitFocus.addListener(() {
      if (mounted) setState(() {});
    });

    _tagFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    _quantityController.dispose();
    _quantityFocus.dispose();
    _unitController.dispose();
    _unitFocus.dispose();
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

          _quantityController.text = item.quantity > 0 ? item.quantity.toString() : '';
          _unitController.text = item.unit;

          _isFullScreen = provider.isFullEditRequested;
          _dragHeightDelta = 0.0;
        }
      } else if (provider.isFullEditRequested && !_isFullScreen) {
        _isFullScreen = true;
      }
    } else if (_originalItem != null) {
      _isFullScreen = false;
      _dragHeightDelta = 0.0;

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && provider.editItemId == null) {
          setState(() {
            _originalItem = null;
            _draftItem = null;
            _nameController.clear();
            _quantityController.clear();
            _unitController.clear();
            _tagInputController.clear();
          });
        }
      });
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

    if (_tagInputController.text.trim().isNotEmpty) return true;

    final origTags = List<String>.from(_originalItem!.attributeRows)..sort();
    final draftTags = List<String>.from(_draftItem!.attributeRows)..sort();
    return origTags.join(',') != draftTags.join(',');
  }

  void _saveAndClose() {
    if (_draftItem == null || _originalItem == null) {
      context.read<ListProvider>().setEditItem(null);
      return;
    }

    if (_tagInputController.text.trim().isNotEmpty) {
      _addTag(_tagInputController.text);
    }

    final provider = context.read<ListProvider>();
    // FIXED: Drops the keyboard entirely when saving/closing
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

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragHeightDelta -= details.delta.dy;
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details, double minHeight, double maxHeight, double screenHeight) {
    final velocity = details.primaryVelocity ?? 0.0;
    final currentHeight = (_isFullScreen ? maxHeight : minHeight) + _dragHeightDelta;
    final bool startedFullScreen = _isFullScreen;

    setState(() {
      _dragHeightDelta = 0.0;

      if (velocity < -500) {
        _isFullScreen = true;
      } else if (velocity > 500) {
        // FIXED: Swiping down fast when maximized instantly fully closes it instead of collapsing
        if (startedFullScreen) {
          _saveAndClose();
        } else {
          _saveAndClose();
        }
      } else {
        if (startedFullScreen) {
          // FIXED: Dragging down past a threshold when maximized instantly fully closes it
          if (currentHeight < maxHeight - 100) {
            _saveAndClose();
          } else {
            _isFullScreen = true;
          }
        } else {
          // Standard physics for when starting from a collapsed state
          if (currentHeight > screenHeight * 0.70) {
            _isFullScreen = true;
          } else if (currentHeight < minHeight - 50) {
            _saveAndClose();
          } else {
            _isFullScreen = false;
          }
        }
      }
    });
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
    final Set<String> tags = {};
    tags.addAll(['urgent', 'vegan', 'organic', 'low sodium', 'bulk']);

    final dict = provider.searchSmartDictionary('');
    for (var item in dict) {
      tags.addAll(item.tags);
    }

    for (var item in provider.displayList) {
      if (item is ListItem) tags.addAll(item.attributeRows);
    }

    return tags.toList().take(15).toList();
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
      _tagFocus.requestFocus();
    }
  }

  Widget _buildNativeFloatingLabelInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required ThemeData theme,
    TextInputType? keyboardType,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textAlign: TextAlign.left,
      onTap: onTap,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.titleMedium?.copyWith(
          color: theme.hintColor.withValues(alpha: 0.4),
          fontWeight: FontWeight.normal,
        ),
        floatingLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: theme.hintColor.withValues(alpha: 0.8),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: theme.cardColor,
        // FIXED: Re-balanced padding to drop the typed text slightly lower and prevent top-clipping
        contentPadding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 22.0, bottom: 10.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildMiniTagChip({required String label, required ThemeData theme, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border.all(color: AppColors.primaryAction.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.primaryAction,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
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

    final double minHeight = 340.0 + safeBottom;
    final double maxHeight = screenHeight * 0.90;

    final double baseHeight = _isFullScreen ? maxHeight : minHeight;
    final double targetHeight = (baseHeight + _dragHeightDelta).clamp(0.0, maxHeight);

    final theme = Theme.of(context);
    final geometry = FluidGeometry(MediaQuery.textScalerOf(context).scale(1.0));

    final macroProvider = context.watch<MacroListProvider>();
    final settings = context.watch<SettingsProvider>();
    final typeId = macroProvider.activeList?.typeId ?? 'sys_shopping';
    final appType = settings.getTypeById(typeId);

    final axis1Base = settings.getAxis1Groups(typeId).map((g) => g.name).where((n) => n != 'Any' && n != 'Everything Else').toList();
    final axis2Base = settings.getAxis2Groups(typeId).map((g) => g.name).where((n) => n != 'Any' && n != 'Everything Else').toList();

    final popularStores = _getPopularList(provider, 'store', axis1Base);
    final popularCategories = _getPopularList(provider, 'category', axis2Base);

    final allUnits = _getPopularUnits(provider);
    final allPopularTags = _getPopularTags(provider);
    final suggestedTags = allPopularTags.where((t) => !_draftItem!.attributeRows.contains(t)).toList();

    final hasTags = _draftItem!.attributeRows.isNotEmpty;
    final showTagHint = !hasTags && !_tagFocus.hasFocus;

    return Positioned.fill(
      child: Stack(
        children: [

          IgnorePointer(
            ignoring: !isVisible,
            child: GestureDetector(
              onTap: _saveAndClose,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: Colors.black.withValues(alpha: isVisible ? 0.4 : 0.0),
              ),
            ),
          ),

          AnimatedPositioned(
            duration: _dragHeightDelta == 0 ? const Duration(milliseconds: 300) : Duration.zero,
            curve: Curves.easeOutCubic,
            left: 0, right: 0,
            bottom: isVisible ? 0 : -maxHeight,
            height: targetHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: _handleVerticalDragUpdate,
              onVerticalDragEnd: (details) => _handleVerticalDragEnd(details, minHeight, maxHeight, screenHeight),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, -5))],
                ),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                            width: 40, height: 5,
                            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: geometry.horizontalPadding, vertical: 0.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_hasModifications)
                                TextButton(
                                  onPressed: _discardAndClose,
                                  child: const Text('Cancel', style: TextStyle(color: AppColors.destructiveAction, fontSize: 16, fontWeight: FontWeight.bold)),
                                )
                              else
                                const SizedBox(width: 60),

                              TextButton(
                                onPressed: _saveAndClose,
                                child: const Text('Done', style: TextStyle(color: AppColors.successAction, fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: geometry.horizontalPadding),
                          child: TextField(
                            controller: _nameController,
                            focusNode: _nameFocus,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _saveAndClose(),
                            minLines: 1, maxLines: 3,
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

                        const SizedBox(height: 12.0),

                        Expanded(
                          child: NotificationListener<ScrollUpdateNotification>(
                            onNotification: (notification) {
                              if (notification.metrics.axis == Axis.vertical && _isFullScreen && notification.metrics.pixels <= 0 && notification.scrollDelta != null && notification.scrollDelta! < 0) {
                                setState(() => _dragHeightDelta += notification.scrollDelta!);
                                return true;
                              }
                              return false;
                            },
                            child: SingleChildScrollView(
                              physics: _isFullScreen ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.only(left: geometry.horizontalPadding, right: geometry.horizontalPadding, bottom: keyboardHeight + safeBottom + 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [

                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildNativeFloatingLabelInput(
                                          controller: _quantityController,
                                          focusNode: _quantityFocus,
                                          label: 'Quantity',
                                          theme: theme,
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),

                                      const SizedBox(width: 12.0),

                                      Expanded(
                                        child: _buildNativeFloatingLabelInput(
                                          controller: _unitController,
                                          focusNode: _unitFocus,
                                          label: 'Unit',
                                          theme: theme,
                                        ),
                                      ),

                                      const SizedBox(width: 12.0),

                                      Container(
                                        decoration: BoxDecoration(color: theme.cardColor, shape: BoxShape.circle),
                                        child: IconButton(
                                            icon: const Icon(Icons.remove_rounded, color: AppColors.destructiveAction),
                                            onPressed: () {
                                              final newQ = ((int.tryParse(_quantityController.text) ?? 0) - 1).clamp(0, 9999);
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
                                              final newQ = ((int.tryParse(_quantityController.text) ?? 0) + 1).clamp(0, 9999);
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

                                  GestureDetector(
                                    onTap: () => _tagFocus.requestFocus(),
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      constraints: const BoxConstraints(minHeight: 120.0),
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius: BorderRadius.circular(16.0),
                                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 6.0, runSpacing: 6.0,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              ..._draftItem!.attributeRows.map((tag) => Chip(
                                                label: Text(tag, style: const TextStyle(color: AppColors.primaryAction, fontWeight: FontWeight.bold, fontSize: 12)),
                                                backgroundColor: AppColors.primaryAction.withValues(alpha: 0.1),
                                                deleteIconColor: AppColors.primaryAction,
                                                deleteIcon: const Icon(Icons.close_rounded, size: 14),
                                                side: BorderSide.none,
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                padding: EdgeInsets.zero,
                                                labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: -2),
                                                onDeleted: () {
                                                  final newTags = List<String>.from(_draftItem!.attributeRows)..remove(tag);
                                                  setState(() => _draftItem = _draftItem!.copyWith(attributeRows: newTags));
                                                },
                                              )),
                                              IntrinsicWidth(
                                                child: TextField(
                                                  controller: _tagInputController,
                                                  focusNode: _tagFocus,
                                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                                                  decoration: InputDecoration(
                                                      hintText: showTagHint ? 'Type a new tag' : '',
                                                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                                        color: theme.hintColor.withValues(alpha: 0.4),
                                                        fontWeight: FontWeight.normal,
                                                        fontSize: 14,
                                                      ),
                                                      border: InputBorder.none,
                                                      isDense: true,
                                                      contentPadding: const EdgeInsets.symmetric(vertical: 6)
                                                  ),
                                                  onSubmitted: _addTag,
                                                ),
                                              )
                                            ],
                                          ),

                                          if (suggestedTags.isNotEmpty) ...[
                                            const SizedBox(height: 16.0),
                                            SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              physics: const BouncingScrollPhysics(),
                                              child: Row(
                                                children: suggestedTags.map((tag) => Padding(
                                                  padding: const EdgeInsets.only(right: 6.0),
                                                  child: _buildMiniTagChip(
                                                    label: tag,
                                                    theme: theme,
                                                    onTap: () => _addTag(tag),
                                                  ),
                                                )).toList(),
                                              ),
                                            ),
                                          ]
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 48.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_unitFocus.hasFocus && allUnits.isNotEmpty)
                      Positioned(
                        left: 0, right: 0,
                        bottom: keyboardHeight,
                        child: Container(
                          height: 70.0,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -4))],
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: geometry.horizontalPadding),
                            child: Center(
                              child: Row(
                                children: allUnits.map((u) => Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: _buildMiniTagChip(
                                      label: u,
                                      theme: theme,
                                      onTap: () {
                                        _unitController.text = u;
                                        setState(() => _draftItem = _draftItem!.copyWith(unit: u));
                                        _unitFocus.unfocus();
                                      }
                                  ),
                                )).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

extension ConstrainedWidget on Widget {
  Widget constrained({required double width}) {
    return SizedBox(width: width, child: this);
  }
}