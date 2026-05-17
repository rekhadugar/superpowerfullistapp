import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/list_item.dart';
import '../services/list_provider.dart';
import '../components/list_item_card.dart';
import '../components/section_header.dart'; // We can reuse your beautiful headers!
import '../theme/app_theme.dart';

class CompletedItemsScreen extends StatelessWidget {
  const CompletedItemsScreen({super.key});

  // Helper function to safely extract a DateTime object from Firestore Timestamp or Native DateTime
  DateTime _extractDate(ListItem item) {
    try {
      // Assuming your model stores it as a Firestore Timestamp
      return (item as dynamic).updatedAt.toDate();
    } catch (_) {
      try {
        // Fallback if it's already a DateTime object
        return (item as dynamic).updatedAt as DateTime;
      } catch (_) {
        return DateTime.now(); // Failsafe
      }
    }
  }

  // The Time Grouping Engine
  String _getTimeGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(itemDate).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff > 1 && diff <= 7) return 'This Week';
    if (now.year == date.year && now.month == date.month) return 'This Month';
    if (now.year == date.year) return 'This Year';
    return 'A Long Time Ago';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListProvider>();

    // 1. Get completed items and sort them newest to oldest
    final List<ListItem> completedItems = provider.items
        .where((item) => item.isCompleted && !item.isDeleted)
        .toList();

    completedItems.sort((a, b) {
      final dateA = _extractDate(a);
      final dateB = _extractDate(b);
      return dateB.compareTo(dateA); // Descending order
    });

    // 2. Flatten into an array of Strings (Headers) and ListItems (Cards)
    final List<dynamic> flatList = [];
    String currentGroup = '';

    for (var item in completedItems) {
      String timeGroup = _getTimeGroup(_extractDate(item));

      if (timeGroup != currentGroup) {
        flatList.add(timeGroup.toUpperCase());
        currentGroup = timeGroup;
      }
      flatList.add(item);
    }

    // Helper to count items per time group
    int getGroupCount(String group) {
      return completedItems.where((item) {
        return _getTimeGroup(_extractDate(item)).toUpperCase() == group;
      }).length;
    }

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
            else
              SliverPadding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40, top: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final row = flatList[index];

                      if (row is String) {
                        return SectionHeader(title: row, itemCount: getGroupCount(row));
                      }

                      // Pass isCompact: true to render the minimal version!
                      return ListItemCard(item: row as ListItem, isCompact: true);
                    },
                    childCount: flatList.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}