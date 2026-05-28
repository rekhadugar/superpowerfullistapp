import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/macro_list_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class CreateListScreen extends StatefulWidget {
  final bool isFirstLaunch;

  const CreateListScreen({super.key, this.isFirstLaunch = false});

  @override
  State<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final _formKey = GlobalKey<FormState>();
  String _listName = '';
  String? _selectedTypeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      if (settings.allTypes.isNotEmpty) {
        setState(() => _selectedTypeId = settings.allTypes.first.id);
      }
    });
  }

  void _saveList() async {
    if (_formKey.currentState!.validate() && _selectedTypeId != null) {
      _formKey.currentState!.save();
      context.read<MacroListProvider>().addList(_listName, _selectedTypeId!);

      if (!widget.isFirstLaunch) {
        if (mounted) Navigator.pop(context);
      }
    }
  }

  void _showCreateCustomTypeSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final axis1Ctrl = TextEditingController();
    final axis2Ctrl = TextEditingController();
    final settings = context.read<SettingsProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 24, left: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Custom Type', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Type Name (e.g., Wine Collection)', border: OutlineInputBorder())
            ),
            const SizedBox(height: 16),
            TextField(
                controller: axis1Ctrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Primary Group (e.g., Region)', border: OutlineInputBorder())
            ),
            const SizedBox(height: 16),
            TextField(
                controller: axis2Ctrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Secondary Group (e.g., Varietal)', border: OutlineInputBorder())
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAction,
                    padding: const EdgeInsets.symmetric(vertical: 16)
                ),
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty && axis1Ctrl.text.isNotEmpty && axis2Ctrl.text.isNotEmpty) {
                    settings.createCustomType(nameCtrl.text, axis1Ctrl.text, axis2Ctrl.text);

                    // Auto-select the newly created type in the dropdown
                    setState(() {
                      _selectedTypeId = settings.allTypes.last.id;
                    });

                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Create Type', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isFirstLaunch,
        title: const Text('New List'),
        actions: [
          TextButton(
            onPressed: _saveList,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('List Type', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedTypeId,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: settings.allTypes.map((type) {
                  return DropdownMenuItem(
                    value: type.id,
                    child: Row(
                      children: [
                        Icon(IconData(type.iconCodePoint, fontFamily: 'MaterialIcons'), size: 20),
                        const SizedBox(width: 12),
                        Text(type.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTypeId = val);
                },
              ),

              // NEW: Quick access to create a brand new taxonomy
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('New Custom Type'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primaryAction),
                  onPressed: () => _showCreateCustomTypeSheet(context),
                ),
              ),

              const SizedBox(height: 16),
              const Text('List Name', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Weekend Groceries',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter a list name'
                    : null,
                onSaved: (value) => _listName = value!,
              ),
            ],
          ),
        ),
      ),
    );
  }
}