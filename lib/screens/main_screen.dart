import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/item_form_modal.dart';
import '../components/main_options_sheet.dart';
import '../components/section_header.dart';
import '../models/list_item.dart';
import '../services/list_provider.dart';
import '../services/sticky_header_engine.dart'; // NEW IMPORT
import '../components/list_item_card.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart'; // NEW IMPORT

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ValueNotifier<String> _activeHeader = ValueNotifier<String>('');
  final Map<String, GlobalKey> _headerKeys = {};

  @override
  Widget build(BuildContext context) {
    final listProvider = context.watch<ListProvider>();
    final activeType = listProvider.activeType;
    final flatList = listProvider.groupedAndSortedItems;

    // Build header keys dynamically
    for (var row in flatList) {
      if (row is String) {
        _headerKeys.putIfAbsent(row, () => GlobalKey());
      }
    }

    for (var row in flatList) {
      if (row is String) {
        _headerKeys.putIfAbsent(row, () => GlobalKey(debugLabel: row));
      }
    }
    _headerKeys.removeWhere((key, _) => !flatList.contains(key));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true, snap: true, pinned: false,
              elevation: 0, centerTitle: true,
              backgroundColor: AppTheme.background,
              title: Text(activeType, style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),

            // The Sticky Pseudo-Header
            SliverPersistentHeader(
              pinned: true,
              delegate: _PseudoHeaderDelegate(_activeHeader, _headerKeys, flatList),
            ),

            SliverPadding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120, top: 8),
              sliver: SliverReorderableList(
                itemCount: flatList.length,
                itemBuilder: (context, index) {
                  final row = flatList[index];

                  if (row is String) {
                    return Container(
                      key: _headerKeys[row], // Track this header's position
                      child: SectionHeader(title: row),
                    );
                  }

                  return ReorderableDelayedDragStartListener(
                    key: ValueKey((row as ListItem).id),
                    index: index,
                    child: ListItemCard(item: row),
                  );
                },
                onReorder: (int oldIndex, int newIndex) { /* ... same as before ... */ },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PseudoHeaderDelegate extends SliverPersistentHeaderDelegate {
  final ValueNotifier<String> activeHeader;
  final Map<String, GlobalKey> headerKeys;
  final List<dynamic> flatList;

  _PseudoHeaderDelegate(this.activeHeader, this.headerKeys, this.flatList);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Logic: Find the highest header whose GlobalKey is at or above the top (or very close)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      String bestHeader = flatList.firstWhere((r) => r is String);

      for (var entry in headerKeys.entries) {
        final renderBox = entry.value.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final dy = renderBox.localToGlobal(Offset.zero).dy;
          // If the header is at or above the 60px sticky area, it's the active one
          if (dy <= 60) {
            bestHeader = entry.key;
          }
        }
      }
      if (activeHeader.value != bestHeader) activeHeader.value = bestHeader;
    });

    return ValueListenableBuilder<String>(
        valueListenable: activeHeader,
        builder: (context, header, child) {
          return Container(
            height: maxExtent, width: double.infinity,
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.only(left: 32.0, right: 16.0, bottom: 8.0),
            decoration: const BoxDecoration(color: AppTheme.background),
            child: Text(header, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: 1.0)),
          );
        }
    );
  }

  @override
  double get maxExtent => 56.0;
  @override
  double get minExtent => 56.0;
  @override
  bool shouldRebuild(covariant _PseudoHeaderDelegate oldDelegate) => true;
}
