import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import '../models/macro_list.dart';
import '../models/list_item.dart';

class MigrationService {
  static Future<void> runLocalToCloudMigration() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final listsJson = prefs.getString('macro_lists');

    if (listsJson == null) return; // No legacy data found, skip migration.

    print('DEBUG: Legacy local data found. Commencing Firestore migration...');
    final List<dynamic> decodedLists = jsonDecode(listsJson);
    final firestore = FirebaseFirestore.instance;
    final userDoc = firestore.collection('users').doc(uid);

    for (var map in decodedLists) {
      final list = MacroList.fromMap(map);

      // 1. Migrate the MacroList document
      await userDoc.collection('lists').doc(list.id).set(list.toMap());

      // 2. Migrate its respective items into the new subcollection
      final itemsJson = prefs.getString('items_${list.id}');
      if (itemsJson != null) {
        final List<dynamic> decodedItems = jsonDecode(itemsJson);
        for (var itemMap in decodedItems) {
          final item = ListItem.fromMap(itemMap);
          await userDoc.collection('lists').doc(list.id).collection('items').doc(item.id).set(item.toMap());
        }
        // Wipe the local items cache so it's not migrated twice
        await prefs.remove('items_${list.id}');
        await prefs.remove('last_purge_date_${list.id}');
      }
    }

    // Wipe the master list cache
    await prefs.remove('macro_lists');
    print('DEBUG: Migration Complete! All local data successfully pushed to Firestore.');
  }
}