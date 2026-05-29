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

    _quickAddController.addListener(() {
      if (mounted) setState(() => _quickAddQuery = _quickAddController.text);
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
        double safeBuffer = AppConstants.headerHeight;
        double scrollTarget = (targetOffset - safeBuffer).clamp(0.0, maxScroll);

        _scrollController.animateTo(
          scrollTarget,
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _phantomHeaderState.dispose();
    _quickAddController.dispose();
    _quickAddFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
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
    });
    _quickAddFocus.unfocus();
  }

  void _commitQuickAdd() {
    final text = _quickAddController.text.trim();
    if (text.isNotEmpty) {
      context.read<ListProvider>().addItem(text, [], 'Any', 'Everything Else', 0, 'pcs');
      _quickAddController.clear();
      setState(() => _quickAddQuery = '');
      _quickAddFocus.requestFocus();
    } else {
      _closeQuickAdd();
    }
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

    // Calculates a compact height tightly wrapped around the font size
    final double pillHeight = (AppConstants.titleFontSize * textScale) + 20.0;

    return GestureDetector(
      onTap: () {
        if (listProvider.openSwipeItemId.value != null) {
          listProvider.openSwipeItemId.value = null;
        }
        if (_isQuickAdding) {
          _closeQuickAdd();
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
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
            height: pillHeight, // Uses the dynamically shorter height
            margin: EdgeInsets.only(
              right: _isQuickAdding ? 0.0 : geometry.horizontalPadding,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(pillHeight / 2),
            ),
            child: _isQuickAdding
                ? Container(
              alignment: Alignment.center,
              child: TextField(
                controller: _quickAddController,
                focusNode: _quickAddFocus,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _commitQuickAdd(),
                textAlignVertical: TextAlignVertical.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: AppConstants.titleFontSize,
                ),
                decoration: InputDecoration(
                  hintText: 'Add an item...',
                  hintStyle: theme.textTheme.titleMedium?.copyWith(
                    fontSize: AppConstants.titleFontSize,
                    color: theme.hintColor,
                    fontWeight: FontWeight.normal,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  // Adjusted vertical padding to keep text vertically centered in the shorter box
                  contentPadding: EdgeInsets.symmetric(horizontal: geometry.horizontalPadding, vertical: 4.0),
                ),
              ),
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
                      fontSize: AppConstants.titleFontSize,
                      fontWeight: FontWeight.bold
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          backgroundColor: theme.cardColor,
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

                    footer: Padding(
                      key: const ValueKey('completed_footer'),
                      padding: EdgeInsets.symmetric(vertical: geometry.baseCardHeight / 2),
                      child: TextButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompletedItemsScreen())),
                        icon: Icon(Icons.history_rounded, color: theme.textTheme.bodyMedium?.color),
                        label: Text('View Completed Items', style: theme.textTheme.bodyMedium),
                      ),
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
                                  context.read<ListProvider>().setEditItem(null);
                                } else {
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

            const FluidEditSheet(),
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
    );
  }
}