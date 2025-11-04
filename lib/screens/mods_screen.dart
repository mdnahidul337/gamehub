import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/db_service.dart';
import '../models/mod_item.dart';
import '../services/auth_service.dart';
import 'admin_mod_edit.dart';
import '../services/download_service.dart';
import 'mod_details_screen.dart';

class ModsScreen extends StatefulWidget {
  const ModsScreen({super.key});

  @override
  State<ModsScreen> createState() => _ModsScreenState();
}

class _ModsScreenState extends State<ModsScreen> {
  final DBService _db = DBService();
  late Future<List<ModItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _db.listMods();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _db.listMods();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final downloadService = Provider.of<DownloadService>(context);
    final isAdmin = auth.currentUser?.role == 'admin';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mods'),
        actions: [
          if (auth.currentUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Center(
                  child: Text('${auth.currentUser!.coins} 💎',
                      style: const TextStyle(fontSize: 16))),
            )
        ],
      ),
      body: FutureBuilder<List<ModItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('No mods found'));
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final m = items[i];
                if (m.unlisted && !isAdmin) return const SizedBox.shrink();
                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ModDetailsScreen(mod: m),
                    ));
                  },
                  child: ListTile(
                    leading: m.screenshots.isNotEmpty
                        ? Image.network(
                            m.screenshots.first,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : null,
                    title: Text(m.title),
                    subtitle: Text(
                        '${m.category} • ${m.price == 0 ? 'Free' : '${m.price}'} coins • ${m.downloads} downloads'),
                    trailing: isAdmin
                        ? PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              await Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => AdminModEdit(mod: m)));
                              _refresh();
                            } else if (v == 'delete') {
                              await _db.deleteMod(m.id!);
                              _refresh();
                            } else if (v == 'unlist') {
                              await _db.setUnlisted(m.id!, !(m.unlisted));
                              _refresh();
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(
                                value: 'unlist', child: Text('Toggle Unlist')),
                            const PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ownership / buy button
                            if (m.price > 0)
                              FutureBuilder<bool>(
                                future: _db.hasUserPurchased(
                                    auth.currentUser?.uid ?? '', m.id!),
                                builder: (context, ownedSnap) {
                                  final owned = ownedSnap.data == true;
                                  if (owned) {
                                    return const Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: Text('Owned',
                                          style:
                                              TextStyle(color: Colors.green)),
                                    );
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final uid = auth.currentUser?.uid;
                                        if (uid == null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Please login to purchase')));
                                          return;
                                        }
                                        final coins =
                                            auth.currentUser?.coins ?? 0;
                                        if (coins < m.price) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Not enough coins')));
                                          return;
                                        }
                                        final confirmed =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('Purchase'),
                                            content: Text(
                                                'Buy "${m.title}" for ${m.price} coins?'),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(false),
                                                  child: const Text('Cancel')),
                                              ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(true),
                                                  child: const Text('Buy')),
                                            ],
                                          ),
                                        );
                                        if (confirmed != true) return;
                                        final res = await _db.purchaseMod(
                                            uid, m.id!, m.price);
                                        if (res['success'] == true) {
                                          await auth.refreshCurrentUser();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Purchase successful')));
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      'Purchase failed: ${res['message']}')));
                                        }
                                      },
                                      child: Text('${m.price} 💎'),
                                    ),
                                  );
                                },
                              )
                            else
                              const SizedBox.shrink(),

                            // download icon and progress
                            IconButton(
                              icon: const Icon(Icons.download),
                              onPressed: () async {
                                if (m.fileUrl == null || m.fileUrl!.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('No file URL')));
                                  return;
                                }
                                if (m.price > 0) {
                                  final uid = auth.currentUser?.uid;
                                  if (uid == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Please login to purchase')));
                                    return;
                                  }
                                  final owned =
                                      await _db.hasUserPurchased(uid, m.id!);
                                  if (!owned) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'You must purchase this item first')));
                                    return;
                                  }
                                }
                                // allow download
                                final url = m.fileUrl!;
                                try {
                                  final fileName =
                                      Uri.parse(url).pathSegments.isNotEmpty
                                          ? Uri.parse(url).pathSegments.last
                                          : '${m.id}.bin';
                                  await downloadService.download(
                                      m.id!, url, fileName);
                                  // increment downloads count on enqueue (we consider started)
                                  await _db.incrementDownloads(m.id!);
                                  _refresh();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Download started')));
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Download error: $e')));
                                }
                              },
                            ),
                            if (m.id != null &&
                                downloadService.progressFor(m.id!) > 0 &&
                                downloadService.progressFor(m.id!) < 100)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: SizedBox(
                                  width: 60,
                                  child: LinearProgressIndicator(
                                      value:
                                          downloadService.progressFor(m.id!) /
                                              100),
                                ),
                              ),
                          ],
                        ),
                  ),
                ); // end InkWell
              }, // end itemBuilder
            ), // end ListView.builder
          ); // end RefreshIndicator
        }, // end FutureBuilder builder
      ), // end FutureBuilder
    ); // end Scaffold
  }
}
