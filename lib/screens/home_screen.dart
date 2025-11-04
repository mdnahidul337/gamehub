import 'package:flutter/material.dart';
import 'package:gamehubtest/screens/tasks_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'profile_screen.dart';
import 'request_mod_screen.dart';
import 'mod_requests_screen.dart';
import 'world_chat_screen.dart';
import '../utils/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<ModItem> _searchResults = [];
  late Future<List<ModItem>> _modsFuture;

  @override
  void initState() {
    super.initState();
    _modsFuture = _fetchMods();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<List<ModItem>> _fetchMods() async {
    final db = Provider.of<DBService>(context, listen: false);
    return db.listMods();
  }

  Future<void> _refreshData() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await auth.refreshCurrentUser();
    setState(() {
      _modsFuture = _fetchMods();
    });
  }

  void _onSearchChanged() {
    _modsFuture.then((mods) {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _searchResults = mods
            .where((mod) => mod.title.toLowerCase().contains(query))
            .toList();
      });
    });
  }

  void _onTap(int idx) => setState(() => _currentIndex = idx);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (auth.currentUser != null)
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: Text('Coins: ${auth.currentUser!.coins}'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshData,
                ),
              ],
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
              accountName: Text(auth.currentUser?.username ?? 'Guest'),
              accountEmail: Text(auth.currentUser?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  auth.currentUser?.username.isNotEmpty == true
                      ? auth.currentUser!.username[0].toUpperCase()
                      : 'G',
                  style: const TextStyle(fontSize: 40.0),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Update profile'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
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
              leading: const Icon(Icons.add_box),
              title: const Text('Request a Mod'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const RequestModScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('My Mod Requests'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ModRequestsScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('World Chat'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WorldChatScreen()));
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
      body: IndexedStack(
        index: _currentIndex,
        children: <Widget>[
          _HomeTab(
            searchResults: _searchResults,
            searchQuery: _searchController.text,
          ),
          ListScreen(searchQuery: _searchController.text),
          const AnnouncementScreen(),
          TopScreen(searchQuery: _searchController.text),
          const ChatsScreen(),
        ],
      ),
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
  final List<ModItem> searchResults;
  final String searchQuery;
  const _HomeTab(
      {super.key, required this.searchResults, required this.searchQuery});

  @override
  __HomeTabState createState() => __HomeTabState();
}

class __HomeTabState extends State<_HomeTab> {
  late Future<Map<String, List<ModItem>>> _items;

  @override
  void initState() {
    super.initState();
    _items = _fetchItems();
    _showDailyRewardDialog();
  }

  Future<void> _refreshItems() async {
    setState(() {
      _items = _fetchItems();
    });
  }

  Future<void> _showDailyRewardDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final lastClaimed = prefs.getString('last_claimed_daily_reward');
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (lastClaimed != today) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Daily Reward'),
              content: const Text('Claim your daily 2 coins!'),
              actions: [
                TextButton(
                  onPressed: () async {
                    final auth =
                        Provider.of<AuthService>(context, listen: false);
                    if (auth.currentUser != null) {
                      await auth.awardCoinsToCurrentUser(2);
                      await prefs.setString(
                          'last_claimed_daily_reward', today);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You have claimed 2 coins!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not claim reward. User not found.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Claim'),
                ),
              ],
            ),
          );
        }
      });
    }
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
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Text(
        title,
        style: AppTheme.textTheme.headlineMedium,
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
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.screenshots.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.network(
                  item.screenshots.first,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: AppTheme.grayText,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTheme.textTheme.headlineMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.publisherName,
                    style: AppTheme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.searchQuery.isNotEmpty) {
      if (widget.searchResults.isEmpty) {
        return const Center(child: Text('No results found.'));
      }
      return ListView.builder(
        itemCount: widget.searchResults.length,
        itemBuilder: (context, index) {
          return _buildItemCard(widget.searchResults[index]);
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshItems,
      child: FutureBuilder<Map<String, List<ModItem>>>(
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
      ),
    );
  }
}
