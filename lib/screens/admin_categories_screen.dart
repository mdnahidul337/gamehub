import 'package:flutter/material.dart';

import '../services/db_service.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final DBService _db = DBService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _db.listCategoryItems();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _db.listCategoryItems();
    });
  }

  Future<void> _showEditDialog({Map<String, dynamic>? existing}) async {
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final descCtrl =
        TextEditingController(text: existing?['description'] ?? '');
    final formKey = GlobalKey<FormState>();
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Category' : 'Edit Category'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final m = {
                'title': titleCtrl.text.trim(),
                'description': descCtrl.text.trim()
              };
              try {
                if (existing == null) {
                  await _db.createCategory(m);
                } else {
                  await _db.updateCategory(existing['id'], m);
                }
                Navigator.of(context).pop(true);
              } catch (e) {
                Navigator.of(context).pop(false);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (res == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin - Categories')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showEditDialog(),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          final items = snap.data ?? [];
          if (items.isEmpty)
            return const Center(child: Text('No categories yet.'));
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final c = items[i];
                return ListTile(
                  title: Text(c['title'] ?? ''),
                  subtitle: Text(c['description'] ?? ''),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        await _showEditDialog(existing: c);
                      } else if (v == 'delete') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Category'),
                            content: Text('Delete "${c['title']}"?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel')),
                              ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await _db.deleteCategory(c['id']);
                          _refresh();
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
