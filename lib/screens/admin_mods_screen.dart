import 'package:flutter/material.dart';
import '../models/mod_item.dart';
import '../services/db_service.dart';
import 'admin_mod_edit.dart';

class AdminModsScreen extends StatefulWidget {
  const AdminModsScreen({super.key});

  @override
  _AdminModsScreenState createState() => _AdminModsScreenState();
}

class _AdminModsScreenState extends State<AdminModsScreen> {
  final DBService _db = DBService();
  late Future<List<ModItem>> _modsFuture;
  List<ModItem> _mods = [];
  List<ModItem> _filteredMods = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _modsFuture = _fetchMods();
    _searchController.addListener(_filterMods);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<ModItem>> _fetchMods() async {
    final mods = await _db.listMods();
    setState(() {
      _mods = mods;
      _filteredMods = mods;
    });
    return mods;
  }

  void _filterMods() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMods = _mods.where((mod) {
        return mod.title.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _refresh() async {
    await _fetchMods();
  }

  void _navigateAndRefresh(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Mods'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search mods...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _navigateAndRefresh(const AdminModEdit()),
      ),
      body: FutureBuilder<List<ModItem>>(
        future: _modsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (_filteredMods.isEmpty) {
            return const Center(child: Text('No mods found.'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: _filteredMods.length,
              itemBuilder: (context, index) {
                final mod = _filteredMods[index];
                return ListTile(
                  title: Text(mod.title),
                  subtitle: Text(mod.category),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _navigateAndRefresh(AdminModEdit(mod: mod));
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Mod'),
                            content: Text('Are you sure you want to delete "${mod.title}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _db.deleteMod(mod.id!);
                          _refresh();
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
