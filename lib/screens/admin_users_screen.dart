import 'package:flutter/material.dart';

import '../services/db_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final DBService _db = DBService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _db.listUsers();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _db.listUsers();
    });
  }

  Future<void> _toggleBan(Map<String, dynamic> user) async {
    final uid = user['id'] as String;
    final banned = (user['banned'] == true);
    await _db.updateUser(uid, {'banned': !banned});
    _refresh();
  }

  Future<void> _editCoins(Map<String, dynamic> user) async {
    final uid = user['id'] as String;
    final ctrl = TextEditingController(text: '${user['coins'] ?? 0}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Coins'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Coins'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Save'))
        ],
      ),
    );
    if (ok == true) {
      final v = int.tryParse(ctrl.text.trim()) ?? 0;
      await _db.updateUser(uid, {'coins': v});
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin - Users')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          final users = snap.data ?? [];
          if (users.isEmpty) return const Center(child: Text('No users found'));
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, i) {
                final u = users[i];
                final banned = u['banned'] == true;
                return ListTile(
                  title: Text(u['email'] ?? u['id'] ?? 'unknown'),
                  subtitle: Text(
                      'Role: ${u['role'] ?? 'user'} • Coins: ${u['coins'] ?? 0}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'ban') {
                        await _toggleBan(u);
                      } else if (v == 'coins') {
                        await _editCoins(u);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: 'ban', child: Text(banned ? 'Unban' : 'Ban')),
                      const PopupMenuItem(
                          value: 'coins', child: Text('Edit coins')),
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
