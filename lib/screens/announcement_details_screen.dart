import 'package:flutter/material.dart';
import '../models/announcement_item.dart';

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
