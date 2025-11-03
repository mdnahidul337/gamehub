import 'package:flutter/material.dart';

import '../services/db_service.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final DBService _db = DBService();
  late Future<List<String>> _future;

  @override
  void initState() {
    super.initState();
    _future = _db.listCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<String>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          final cats = snap.data ?? [];
          if (cats.isEmpty) return const Center(child: Text('No categories'));
          return ListView.builder(
            itemCount: cats.length,
            itemBuilder: (context, i) => ListTile(title: Text(cats[i])),
          );
        },
      ),
    );
  }
}
