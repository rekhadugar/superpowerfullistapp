import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart'; // This is our Organize Lists Hub

class GlobalSettingsScreen extends StatelessWidget {
  const GlobalSettingsScreen({Key? key}) : super(key: key);

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryAction.withOpacity(0.8),
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

          // --- ORGANIZATION SECTION ---
          _buildSectionHeader('Data & Organization', theme),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primaryAction.withOpacity(0.1), shape: BoxShape.circle),
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
                      selectedColor: AppColors.primaryAction.withOpacity(0.15),
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

          // --- ABOUT SECTION (Future Proofing) ---
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