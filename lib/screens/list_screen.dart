import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mod_item.dart';
import '../services/db_service.dart';

class ListScreen extends StatelessWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DBService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Mods'),
      ),
      body: FutureBuilder<List<ModItem>>(
        future: db.listMods(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No mods found.'));
          }
          final mods = snapshot.data!;
          return ListView.builder(
            itemCount: mods.length,
            itemBuilder: (context, index) {
              final mod = mods[index];
              return ListTile(
                leading: mod.screenshots.isNotEmpty
                    ? Image.network(mod.screenshots.first)
                    : const Icon(Icons.image),
                title: Text(mod.title),
                subtitle: Text(mod.category),
              );
            },
          );
        },
      ),
    );
  }
}
