import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_list_type.dart';
import '../providers/macro_list_provider.dart';
import '../providers/settings_provider.dart';

class CreateListScreen extends StatefulWidget {
  final bool isFirstLaunch;

  const CreateListScreen({Key? key, this.isFirstLaunch = false}) : super(key: key);

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
                value: _selectedTypeId,
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
              const SizedBox(height: 24),
              const Text('List Name', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                autofocus: true,
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