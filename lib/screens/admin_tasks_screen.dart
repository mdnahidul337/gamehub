import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../services/db_service.dart';

class AdminTasksScreen extends StatefulWidget {
  const AdminTasksScreen({super.key});

  @override
  State<AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends State<AdminTasksScreen> {
  final DBService _db = DBService();
  late Future<List<TaskItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _db.listTasks();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _db.listTasks();
    });
  }

  Future<void> _showEditDialog({TaskItem? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final pointsCtrl = TextEditingController(text: '${existing?.points ?? 0}');
    final thumbCtrl = TextEditingController(text: existing?.thumbnailUrl ?? '');
    final urlCtrl = TextEditingController(text: existing?.taskUrl ?? '');

    final formKey = GlobalKey<FormState>();

    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Task' : 'Edit Task'),
        content: SingleChildScrollView(
          child: Form(
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
                TextFormField(
                  controller: pointsCtrl,
                  decoration: const InputDecoration(labelText: 'Points'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final i = int.tryParse(v);
                    if (i == null || i < 0) return 'Invalid';
                    return null;
                  },
                ),
                TextFormField(
                  controller: thumbCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Thumbnail URL (optional)'),
                ),
                TextFormField(
                  controller: urlCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Task URL (optional)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final t = TaskItem(
                id: existing?.id,
                title: titleCtrl.text.trim(),
                description: descCtrl.text.trim(),
                points: int.parse(pointsCtrl.text.trim()),
                thumbnailUrl: thumbCtrl.text.trim().isEmpty
                    ? null
                    : thumbCtrl.text.trim(),
                taskUrl:
                    urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
              );
              try {
                if (existing == null) {
                  await _db.createTask(t);
                } else {
                  await _db.updateTask(existing.id!, t);
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
      appBar: AppBar(title: const Text('Admin - Tasks')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showEditDialog(),
      ),
      body: FutureBuilder<List<TaskItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          final items = snap.data ?? [];
          if (items.isEmpty) return Center(child: Text('No tasks yet.'));
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final t = items[i];
                return ListTile(
                  title: Text(t.title),
                  subtitle: Text('${t.points} pts • ${t.description}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        await _showEditDialog(existing: t);
                      } else if (v == 'delete') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Task'),
                            content: Text('Delete "${t.title}"?'),
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
                          await _db.deleteTask(t.id!);
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
