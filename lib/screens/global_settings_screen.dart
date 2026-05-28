import 'package:flutter/material.dart';
import 'package:listicle_v2/screens/sign_in_screen.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';
import '../services/auth_service.dart';

class GlobalSettingsScreen extends StatelessWidget {
  const GlobalSettingsScreen({super.key});

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryAction.withValues(alpha: 0.8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        // FIXED: Only render the back button if we navigated here via the Drawer.
        // If accessed via the Bottom Tab, it gracefully hides to prevent black-screen crashes.
        leading: Navigator.canPop(context)
            ? IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textTheme.titleMedium?.color),
          onPressed: () => Navigator.pop(context),
        )
            : null,
        title: Text('Settings', style: theme.textTheme.titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // --- ACCOUNT SECTION ---
          _buildSectionHeader('Account', theme),
          const GoogleAccountLinkTile(),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1),

          const SizedBox(height: 8),

          // --- ORGANIZATION SECTION ---
          _buildSectionHeader('Data & Organization', theme),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primaryAction.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.tune_rounded, color: AppColors.primaryAction),
            ),
            title: const Text('Organize Lists', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Manage taxonomies, groups, and sorting'),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1),

          // --- APPEARANCE SECTION ---
          const SizedBox(height: 8),
          _buildSectionHeader('Appearance', theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // FIXED: Wrapped in Expanded to prevent right-side overflow on large scales
                    const Expanded(
                      child: Text(
                        'Global App Scale',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('${(themeProvider.textScaleMultiplier * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryAction)),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: themeProvider.textScaleMultiplier,
                  min: 0.5,
                  max: 1.5, // FIXED: Capped max at 1.5
                  divisions: 10, // Smoother stepping for the smaller range
                  activeColor: AppColors.primaryAction,
                  inactiveColor: AppColors.primaryAction.withValues(alpha: 0.2),
                  onChanged: (val) => themeProvider.setFluidScale(val),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('Adjusts text, margins, and component geometry globally.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1),

          // --- ABOUT SECTION ---
          const SizedBox(height: 8),
          _buildSectionHeader('About', theme),
          const ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 20),
            leading: Icon(Icons.info_outline_rounded, color: Colors.grey),
            title: Text('Version', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('2.2.0 (Fluid UI Beta)'),
          ),
        ],
      ),
    );
  }
}

// --- SELF MANAGING ACCOUNT LINK TILE ---
class GoogleAccountLinkTile extends StatefulWidget {
  const GoogleAccountLinkTile({super.key});

  @override
  State<GoogleAccountLinkTile> createState() => _GoogleAccountLinkTileState();
}

class _GoogleAccountLinkTileState extends State<GoogleAccountLinkTile> {
  bool _isLoading = false;

  Future<void> _linkAccount() async {
    setState(() => _isLoading = true);
    final user = await AuthService.signInWithGoogle();

    if (mounted) {
      setState(() => _isLoading = false); // Stop the spinner

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account successfully secured!')),
        );
      } else {
        // If it returns null, it failed (usually because the Google account is already used)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to link. That Google account may already be tied to another user.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    await AuthService.signOut();

    if (mounted) {
      // Wipe the navigation stack and send them back to the brand new Sign-In Screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAnon = AuthService.isAnonymous;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: const Icon(Icons.account_circle, size: 36, color: AppColors.primaryAction),
      title: Text(isAnon ? 'Link Google Account' : 'Google Account Linked', style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(isAnon ? 'Secure your lists in the cloud' : 'Your data is safely backed up'),
      trailing: _isLoading
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          : isAnon
          ? TextButton(
        onPressed: _linkAccount,
        child: const Text('Link', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryAction)),
      )
          : TextButton(
        onPressed: _signOut,
        child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
      ),
    );
  }
}