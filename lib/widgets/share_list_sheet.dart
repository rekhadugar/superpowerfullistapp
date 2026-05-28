import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import '../models/macro_list.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart'; // Adjust if your theme import is different

class ShareListSheet extends StatefulWidget {
  final MacroList targetList;

  const ShareListSheet({super.key, required this.targetList});

  /// Helper method to easily launch this sheet from anywhere
  static void show(BuildContext context, MacroList list) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareListSheet(targetList: list),
    );
  }

  @override
  State<ShareListSheet> createState() => _ShareListSheetState();
}

class _ShareListSheetState extends State<ShareListSheet> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _userNotFound = false;

  Future<void> _handleInvite() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) return;

    setState(() {
      _isLoading = true;
      _userNotFound = false;
    });

    try {
      // 1. Search for the user in the database
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // SCENARIO A: USER FOUND! Send In-App Invite
        final targetUserId = querySnapshot.docs.first.id;

        // Don't let users invite themselves
        if (targetUserId == AuthService.currentUserId) {
           _showSnack('You cannot invite yourself!');
           setState(() => _isLoading = false);
           return;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .collection('invitations')
            .add({
          'listId': widget.targetList.id,
          'listName': widget.targetList.name,
          'invitedBy': AuthService.currentUserId,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.pop(context);
          _showSnack('Invite sent to $email!');
        }
      } else {
        // SCENARIO B: USER NOT FOUND. Show the viral fallback.
        setState(() => _userNotFound = true);
      }
    } catch (e) {
      _showSnack('Error sending invite: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _triggerNativeShare() {
    // Step 3 will convert this into a real clickable Deep Link
    final inviteLink = 'https://listicle.app/join/${widget.targetList.id}';

    Share.share(
      'Join my list "${widget.targetList.name}" on Listicle! $inviteLink',
      subject: 'Listicle Invitation',
    );

    Navigator.pop(context);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Handles the keyboard pushing the sheet up
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 24 + bottomInset),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Share List',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Invite someone to edit "${widget.targetList.name}" with you.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // The Email Input
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Enter email address',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: theme.cardColor,
            ),
            onSubmitted: (_) => _handleInvite(),
          ),
          const SizedBox(height: 16),

          // Dynamic Button State
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_userNotFound) ...[
            // The Fallback UI
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Text(
                'User not found. They might not have an account yet!',
                style: TextStyle(color: Colors.deepOrange),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.ios_share),
              label: const Text('Share via SMS / WhatsApp'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primaryAction,
                foregroundColor: Colors.white,
              ),
              onPressed: _triggerNativeShare,
            ),
          ] else
            // The Standard Invite Button
            ElevatedButton(
              onPressed: _handleInvite,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primaryAction,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Invite', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}