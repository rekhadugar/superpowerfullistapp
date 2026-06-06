import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/dictionary_uploader.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Local state for interactive mock switches
  bool _hapticEnabled = true;
  bool _badgeEnabled = false;
  bool _compactLayout = false;

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming in a future update!', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryAction,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        // FIXED: Removed the leading IconButton and prevented Flutter from adding one automatically
        automaticallyImplyLeading: false,
        title: Text(
          'Settings',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 48),
        children: [
          _buildSectionHeader(theme, 'PROFILE SETTINGS'),
          _buildCardGroup(
            theme: theme,
            children: [
              _buildProfileCard(theme),
              const Divider(height: 1, indent: 56),
              _buildActionTile(theme, icon: Icons.cloud_sync_outlined, title: 'Cloud Sync', onTap: () => _showComingSoon('Cloud Sync')),
              const Divider(height: 1, indent: 56),
              _buildActionTile(theme, icon: Icons.download_outlined, title: 'Export Data', onTap: () => _showComingSoon('Data Export')),
              const Divider(height: 1, indent: 56),
              _buildActionTile(theme, icon: Icons.logout_rounded, title: 'Sign Out', color: AppColors.destructiveAction, onTap: () => _showComingSoon('Authentication')),
            ],
          ),

          const SizedBox(height: 64),
          // --- TEMPORARY DATABASE UPLOADER ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text('UPLOAD GLOBAL DICTIONARY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Upload started! Check terminal logs.')),
                );
                await DictionaryUploader.uploadDictionary();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Upload Complete! 🎉')),
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          const SizedBox(height: 24),
          _buildSectionHeader(theme, 'APP SETTINGS'),
          _buildCardGroup(
            theme: theme,
            children: [
              _buildActionTile(theme, icon: Icons.dark_mode_outlined, title: 'Appearance', trailingText: 'System', onTap: () => _showComingSoon('Theme Engine')),
              const Divider(height: 1, indent: 56),
              _buildSwitchTile(theme, icon: Icons.vibration_rounded, title: 'Haptic Feedback', value: _hapticEnabled, onChanged: (v) => setState(() => _hapticEnabled = v)),
              const Divider(height: 1, indent: 56),
              _buildSwitchTile(theme, icon: Icons.looks_3_outlined, title: 'App Icon Badge', value: _badgeEnabled, onChanged: (v) => setState(() => _badgeEnabled = v)),
              const Divider(height: 1, indent: 56),
              _buildActionTile(theme, icon: Icons.notifications_none_rounded, title: 'Notifications', onTap: () => _showComingSoon('Notifications')),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(theme, 'LIST SETTINGS'),
          _buildCardGroup(
            theme: theme,
            children: [
              _buildActionTile(theme, icon: Icons.library_books_outlined, title: 'Manage Smart Dictionary', onTap: () => _showComingSoon('Dictionary Manager')),
              const Divider(height: 1, indent: 56),
              _buildActionTile(theme, icon: Icons.sort_rounded, title: 'Default Sort Mode', trailingText: 'By Store', onTap: () => _showComingSoon('Global Sort Options')),
              const Divider(height: 1, indent: 56),
              _buildActionTile(theme, icon: Icons.cleaning_services_outlined, title: 'Completed Items', trailingText: 'Hide in 24h', onTap: () => _showComingSoon('Completion Behavior')),
              const Divider(height: 1, indent: 56),
              _buildSwitchTile(theme, icon: Icons.compress_rounded, title: 'Compact List Layout', value: _compactLayout, onChanged: (v) => setState(() => _compactLayout = v)),
              const Divider(height: 1, indent: 56),
              _buildActionTile(theme, icon: Icons.flash_on_rounded, title: 'Quick Add Defaults', onTap: () => _showComingSoon('Quick Add Defaults')),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(theme, 'LEGAL'),
          _buildCardGroup(
            theme: theme,
            children: [
              _buildActionTile(theme, icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () => _showComingSoon('Privacy Policy')),
              const Divider(height: 1, indent: 56),
              _buildActionTile(theme, icon: Icons.gavel_rounded, title: 'Terms of Service', onTap: () => _showComingSoon('Terms of Service')),
              const Divider(height: 1, indent: 56),
              _buildActionTile(theme, icon: Icons.code_rounded, title: 'Open Source Licenses', onTap: () => _showComingSoon('OS Licenses')),
            ],
          ),

          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Text(
                  'Listille',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.hintColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 2.2.0',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.hintColor.withValues(alpha: 0.8),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCardGroup({required ThemeData theme, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme) {
    return InkWell(
      onTap: () => _showComingSoon('Account Management'),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryAction.withValues(alpha: 0.15),
              child: const Text(
                'D',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryAction),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dhiraj Dugar',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'dhiraj.dugar@email.com',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.dividerColor),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(ThemeData theme, {required IconData icon, required String title, String? trailingText, Color? color, required VoidCallback onTap}) {
    final itemColor = color ?? theme.textTheme.bodyLarge?.color;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: color ?? theme.hintColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: itemColor,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right_rounded, color: theme.dividerColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(ThemeData theme, {required IconData icon, required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: theme.hintColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryAction,
          ),
        ],
      ),
    );
  }
}