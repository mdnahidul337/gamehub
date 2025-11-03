import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/announcement_item.dart';
import '../services/db_service.dart';

class AnnouncementScreen extends StatelessWidget {
  const AnnouncementScreen({super.key});

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

class AnnouncementDetailsScreen extends StatelessWidget {
  final AnnouncementItem announcement;

  const AnnouncementDetailsScreen({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(announcement.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (announcement.imageUrl != null)
              Image.network(announcement.imageUrl!),
            const SizedBox(height: 16),
            Text(announcement.title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(announcement.content),
          ],
        ),
      ),
    );
  }
}
