import 'package:flutter/material.dart';
import '../models/mod_item.dart';
import '../widgets/mod_list.dart';

class CategoryScreen extends StatelessWidget {
  final String category;
  final List<ModItem> mods;

  const CategoryScreen({super.key, required this.category, required this.mods});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: ModList(mods: mods, searchQuery: ''),
    );
  }
}
