// Location: lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/list_provider.dart';
import '../widgets/edit_item_bottom_sheet.dart';
import '../widgets/list_item_card.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';
import '../widgets/section_header.dart';
import '../widgets/swipe_action_wrapper.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // NEW: Pass viewport width to the provider for strict layout math
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        final width = MediaQuery.of(context).size.width;
        context.read<ListProvider>().updateViewportWidth(width);
      }
    });

    final listProvider = context.watch<ListProvider>();
    final activeItems = listProvider.activeItems;
    final theme = Theme.of(context);

    return Scaffold(
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
      body: activeItems.isEmpty
          ? Center(child: Text('All caught up!', style: theme.textTheme.bodyMedium))
          : ListView.builder(
        padding: const EdgeInsets.only(top: 0.0, bottom: 120.0), // Removed top padding to sit flush
        itemCount: activeItems.length + 1, // +1 for the static header
        itemBuilder: (context, index) {
          if (index == 0) {
            return const SectionHeader(title: 'Hardware Store');
          }

          final item = activeItems[index - 1];

          return SwipeActionWrapper(
            key: ValueKey('swipe_${item.id}'),
            itemId: item.id,
            onEdit: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent, // Allows our custom rounded corners to show
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
                context.read<ListProvider>().toggleCompletion(item.id);
              },
            ),
          );
        },
      ),
    );
  }
}