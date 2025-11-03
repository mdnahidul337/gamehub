import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/mod_item.dart';
import '../services/db_service.dart';
import '../services/storage_service.dart';
import 'package:uuid/uuid.dart';

class AdminModEdit extends StatefulWidget {
  final ModItem? mod;
  const AdminModEdit({super.key, this.mod});

  @override
  State<AdminModEdit> createState() => _AdminModEditState();
}

class _AdminModEditState extends State<AdminModEdit> {
  final _form = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _fileUrlCtrl = TextEditingController();
  final _screenshots = <TextEditingController>[];
  String _status = 'published';
  bool _unlisted = false;
  final DBService _db = DBService();
  final StorageService _storage = StorageService();
  final Uuid _uuid = const Uuid();
  bool _uploadingFile = false;
  bool _uploadingScreens = false;

  @override
  void initState() {
    super.initState();
    if (widget.mod != null) {
      final m = widget.mod!;
      _titleCtrl.text = m.title;
      _aboutCtrl.text = m.about;
      _categoryCtrl.text = m.category;
      _priceCtrl.text = '${m.price}';
      _fileUrlCtrl.text = m.fileUrl ?? '';
      _status = m.status;
      _unlisted = m.unlisted;
      for (var s in m.screenshots) {
        final c = TextEditingController(text: s);
        _screenshots.add(c);
      }
    } else {
      _screenshots.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _aboutCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    _fileUrlCtrl.dispose();
    for (var c in _screenshots) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final screenshots = _screenshots
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final item = ModItem(
      id: widget.mod?.id,
      title: _titleCtrl.text.trim(),
      about: _aboutCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      price: int.tryParse(_priceCtrl.text.trim()) ?? 0,
      screenshots: screenshots,
      fileUrl:
          _fileUrlCtrl.text.trim().isEmpty ? null : _fileUrlCtrl.text.trim(),
      status: _status,
      unlisted: _unlisted,
    );
    if (widget.mod == null) {
      await _db.createMod(item);
    } else {
      await _db.updateMod(item);
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _addScreenshotField() {
    setState(() {
      _screenshots.add(TextEditingController());
    });
  }

  Future<void> _pickAndUploadFile() async {
    final res = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (res == null || res.files.isEmpty) return;
    final p = res.files.first.path;
    if (p == null) return;
    final file = File(p);
    setState(() => _uploadingFile = true);
    try {
      final url = await _storage.uploadFile(file, folder: 'mods/${_uuid.v4()}');
      _fileUrlCtrl.text = url;
    } catch (e) {
      // ignore for now, could show error
    } finally {
      setState(() => _uploadingFile = false);
    }
  }

  Future<void> _pickAndUploadScreenshots() async {
    final available = 3 - _screenshots.length;
    if (available <= 0) return;
    final res = await FilePicker.platform
        .pickFiles(allowMultiple: true, type: FileType.image);
    if (res == null || res.files.isEmpty) return;
    final files =
        res.files.take(available).where((f) => f.path != null).toList();
    if (files.isEmpty) return;
    setState(() => _uploadingScreens = true);
    try {
      for (var f in files) {
        final file = File(f.path!);
        final url =
            await _storage.uploadFile(file, folder: 'mods/${_uuid.v4()}');
        setState(() {
          final c = TextEditingController(text: url);
          _screenshots.add(c);
        });
      }
    } catch (e) {
      // ignore for now
    } finally {
      setState(() => _uploadingScreens = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.mod == null ? 'Add Mod' : 'Edit Mod')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null),
              TextFormField(
                  controller: _aboutCtrl,
                  decoration: const InputDecoration(labelText: 'About'),
                  maxLines: 3),
              TextFormField(
                  controller: _categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Category')),
              TextFormField(
                  controller: _priceCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Price (0 = free)'),
                  keyboardType: TextInputType.number),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fileUrlCtrl,
                      decoration: const InputDecoration(labelText: 'File URL'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _uploadingFile ? null : _pickAndUploadFile,
                    child: _uploadingFile
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Pick & Upload'),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Screenshots (min 1, max 3)'),
                Row(children: [
                  TextButton(
                      onPressed: _addScreenshotField, child: const Text('Add')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                      onPressed:
                          _uploadingScreens ? null : _pickAndUploadScreenshots,
                      child: _uploadingScreens
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Pick & Upload'))
                ])
              ]),
              for (var c in _screenshots)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextFormField(
                      controller: c,
                      decoration:
                          const InputDecoration(labelText: 'Screenshot URL')),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                items: const [
                  DropdownMenuItem(
                      value: 'published', child: Text('Published')),
                  DropdownMenuItem(value: 'draft', child: Text('Draft'))
                ],
                onChanged: (v) => setState(() => _status = v ?? 'published'),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              SwitchListTile(
                  value: _unlisted,
                  onChanged: (v) => setState(() => _unlisted = v),
                  title: const Text('Unlisted')),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _save, child: const Text('Save'))
            ],
          ),
        ),
      ),
    );
  }
}
