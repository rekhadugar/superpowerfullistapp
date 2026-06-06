// Location: lib/screens/main_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/sticky_header_engine.dart';
import '../models/list_item.dart';
import '../providers/list_provider.dart';
import '../providers/macro_list_provider.dart';
import '../theme/app_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/batch_action_bar.dart';
import '../widgets/edit_item_bottom_sheet.dart';
import '../widgets/fluid_edit_sheet.dart';
import '../widgets/list_item_card.dart';
import '../widgets/main_options_sheet.dart';
import '../widgets/section_header.dart';
import '../widgets/share_list_sheet.dart';
import '../widgets/swipe_action_wrapper.dart';
import 'completed_items_screen.dart';
import 'create_list_screen.dart';
import '../services/dictionary_service.dart';
import '../data/mock_global_dictionary.dart'; // Brings the SmartItem class back into scope

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late ScrollController _scrollController;
  final ValueNotifier<PhantomHeaderData> _phantomHeaderState = ValueNotifier(const PhantomHeaderData());

  String? _lastScrolledFlashId;
  Timer? _toastTimer;

  bool _isQuickAdding = false;
  bool _keyboardWasOpen = false;
  final TextEditingController _quickAddController = TextEditingController();
  final FocusNode _quickAddFocus = FocusNode();
  String _quickAddQuery = '';

  // NEW: Debouncer variables
  Timer? _debounce;
  List<SmartItem> _liveSuggestions = [];

  // FIXED: Mock Dictionary removed completely. We now rely natively on the ListProvider.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ListProvider>().addListener(_onProviderStateChanged);
      }
    });

    // FIXED: Implementing the 300ms Debouncer and Character Threshold
    _quickAddController.addListener(() {
      if (!mounted) return;
      final text = _quickAddController.text;

      // Prevent redundant triggers if only focus changed
      if (text == _quickAddQuery) return;

      setState(() => _quickAddQuery = text);

      // Cancel the previous timer if the user is still typing
      if (_debounce?.isActive ?? false) _debounce!.cancel();

      // Shield 1: Character Threshold (Don't search for 1 or 2 letters)
      if (text.trim().length < 3) {
        setState(() => _liveSuggestions = []);
        return;
      }

      // Shield 2: Wait 300ms after they stop typing before filtering
      _debounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted && _quickAddQuery == text) {
          // Shield 3: Instant RAM query
          setState(() {
            _liveSuggestions = DictionaryService.searchItems(text);
          });
        }
      });
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;

    if (bottomInset > 0) {
      _keyboardWasOpen = true;
    } else if (bottomInset == 0.0 && _isQuickAdding && _keyboardWasOpen) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _isQuickAdding) {
            _closeQuickAdd();
          }
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.of(context).size.width;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ListProvider>().updateViewportMetrics(screenWidth, textScale);
      }
    });
  }

  void _onProviderStateChanged() {
    if (!mounted) return;
    final provider = context.read<ListProvider>();

    if (provider.flashItemId != null && provider.flashItemId != _lastScrolledFlashId) {
      _lastScrolledFlashId = provider.flashItemId;
      final targetOffset = provider.getOffsetForItem(provider.flashItemId!);

      if (targetOffset != null && _scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;

        // FIXED: The exact mathematical scroll target.
        // We add the listTopPadding to account for the physical shift of the scroll view,
        // then subtract the headerHeight so it docks flush against the bottom of the sticky header.
        double exactScrollTarget = targetOffset + AppConstants.listTopPadding - AppConstants.headerHeight;

        _scrollController.animateTo(
          exactScrollTarget.clamp(0.0, maxScroll),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
        );
      }
    } else if (provider.flashItemId == null) {
      _lastScrolledFlashId = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _toastTimer?.cancel();
    _debounce?.cancel(); // NEW: Cancel debouncer on dispose
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _phantomHeaderState.dispose();
    _quickAddController.dispose();
    _quickAddFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    // FIXED: Prevents math errors if forced to recalculate during a hard layout shift
    if (!_scrollController.hasClients) return;

    final provider = context.read<ListProvider>();
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    final newHeaderData = StickyHeaderEngine.calculatePhantomHeader(
      _scrollController.offset,
      provider.cumulativeYOffsets,
      provider.displayList,
      textScaleFactor: textScale,
    );

    if (_phantomHeaderState.value.title != newHeaderData.title ||
        _phantomHeaderState.value.yOffset != newHeaderData.yOffset) {
      _phantomHeaderState.value = newHeaderData;
    }
  }

  void _showActionToast(BuildContext context, String message, VoidCallback? onUndo) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.fixed,
        backgroundColor: theme.colorScheme.inverseSurface,
        elevation: 0,
        content: SizedBox(
          height: AppConstants.baseCardHeight * 1.5,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(message, style: TextStyle(color: theme.colorScheme.onInverseSurface, fontWeight: FontWeight.bold))),
                if (onUndo != null)
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      onUndo();
                    },
                    child: const Text('Undo', style: TextStyle(color: AppColors.primaryAction, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _startQuickAdd() {
    setState(() {
      _isQuickAdding = true;
      _keyboardWasOpen = false;
    });
    _quickAddFocus.requestFocus();
  }

  void _closeQuickAdd() {
    setState(() {
      _isQuickAdding = false;
      _keyboardWasOpen = false;
      _quickAddController.clear();
      _quickAddQuery = '';
      _liveSuggestions = []; // NEW: Clear the suggestions
    });
    _quickAddFocus.unfocus();

    void forceHeaderSync() {
      if (mounted && _scrollController.hasClients) {
        _onScroll();
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => forceHeaderSync());
    Future.delayed(const Duration(milliseconds: 100), forceHeaderSync);
    Future.delayed(const Duration(milliseconds: 250), forceHeaderSync);
    Future.delayed(const Duration(milliseconds: 450), forceHeaderSync);
  }

  // FIXED: Now also accepts the unit parameter to fully reconstruct items from the dictionary
  void _commitQuickAdd([String? specificName, String? category, String? store, String? unit]) {
    final text = specificName ?? _quickAddController.text.trim();
    if (text.isNotEmpty) {
      context.read<ListProvider>().addItem(
          text,
          [],
          store ?? 'Any',
          category ?? 'Everything Else',
          0,
          unit ?? 'pcs' // Utilizes the SmartItem unit if available
      );
      _quickAddController.clear();
      setState(() => _quickAddQuery = '');
      _quickAddFocus.requestFocus();
    } else {
      _closeQuickAdd();
    }
  }

  // FIXED: Injects ListProvider directly to query the real backend dictionary
  Widget _buildSmartSuggestions(ThemeData theme, FluidGeometry geometry, ListProvider listProvider) {
    final query = _quickAddQuery.trim();

    return Material(
      elevation: 12.0,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(16.0),
      color: theme.cardColor,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.45,
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          children: [
            // 1. The Dynamic "Create New" Row (Always visible)
            InkWell(
              onTap: () => _commitQuickAdd(query, 'Everything Else', 'Any', 'pcs'),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: geometry.horizontalPadding, vertical: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                          color: AppColors.primaryAction.withValues(alpha: 0.1),
                          shape: BoxShape.circle
                      ),
                      child: Icon(Icons.add_rounded, color: AppColors.primaryAction, size: geometry.iconSize * 0.9),
                    ),
                    SizedBox(width: geometry.interElementGap),
                    Expanded(
                      child: Text(
                        'Add "$query"',
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryAction
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // FIXED: Now uses the live async array populated by the debouncer
            if (_liveSuggestions.isNotEmpty)
              Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),

            // 2. Smart Dictionary Suggestions
            ..._liveSuggestions.map((item) {
              return InkWell(
                onTap: () => _commitQuickAdd(item.title, item.category, item.store, item.unit),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: geometry.horizontalPadding, vertical: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5), size: geometry.iconSize * 0.9),
                      SizedBox(width: geometry.interElementGap),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                item.title,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)
                            ),
                            const SizedBox(height: 6.0),
                            Row(
                              children: [
                                _buildMiniBadge(theme, item.category, Icons.category_outlined),
                                const SizedBox(width: 8.0),
                                _buildMiniBadge(theme, item.store, Icons.storefront_outlined),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.north_west_rounded, color: theme.dividerColor, size: geometry.iconSize * 0.7),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(ThemeData theme, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: theme.dividerColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: theme.textTheme.bodyMedium?.color),
          const SizedBox(width: 4),
          Text(text, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final macroProvider = context.watch<MacroListProvider>();

    if (!macroProvider.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (macroProvider.lists.isEmpty) {
      return const CreateListScreen(isFirstLaunch: true);
    }

    final activeId = macroProvider.activeListId!;
    context.read<ListProvider>().loadItems(activeId);
    context.read<ListProvider>().syncGlobalDictionary(macroProvider.lists);

    final listProvider = context.watch<ListProvider>();
    final displayList = listProvider.displayList;
    final activeList = context.watch<MacroListProvider>().activeList;
    final theme = Theme.of(context);
    final double safeBottomPadding = MediaQuery.of(context).padding.bottom;

    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final geometry = FluidGeometry(textScale);

    final double pillHeight = geometry.baseCardHeight;

    return GestureDetector(
      onTap: () {
        if (listProvider.openSwipeItemId.value != null) {
          listProvider.openSwipeItemId.value = null;
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: theme.scaffoldBackgroundColor,
            // FIXED: Contextual AppBar for Batch Selection Mode
            appBar: listProvider.isBatchModeActive
                ? AppBar(
              backgroundColor: theme.cardColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.close, color: theme.textTheme.titleMedium?.color),
                onPressed: () => listProvider.clearSelection(),
              ),
              title: Text(
                '${listProvider.selectedItemIds.length} Selected',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.select_all, color: theme.textTheme.titleMedium?.color),
                  tooltip: 'Select All',
                  onPressed: () {
                    final allVisibleIds = displayList.whereType<ListItem>().map((e) => e.id).toList();
                    listProvider.selectAll(allVisibleIds);
                  },
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: theme.textTheme.titleMedium?.color),
                  onSelected: (String value) {
                    if (value == 'delete') {
                      listProvider.deleteSelectedItems();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: AppColors.destructiveAction, size: 20),
                          SizedBox(width: 12),
                          Text('Delete Selected', style: TextStyle(color: AppColors.destructiveAction, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
                : AppBar(
              leadingWidth: _isQuickAdding
                  ? geometry.leadingBlockWidth + geometry.horizontalPadding
                  : geometry.horizontalPadding + geometry.leadingBlockWidth + geometry.interElementGap,
              leading: _isQuickAdding
                  ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, size: geometry.iconSize, color: theme.textTheme.titleMedium?.color),
                onPressed: _closeQuickAdd,
              )
                  : Padding(
                padding: EdgeInsets.only(left: geometry.horizontalPadding),
                child: Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.menu_rounded, size: geometry.iconSize, color: theme.textTheme.titleMedium?.color),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    onPressed: () => context.findRootAncestorStateOfType<ScaffoldState>()?.openDrawer(),
                  ),
                ),
              ),
              titleSpacing: 0,
              title: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                height: pillHeight,
                margin: EdgeInsets.only(
                  right: _isQuickAdding ? 0.0 : geometry.horizontalPadding,
                ),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(pillHeight / 2),
                ),
                child: _isQuickAdding
                    ? AnimatedBuilder(
                  animation: _quickAddController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        if (_quickAddController.text.isEmpty)
                          Center(
                            child: Text(
                              'Add an item...',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.hintColor,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        TextField(
                          controller: _quickAddController,
                          focusNode: _quickAddFocus,
                          textAlign: TextAlign.left,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _commitQuickAdd(),
                          textAlignVertical: TextAlignVertical.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: geometry.horizontalPadding),
                          ),
                        ),
                      ],
                    );
                  },
                )
                    : GestureDetector(
                  onTap: _startQuickAdd,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: geometry.horizontalPadding),
                    child: Text(
                      activeList?.name ?? 'Listicle',
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              scrolledUnderElevation: 0.0,
              surfaceTintColor: Colors.transparent,
              centerTitle: false,
              actions: [
                if (_isQuickAdding)
                  IconButton(
                    icon: Icon(Icons.check_rounded, size: geometry.iconSize * 1.15, color: AppColors.primaryAction),
                    onPressed: _commitQuickAdd,
                  )
                else
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: geometry.iconSize, color: theme.textTheme.titleMedium?.color),
                    onSelected: (String value) {
                      if (value == 'share') {
                        if (activeList != null) {
                          ShareListSheet.show(context, activeList);
                        }
                      } else if (value == 'options') {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => const MainOptionsSheet(),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.person_add_alt_1_rounded, size: 20, color: AppColors.primaryAction),
                            SizedBox(width: 12),
                            Text('Share List', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'options',
                        child: Row(
                          children: [
                            Icon(Icons.tune_rounded, size: 20),
                            SizedBox(width: 12),
                            Text('List Options'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            body: Stack(
              children: [
                displayList.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'All caught up!\nTap + to add your first item.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (listProvider.checkedDisplayList.isNotEmpty) ...[
                        SizedBox(height: geometry.baseCardHeight),
                        TextButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompletedItemsScreen())),
                          icon: Icon(Icons.history_rounded, color: theme.textTheme.bodyMedium?.color),
                          label: Text('View Completed Items', style: theme.textTheme.bodyMedium),
                        ),
                      ]
                    ],
                  ),
                )
                    : NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    if (listProvider.openSwipeItemId.value != null) {
                      listProvider.openSwipeItemId.value = null;
                    }

                    if (notification is ScrollUpdateNotification && notification.dragDetails != null) {
                      if (_isQuickAdding) {
                        _closeQuickAdd();
                      }

                      if (listProvider.editItemId != null) {
                        final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
                        if (isKeyboardOpen) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        } else {
                          listProvider.setEditItem(null);
                        }
                      }
                    }
                    return false;
                  },
                  child: Stack(
                    children: [
                      ReorderableListView.builder(
                        scrollController: _scrollController,
                        padding: EdgeInsets.only(
                            top: AppConstants.listTopPadding,
                            bottom: listProvider.isBatchModeActive
                                ? AppConstants.batchModeBottomClearance
                                : safeBottomPadding + AppConstants.listBottomClearance
                        ),
                        itemCount: displayList.length,
                        buildDefaultDragHandles: false,

                        footer: Column(
                          key: const ValueKey('completed_footer'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isQuickAdding)
                              SizedBox(height: MediaQuery.of(context).size.height),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: geometry.baseCardHeight / 2),
                              child: TextButton.icon(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompletedItemsScreen())),
                                icon: Icon(Icons.history_rounded, color: theme.textTheme.bodyMedium?.color),
                                label: Text('View Completed Items', style: theme.textTheme.bodyMedium),
                              ),
                            ),
                          ],
                        ),

                        onReorder: (oldIndex, newIndex) {
                          if (oldIndex == newIndex) {
                            final item = displayList[oldIndex];
                            if (item is ListItem) context.read<ListProvider>().toggleSelection(item.id);
                            return;
                          }
                          context.read<ListProvider>().executeNativeReorder(oldIndex, newIndex);
                        },
                        proxyDecorator: (child, index, animation) {
                          return Material(color: Colors.transparent, elevation: 8.0, shadowColor: Colors.black45, child: child);
                        },
                        itemBuilder: (context, index) {
                          final item = displayList[index];

                          if (item is String) {
                            return Container(key: ValueKey('header_$item'), child: SectionHeader(title: item));
                          }

                          if (item is ListItem) {
                            Widget coreCard = ListItemCard(
                              title: item.title,
                              nWrap: item.nWrap,
                              nTagRows: item.nTagRows,
                              attributeRows: item.attributeRows,
                              type: item.type,
                              category: item.category,
                              sortMode: listProvider.currentSortMode,
                              quantity: item.quantity,
                              unit: item.unit,
                              isHighlighted: listProvider.flashItemId == item.id,
                              isDragging: false,
                              isBatchModeActive: listProvider.isBatchModeActive,
                              isBatchSelected: listProvider.selectedItemIds.contains(item.id),
                              isFluidEditing: listProvider.editItemId == item.id,

                              onCheck: () {
                                final id = listProvider.toggleCompletion(item.id);
                                _showActionToast(context, '${item.title} checked off', () => listProvider.restoreItems([id]));
                              },
                              onTap: () {
                                if (listProvider.openSwipeItemId.value != null) {
                                  listProvider.openSwipeItemId.value = null;
                                } else {
                                  if (listProvider.isBatchModeActive) {
                                    context.read<ListProvider>().toggleSelection(item.id);
                                  } else {
                                    if (listProvider.editItemId == item.id) {
                                      context.read<ListProvider>().setFullEditRequest(false);
                                      context.read<ListProvider>().setEditItem(null);
                                    } else {
                                      context.read<ListProvider>().setFullEditRequest(false);
                                      context.read<ListProvider>().setEditItem(item.id);
                                    }
                                  }
                                }
                              },
                              onToggleSelection: () => context.read<ListProvider>().toggleSelection(item.id),
                            );

                            return ReorderableDelayedDragStartListener(
                              key: ValueKey('drag_${item.id}'),
                              index: index,
                              child: SwipeActionWrapper(
                                key: ValueKey('swipe_${item.id}'),
                                itemId: item.id,
                                requireConfirm: true,
                                isBatchModeActive: listProvider.isBatchModeActive,
                                onCheckout: () {
                                  final id = listProvider.toggleCompletion(item.id);
                                  _showActionToast(context, '${item.title} checked off', () => listProvider.restoreItems([id]));
                                },
                                onEdit: () {
                                  listProvider.clearAllInteractions();
                                  listProvider.setEditItem(item.id);
                                  listProvider.setFullEditRequest(true);
                                },
                                onDelete: () {
                                  final id = listProvider.deleteItem(item.id);
                                  _showActionToast(context, '${item.title} deleted', () => listProvider.restoreItems([id]));
                                },
                                child: coreCard,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      ValueListenableBuilder<PhantomHeaderData>(
                        valueListenable: _phantomHeaderState,
                        builder: (context, data, child) {
                          if (data.title == null) return const SizedBox.shrink();
                          return Positioned(
                            top: 0, left: 0, right: 0,
                            child: RepaintBoundary(
                              child: Transform.translate(offset: Offset(0, data.yOffset), child: SectionHeader(title: data.title!)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                if (_isQuickAdding) ...[
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _closeQuickAdd,
                      onPanStart: (_) => _closeQuickAdd(),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  if (_quickAddQuery.trim().isNotEmpty)
                    Positioned(
                      top: 8.0,
                      left: geometry.horizontalPadding,
                      right: geometry.horizontalPadding,
                      child: _buildSmartSuggestions(theme, geometry, listProvider),
                    ),
                ],

                const BatchActionBar(),

                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  right: geometry.horizontalPadding,
                  bottom: (listProvider.isBatchModeActive || listProvider.editItemId != null || _isQuickAdding)
                      ? -100.0
                      : safeBottomPadding + AppConstants.listBottomClearance + geometry.horizontalPadding,
                  child: FloatingActionButton(
                    onPressed: _startQuickAdd,
                    backgroundColor: AppColors.primaryAction,
                    elevation: 4,
                    child: Icon(Icons.add, color: Colors.white, size: geometry.iconSize * 1.15),
                  ),
                ),
              ],
            ),
          ),
          const FluidEditSheet(),
        ],
      ),
    );
  }
}