import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/list_provider.dart';
import '../components/list_item_card.dart';
import '../theme/app_theme.dart';

class CompletedItemsScreen extends StatelessWidget {
  const CompletedItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListProvider>();

    // Filter items to show ONLY completed items that are not deleted
    final completedItems = provider.items
        .where((item) => item.isCompleted && !item.isDeleted)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: true,
              elevation: 0,
              backgroundColor: AppTheme.background,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Checked Items',
                style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),

            // Empty State
            if (completedItems.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.playlist_add_check, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No checked items yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              )
            // Populated State
            else
              SliverPadding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40, top: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      return ListItemCard(item: completedItems[index]);
                    },
                    childCount: completedItems.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}