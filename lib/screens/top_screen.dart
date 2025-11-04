import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mod_item.dart';
import '../services/db_service.dart';
import '../widgets/mod_list.dart';

class TopScreen extends StatelessWidget {
  final String searchQuery;
  const TopScreen({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DBService>(context, listen: false);
    return Scaffold(
      body: FutureBuilder<List<ModItem>>(
        future: db.listTopMods(),
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
          return ModList(mods: snapshot.data!, searchQuery: searchQuery);
        },
      ),
    );
  }
}
