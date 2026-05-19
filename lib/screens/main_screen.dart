// Location: lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/list_provider.dart';
import '../widgets/list_item_card.dart';
import '../theme/app_theme.dart';

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
        padding: const EdgeInsets.only(top: 8.0, bottom: 120.0),
        itemCount: activeItems.length,
        itemBuilder: (context, index) {
          final item = activeItems[index];

          return ListItemCard(
            key: ValueKey(item.id),
            title: item.title,
            nWrap: item.nWrap, // Now dynamically driven by the state engine
            attributeRows: item.attributeRows,
            onTap: () {
              context.read<ListProvider>().toggleCompletion(item.id);
            },
          );
        },
      ),
    );
  }
}