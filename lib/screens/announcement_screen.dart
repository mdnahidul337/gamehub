import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/announcement_item.dart';
import '../services/db_service.dart';
import 'home_screen.dart';
import 'mods_screen.dart';
import 'tasks_screen.dart';
import 'admin_users_screen.dart';
import 'announcement_details_screen.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  int _currentIndex = 4; // Set to 'Announce'

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    // In a real app, you'd navigate to the other screens.
    // This is a simplified example.
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()));
        break;
      case 1:
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ModsScreen()));
        break;
      case 2:
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const TasksScreen()));
        break;
      case 3:
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminUsersScreen()));
        break;
      case 4:
        // Already on this screen
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DBService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: db.listAnnouncements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No announcements found.'));
          }
          final announcements = snapshot.data!
              .map((map) => AnnouncementItem.fromMap(map))
              .toList();
          return ListView.builder(
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (announcement.imageUrl != null)
                        Image.network(announcement.imageUrl!),
                      const SizedBox(height: 8),
                      Text(announcement.title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        announcement.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => AnnouncementDetailsScreen(
                                  announcement: announcement)));
                        },
                        child: const Text('Read More'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
