import 'package:flutter/material.dart';
import 'admin_announcements_screen.dart';
import 'admin_mods_screen.dart';
import 'admin_tasks_screen.dart';
import 'admin_users_screen.dart';
import 'admin_payments_screen.dart';

import '../models/mod_item.dart';
import '../services/db_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DBService _db = DBService();

  late Future<void> _future;
  int usersCount = 0;
  int modsCount = 0;
  int purchasesCount = 0;
  List<Map<String, dynamic>> recentPurchases = [];
  List<ModItem> topMods = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _load() async {
    final users = await _db.listUsers();
    final mods = await _db.listMods();
    final purchases = await _db.listRecentPurchases(limit: 20);
    final top = await _db.listTopMods(limit: 10);
    setState(() {
      usersCount = users.length;
      modsCount = mods.length;
      purchasesCount = purchases.length;
      recentPurchases = purchases;
      topMods = top;
    });
  }

  Future<void> _refresh() async {
    await _load();
  }

  int _currentIndex = 0;

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        // Already on this screen
        break;
      case 1:
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminModsScreen()));
        break;
      case 2:
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminTasksScreen()));
        break;
      case 3:
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminUsersScreen()));
        break;
      case 4:
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => const AdminAnnouncementsScreen()));
        break;
      case 5:
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminPaymentsScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin - Dashboard')),
      body: FutureBuilder<void>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _statCard('Users', usersCount, Icons.group),
                      const SizedBox(width: 8),
                      _statCard('Mods', modsCount, Icons.folder),
                      const SizedBox(width: 8),
                      _statCard(
                          'Purchases', purchasesCount, Icons.shopping_cart),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Recent purchases',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...recentPurchases.map((p) => ListTile(
                        title: Text('${p['modId'] ?? 'unknown'}'),
                        subtitle: Text(
                            'User: ${p['uid'] ?? 'unknown'} • ${DateTime.fromMillisecondsSinceEpoch((p['ts'] ?? 0) as int)}'),
                        trailing: Text('${p['price'] ?? 0} coins'),
                      )),
                  const SizedBox(height: 16),
                  const Text('Top mods',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...topMods.map((m) => ListTile(
                        title: Text(m.title),
                        subtitle: Text(
                            'Downloads: ${m.downloads} • Price: ${m.price}'),
                      )),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.games), label: 'Mods'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(
              icon: Icon(Icons.announcement), label: 'Announce'),
          BottomNavigationBarItem(
              icon: Icon(Icons.payment), label: 'Payments'),
        ],
      ),
    );
  }

  Widget _statCard(String title, int value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text('$value',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
