// Location: lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/list_provider.dart';
import 'screens/main_screen.dart';
// Note: Firebase core initialization will be added here in Phase 4.

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ListProvider()),
      ],
      child: const ListicleApp(),
    ),
  );
}

class ListicleApp extends StatelessWidget {
  const ListicleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Listicle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Adapts to device settings automatically
      home: const MainScreen(),
    );
  }
}