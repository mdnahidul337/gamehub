import 'package:flutter/material.dart';
import '../models/mod_item.dart';
import '../screens/mod_details_screen.dart';

class ModList extends StatelessWidget {
  final List<ModItem> mods;
  final String searchQuery;

  const ModList({super.key, required this.mods, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final filteredMods = mods
        .where((mod) =>
            mod.title.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    if (filteredMods.isEmpty) {
      return const Center(child: Text('No mods found.'));
    }

    return ListView.builder(
      itemCount: filteredMods.length,
      itemBuilder: (context, index) {
        final mod = filteredMods[index];
        return ListTile(
          leading: mod.screenshots.isNotEmpty
              ? Image.network(mod.screenshots.first)
              : const Icon(Icons.image),
          title: Text(mod.title),
          subtitle: Text(mod.category),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ModDetailsScreen(mod: mod),
            ));
          },
        );
      },
    );
  }
}
