import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'admin_dashboard_screen.dart';
import 'announcement_screen.dart';
import 'chats_screen.dart';
import 'downloads_screen.dart';
import 'list_screen.dart';
import 'shop_screen.dart';
import 'top_screen.dart';

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

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildModCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.image, size: 50)),
            ),
            const SizedBox(height: 8),
            const Text('Mod Title',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Publisher Name'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildSectionTitle("Editor's Choice"),
        _buildModCard(),
        _buildModCard(),
        _buildSectionTitle("New and Update"),
        _buildModCard(),
        _buildSectionTitle("Best Skins"),
        _buildModCard(),
      ],
    );
  }
}
