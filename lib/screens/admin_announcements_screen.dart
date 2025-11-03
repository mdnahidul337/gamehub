import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/db_service.dart';
import '../services/storage_service.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final DBService _db = DBService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _db.listAnnouncements();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _db.listAnnouncements();
    });
  }

  Future<void> _showEditDialog({Map<String, dynamic>? existing}) async {
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final bodyCtrl = TextEditingController(text: existing?['body'] ?? '');
    final imageCtrl = TextEditingController(text: existing?['imageUrl'] ?? '');
    final formKey = GlobalKey<FormState>();
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:
            Text(existing == null ? 'Add Announcement' : 'Edit Announcement'),
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
                controller: bodyCtrl,
                decoration: const InputDecoration(labelText: 'Body'),
                maxLines: 3,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: imageCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Image URL (optional)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Pick'),
                    onPressed: () async {
                      // pick an image and upload to storage
                      try {
                        final res = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                          allowMultiple: false,
                        );
                        if (res == null || res.files.isEmpty) return;
                        final p = res.files.first.path;
                        if (p == null) return;
                        final file = File(p);
                        final ss = StorageService();
                        final url =
                            await ss.uploadFile(file, folder: 'announcements');
                        imageCtrl.text = url;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Image uploaded')));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Upload failed: $e')));
                      }
                    },
                  )
                ],
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
                'body': bodyCtrl.text.trim(),
                'imageUrl': imageCtrl.text.trim().isEmpty
                    ? null
                    : imageCtrl.text.trim(),
                'ts': DateTime.now().millisecondsSinceEpoch,
              };
              try {
                if (existing == null) {
                  await _db.createAnnouncement(m);
                } else {
                  await _db.updateAnnouncement(existing['id'], m);
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
      appBar: AppBar(title: const Text('Admin - Announcements')),
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
            return const Center(child: Text('No announcements yet.'));
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final a = items[i];
                return ListTile(
                  title: Text(a['title'] ?? ''),
                  subtitle: Text(a['body'] ?? ''),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        await _showEditDialog(existing: a);
                      } else if (v == 'delete') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Announcement'),
                            content: Text('Delete "${a['title']}"?'),
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
                          await _db.deleteAnnouncement(a['id']);
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
