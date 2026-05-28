import 'package:flutter/material.dart';
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textTheme.titleMedium?.color),
          onPressed: () => Navigator.pop(context),
        ),
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
                const Text('App Font Size', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12.0,
                  children: AppFontSize.values.map((size) {
                    final isSelected = themeProvider.fontSize == size;
                    return ChoiceChip(
                      label: Text(size.name.toUpperCase()),
                      selected: isSelected,
                      selectedColor: AppColors.primaryAction.withValues(alpha: 0.15),
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primaryAction : theme.textTheme.bodyMedium?.color,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) => themeProvider.setFontSize(size),
                    );
                  }).toList(),
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
            subtitle: Text('1.0.0 (Beta)'),
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

    if (user != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account successfully secured!')),
      );
    }
    if (mounted) {
      setState(() => _isLoading = false);
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
          : const Icon(Icons.check_circle, color: AppColors.successAction),
    );
  }
}