// Location: lib/main.dart

import 'package:flutter/material.dart';
import 'package:listicle_v2/providers/macro_list_provider.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/list_provider.dart';
import 'providers/theme_provider.dart'; // <--- NEW
import 'screens/main_screen.dart';

// Note: Firebase core initialization will be added here in Phase 4.

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // <--- NEW
        ChangeNotifierProvider(create: (_) => MacroListProvider()),
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
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Listicle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Adapts to device settings automatically

      // NEW: Override the global text scaler based on user preference
      builder: (context, child) {
        if (!themeProvider.isInitialized) return const SizedBox.shrink();

        final mediaQuery = MediaQuery.of(context);
        // Multiply the device's native scale by our app's internal multiplier
        final customScaler = TextScaler.linear(
            mediaQuery.textScaler.scale(1.0) * themeProvider.textScaleMultiplier
        );

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: customScaler),
          child: child!,
        );
      },
      home: const MainScreen(),
    );
  }
}