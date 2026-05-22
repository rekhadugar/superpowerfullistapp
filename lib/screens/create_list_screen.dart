import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/list_type.dart';
import '../providers/macro_list_provider.dart';

class CreateListScreen extends StatefulWidget {
  const CreateListScreen({Key? key}) : super(key: key);

  @override
  State<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final _formKey = GlobalKey<FormState>();
  String _listName = '';
  ListType _selectedType = ListType.shopping;

  void _saveList() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      context.read<MacroListProvider>().createNewList(_listName, _selectedType);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
              DropdownButtonFormField<ListType>(
                value: _selectedType,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: ListType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(type.icon, size: 20),
                        const SizedBox(width: 12),
                        Text(type.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
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