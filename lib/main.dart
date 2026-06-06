// Location: lib/main.dart

import 'package:flutter/material.dart';
import 'package:listicle_v2/providers/macro_list_provider.dart';
import 'package:listicle_v2/providers/settings_provider.dart';
import 'package:listicle_v2/screens/root_navigation_screen.dart';
import 'package:listicle_v2/services/migration_service.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/list_provider.dart';
import 'providers/theme_provider.dart';

// Firebase Foundation Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/sign_in_screen.dart'; // NEW: Import the sign in screen
import 'services/dictionary_service.dart'; // NEW IMPORT

void main() async {
  // Ensure Flutter engine is fully bound before calling native code
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  DictionaryService.initialize();

  // 2. Enable Firestore Native Offline Persistence (The Local-First Magic)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // 3. Removed the forced silent auth engine so new users see the sign-in screen
  // await AuthService.signInAnonymouslySilently();

  // 4. Run Data Migration (Only runs once if old local data exists)
  await MigrationService.runLocalToCloudMigration();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MacroListProvider()),
        ChangeNotifierProvider(create: (_) => ListProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const ListicleApp(),
    ),
  );
}

class ListicleApp extends StatelessWidget {
  const ListicleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Listicle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Adapts to device settings automatically

      // Override the global text scaler based on user preference
      builder: (context, child) {
        if (!themeProvider.isInitialized) return const SizedBox.shrink();

        final mediaQuery = MediaQuery.of(context);

        // FIXED: Strictly override OS scaling to prevent unpredictable spatial math.
        // We do not multiply against the native device scale anymore.
        final customScaler = TextScaler.linear(themeProvider.textScaleMultiplier);

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: customScaler),
          child: child!,
        );
      },
      // ROUTING LOGIC: Direct to SignIn if no user is found
      home: AuthService.currentUserId == null
          ? const SignInScreen()
          : const RootNavigationScreen(),
    );
  }
}