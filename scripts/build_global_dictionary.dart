import 'dart:convert';
import 'dart:io';

void main() async {
  final categoryFile = File('scripts/data_source/food_category.csv');
  final foodFile = File('scripts/data_source/food.csv');

  if (!await categoryFile.exists() || !await foodFile.exists()) {
    print('❌ Missing CSV files. Ensure food.csv and food_category.csv are in scripts/data_source/');
    return;
  }

  print('1. Loading Category Map...');
  final categoryLines = await categoryFile.readAsLines();

  Map<String, String> categoryMap = {};
  for (int i = 1; i < categoryLines.length; i++) {
    // Basic CSV split
    final row = categoryLines[i].split('","');
    // FIXED: Ensure we have at least 3 columns and grab the 3rd column (index 2) for the text description!
    if (row.length >= 3) {
      final id = row[0].replaceAll('"', '').trim();
      final description = row[2].replaceAll('"', '').trim();
      categoryMap[id] = description;
    }
  }

  print('2. Reading Food Items and Joining Categories...');
  final foodLines = await foodFile.readAsLines();
  List<Map<String, dynamic>> dictionary = [];

  for (int i = 1; i < foodLines.length; i++) {
    final row = foodLines[i].split('","');

    if (row.length >= 4) {
      final rawTitle = row[2].replaceAll('"', '').trim();
      final categoryId = row[3].replaceAll('"', '').trim();

      final cleanTitle = rawTitle.split(',').first.trim();

      final categoryName = categoryMap[categoryId] ?? 'Other';

      if (cleanTitle.toLowerCase() != 'water' && cleanTitle.isNotEmpty) {
        dictionary.add({
          'title': cleanTitle,
          'category': categoryName,
          'defaultUnit': 'pcs',
        });
      }
    }
  }

  final uniqueDictionary = dictionary.toSet().toList();

  print('3. Saving to JSON...');
  final outputFile = File('scripts/clean_global_dictionary.json');
  await outputFile.writeAsString(const JsonEncoder.withIndent('  ').convert(uniqueDictionary));

  print('✅ Success! Converted ${uniqueDictionary.length} items with real USDA categories.');
}