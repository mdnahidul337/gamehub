import 'package:flutter/material.dart';
import 'package:gamehubtest/screens/tasks_screen.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'admin_dashboard_screen.dart';
import 'announcement_screen.dart';
import 'chats_screen.dart';
import 'downloads_screen.dart';
import 'list_screen.dart';
import 'shop_screen.dart';
import 'top_screen.dart';
import '../models/mod_item.dart';
import '../services/db_service.dart';
import 'mod_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const List<Widget> _pages = <Widget>[
    _HomeTab(),
    ListScreen(),
    AnnouncementScreen(),
    TopScreen(),
    ChatsScreen(),
  ];

  void _onTap(int idx) => setState(() => _currentIndex = idx);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const TextField(
          decoration: InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (auth.currentUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text('Coins: ${auth.currentUser!.coins}'),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.monetization_on),
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ShopScreen()));
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(auth.currentUser?.email ?? 'Guest'),
              accountEmail: Text('Role: ${auth.currentUser?.role ?? 'user'}'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Update profile'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Downloads'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DownloadsScreen()));
              },
            ),
            if (auth.currentUser?.role == 'admin')
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Admin Access'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AdminDashboardScreen()));
                },
              ),
            const Divider(),
            ListTile(
                leading: const Icon(Icons.send),
                title: const Text('Tasks Screen'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TasksScreen()));
                }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Telegram'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.facebook),
              title: const Text('Facebook'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('YouTube'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Tutorial Video'),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await auth.signOut();
              },
            ),
          ],
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'List'),
          BottomNavigationBarItem(
              icon: Icon(Icons.announcement), label: 'Announce'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Top'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  __HomeTabState createState() => __HomeTabState();
}

class __HomeTabState extends State<_HomeTab> {
  late Future<Map<String, List<ModItem>>> _items;

  @override
  void initState() {
    super.initState();
    _items = _fetchItems();
  }

  Future<Map<String, List<ModItem>>> _fetchItems() async {
    final db = Provider.of<DBService>(context, listen: false);
    final allItems = await db.listMods();
    return {
      'maps': allItems.where((i) => i.category == 'maps').toList(),
      'mods': allItems.where((i) => i.category == 'mods').toList(),
      'bus_skins': allItems.where((i) => i.category == 'bus_skins').toList(),
    };
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildItemCard(ModItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ModDetailsScreen(mod: item),
        ));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            if (item.screenshots.isNotEmpty)
              Image.network(
                item.screenshots.first,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.image, size: 50)),
                ),
              ),
            const SizedBox(height: 8),
            Text(item.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(item.publisherName),
          ],
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<ModItem>>>(
      future: _items,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No items found.'));
        }

        final items = snapshot.data!;
        final maps = items['maps'] ?? [];
        final mods = items['mods'] ?? [];
        final busSkins = items['bus_skins'] ?? [];

        return ListView(
          children: [
            if (maps.isNotEmpty) ...[
              _buildSectionTitle("Editor's Choice for maps"),
              ...maps.map(_buildItemCard),
            ],
            if (mods.isNotEmpty) ...[
              _buildSectionTitle("New and Update latest mods"),
              ...mods.map(_buildItemCard),
            ],
            if (busSkins.isNotEmpty) ...[
              _buildSectionTitle("Best Skins here"),
              ...busSkins.map(_buildItemCard),
            ],
          ],
        );
      },
    );
  }
}
