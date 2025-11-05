import 'package:flutter/material.dart';
import 'package:gamehubtest/screens/category_screen.dart';
import 'package:gamehubtest/screens/tasks_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../utils/theme_notifier.dart';

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
  BannerAd? _bannerAd;

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
    _bannerAd?.dispose();
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

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        title:
            Text('GameHub', style: Theme.of(context).textTheme.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _ModSearchDelegate(
                  (query) {
                    _searchController.text = query;
                    _onSearchChanged();
                  },
                ),
              );
            },
          ),
          if (auth.currentUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Row(
                  children: [
                    Icon(Icons.monetization_on,
                        color: Theme.of(context).primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '${auth.currentUser!.coins}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).colorScheme.secondary
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: Text(
                auth.currentUser?.username ?? 'Guest',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
              accountEmail: Text(
                auth.currentUser?.email ?? '',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  auth.currentUser?.username.isNotEmpty == true
                      ? auth.currentUser!.username[0].toUpperCase()
                      : 'G',
                  style: TextStyle(
                      fontSize: 40.0, color: Theme.of(context).primaryColor),
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
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Coin Shop'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ShopScreen()));
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
              onTap: () => _launchURL('https://t.me/your_telegram_channel'),
            ),
            ListTile(
              leading: const Icon(Icons.facebook),
              title: const Text('Facebook'),
              onTap: () =>
                  _launchURL('https://www.facebook.com/your_facebook_page'),
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('YouTube'),
              onTap: () =>
                  _launchURL('https://www.youtube.com/your_youtube_channel'),
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Tutorial Video'),
              onTap: () => _launchURL(
                  'https://www.youtube.com/watch?v=your_tutorial_video'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await auth.signOut();
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: themeNotifier.getTheme() == AppTheme.darkTheme,
              onChanged: (value) {
                if (value) {
                  themeNotifier.setTheme(AppTheme.darkTheme);
                } else {
                  themeNotifier.setTheme(AppTheme.lightTheme);
                }
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
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
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

class _ModSearchDelegate extends SearchDelegate<String> {
  final Function(String) onSearch;

  _ModSearchDelegate(this.onSearch);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          onSearch(query);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final db = Provider.of<DBService>(context, listen: false);
    if (query.isEmpty) {
      return const Center(child: Text('Please enter a search query.'));
    }
    return FutureBuilder<List<ModItem>>(
      future: db.listMods(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No results found.'));
        }
        final results = snapshot.data!
            .where(
                (mod) => mod.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
        if (results.isEmpty) {
          return const Center(child: Text('No results found.'));
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return ListTile(
              leading: result.screenshots.isNotEmpty
                  ? Image.network(
                      result.screenshots.first,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.image),
              title: Text(result.title),
              subtitle: Text(result.publisherName),
              onTap: () {
                close(context, '');
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ModDetailsScreen(mod: result),
                ));
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final db = Provider.of<DBService>(context, listen: false);
    if (query.isEmpty) {
      return Container();
    }
    return FutureBuilder<List<ModItem>>(
      future: db.listMods(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No suggestions.'));
        }
        final suggestions = snapshot.data!
            .where(
                (mod) => mod.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
        return ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return ListTile(
              leading: suggestion.screenshots.isNotEmpty
                  ? Image.network(
                      suggestion.screenshots.first,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.image),
              title: Text(suggestion.title),
              subtitle: Text(suggestion.publisherName),
              onTap: () {
                close(context, '');
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ModDetailsScreen(mod: suggestion),
                ));
              },
            );
          },
        );
      },
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text('Daily Reward',
                  style: AppTheme.textTheme.headlineMedium),
              content: Text('Claim your daily 2 coins!',
                  style: AppTheme.textTheme.bodyLarge),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Later', style: AppTheme.textTheme.bodyMedium),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final auth =
                        Provider.of<AuthService>(context, listen: false);
                    if (auth.currentUser != null) {
                      await auth.awardCoinsToCurrentUser(2);
                      await prefs.setString('last_claimed_daily_reward', today);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('You have claimed 2 coins!'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Could not claim reward. User not found.'),
                          backgroundColor: AppTheme.error,
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

  Widget _buildSectionTitle(String title, VoidCallback onViewMore) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          TextButton(
            onPressed: onViewMore,
            child: const Text('See more'),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(List<ModItem> items) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return SizedBox(
            width: 200,
            child: _buildItemCard(items[index]),
          );
        },
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
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).cardColor,
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
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Theme.of(context).iconTheme.color,
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 22),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.publisherName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.download,
                              color: Theme.of(context).iconTheme.color,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.downloads}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                _buildSectionTitle("Editor's Choice for maps", () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CategoryScreen(
                      category: 'maps',
                      mods: maps,
                    ),
                  ));
                }),
                _buildHorizontalList(maps),
              ],
              if (mods.isNotEmpty) ...[
                _buildSectionTitle("New and Update latest mods", () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CategoryScreen(
                      category: 'mods',
                      mods: mods,
                    ),
                  ));
                }),
                _buildHorizontalList(mods),
              ],
              if (busSkins.isNotEmpty) ...[
                _buildSectionTitle("Best Skins here", () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CategoryScreen(
                      category: 'bus_skins',
                      mods: busSkins,
                    ),
                  ));
                }),
                _buildHorizontalList(busSkins),
              ],
            ],
          );
        },
      ),
    );
  }
}
