import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DictionaryUploader {
  static Future<void> uploadDictionary() async {
    try {
      print('1. Loading JSON from assets...');
      final String jsonString = await rootBundle.loadString('assets/data/clean_global_dictionary.json');
      final List<dynamic> items = jsonDecode(jsonString);

      final firestore = FirebaseFirestore.instance;
      final collection = firestore.collection('global_dictionary');

      print('2. Chunking ${items.length} items into batches of 500...');
      const int batchSize = 500;

      for (int i = 0; i < items.length; i += batchSize) {
        final batch = firestore.batch();
        final end = (i + batchSize < items.length) ? i + batchSize : items.length;
        final chunk = items.sublist(i, end);

        for (var item in chunk) {
          final title = item['title'].toString();

          // We use auto-generated document IDs and store a lowercase 'searchTitle'
          // because Firestore does not support case-insensitive searching natively.
          final docRef = collection.doc();
          batch.set(docRef, {
            'title': title,
            'searchTitle': title.toLowerCase(),
            'category': item['category'],
            'defaultUnit': item['defaultUnit'],
            'stores': ['Any'], // Initialize the stores array
          });
        }

        await batch.commit();
        print('✅ Uploaded batch ${(i / batchSize).floor() + 1} of ${(items.length / batchSize).ceil()}');
      }

      print('🎉 COMPLETE: All items successfully uploaded to Firestore!');

    } catch (e) {
      print('❌ Error during upload: $e');
    }
  }
}