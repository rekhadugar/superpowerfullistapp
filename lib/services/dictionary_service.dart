import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../data/mock_global_dictionary.dart';

class DictionaryService {
  // SHIELD 3: The Local Memory Cache
  static List<SmartItem> _inMemoryDictionary = [];
  static bool _isInitialized = false;

  /// Call this once when the app starts
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Find the safe local directory for this device
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/clean_global_dictionary.json');

      // If the file isn't on the phone, download it from Cloud Storage
      if (!await file.exists()) {
        print('Downloading dictionary from Cloud Storage...');
        final ref = FirebaseStorage.instance.ref().child('dictionaries/clean_global_dictionary.json');
        await ref.writeToFile(file);
        print('Download complete!');
      } else {
        print('Dictionary found on device.');
      }

      // Load the file from local storage into RAM
      final jsonString = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(jsonString);

      _inMemoryDictionary = jsonData.map((data) {
        return SmartItem(
          title: data['title'] ?? '',
          category: data['category'] ?? 'Other',
          store: 'Any', // The global list doesn't strictly dictate the user's local store
          unit: data['defaultUnit'] ?? 'pcs',
          tags: [],
        );
      }).toList();

      _isInitialized = true;
      print('Dictionary loaded into RAM: ${_inMemoryDictionary.length} items.');

    } catch (e) {
      print('Error initializing dictionary: $e');
    }
  }

  /// Synchronous, instant search from RAM
  static List<SmartItem> searchItems(String query) {
    if (!_isInitialized) return [];

    final q = query.trim().toLowerCase();

    // SHIELD 1: Character Threshold
    if (q.length < 3) return [];

    // Filter the RAM array instantly
    return _inMemoryDictionary
        .where((item) => item.title.toLowerCase().startsWith(q))
        .take(8) // Limit to 8 to keep the UI clean
        .toList();
  }
}