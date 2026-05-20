import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/list_provider.dart';
import '../widgets/edit_item_bottom_sheet.dart';
import '../widgets/list_item_card.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';
import '../widgets/section_header.dart';
import '../widgets/swipe_action_wrapper.dart';
import '../models/list_item.dart';
import '../engine/sticky_header_engine.dart'; // IMPORT THE ENGINE

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late ScrollController _scrollController;
  final ValueNotifier<PhantomHeaderData> _phantomHeaderState = ValueNotifier(const PhantomHeaderData());

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _phantomHeaderState.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<ListProvider>();

    // CLEAN ARCHITECTURE: Ask the engine for the result, instead of doing math in the UI layer
    final newHeaderData = StickyHeaderEngine.calculatePhantomHeader(
      _scrollController.offset,
      provider.cumulativeYOffsets,
      provider.displayList,
    );

    // Only update the ValueNotifier if the data actually changed to prevent unnecessary rebuilds
    if (_phantomHeaderState.value.title != newHeaderData.title ||
        _phantomHeaderState.value.yOffset != newHeaderData.yOffset) {
      _phantomHeaderState.value = newHeaderData;
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        final width = MediaQuery.of(context).size.width;
        context.read<ListProvider>().updateViewportWidth(width);
      }
    });

    final listProvider = context.watch<ListProvider>();
    final displayList = listProvider.displayList;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        if (listProvider.openSwipeItemId.value != null) {
          listProvider.openSwipeItemId.value = null;
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          titleSpacing: AppConstants.horizontalPadding + AppConstants.leadingBlockWidth + AppConstants.interElementGap,
          title: const Text('Listicle V2 Prototype'),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: theme.textTheme.titleMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        body: displayList.isEmpty
            ? Center(child: Text('All caught up!', style: theme.textTheme.bodyMedium))
            : NotificationListener<ScrollStartNotification>(
          onNotification: (_) {
            if (listProvider.openSwipeItemId.value != null) {
              listProvider.openSwipeItemId.value = null;
            }
            return false;
          },
          // ==========================================
          // BATCH 3: THE PHANTOM HEADER UI STACK
          // ==========================================
          child: Stack(
            children: [
              // The main scrolling list
              ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 0.0, bottom: 120.0),
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final item = displayList[index];

                  if (item is String) {
                    return SectionHeader(
                      key: ValueKey('header_$item'),
                      title: item,
                    );
                  }

                  if (item is ListItem) {
                    return SwipeActionWrapper(
                      key: ValueKey('swipe_${item.id}'),
                      itemId: item.id,
                      requireConfirm: true,
                      onCheckout: () {
                        context.read<ListProvider>().toggleCompletion(item.id);
                      },
                      onEdit: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => EditItemBottomSheet(
                            item: item,
                            onSave: (newTitle, newAttributes) {
                              context.read<ListProvider>().editItem(item.id, newTitle, newAttributes);
                            },
                          ),
                        );
                      },
                      onDelete: () {
                        context.read<ListProvider>().deleteItem(item.id);
                      },
                      child: ListItemCard(
                        title: item.title,
                        nWrap: item.nWrap,
                        attributeRows: item.attributeRows,
                        onTap: () {
                          if (listProvider.openSwipeItemId.value != null) {
                            listProvider.openSwipeItemId.value = null;
                          } else {
                            listProvider.toggleCompletion(item.id);
                          }
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // The Math-Driven Phantom Header Overlay
              ValueListenableBuilder<PhantomHeaderData>(
                valueListenable: _phantomHeaderState,
                builder: (context, data, child) {
                  if (data.title == null) return const SizedBox.shrink();

                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    // GPU hardware acceleration for the floating header
                    child: RepaintBoundary(
                      child: Transform.translate(
                        offset: Offset(0, data.yOffset), // Pushes up natively when colliding
                        child: SectionHeader(title: data.title!),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
