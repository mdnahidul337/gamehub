import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../config/ad_config.dart';
import '../models/mod_item.dart';
import '../widgets/ad_widget.dart';
import '../services/db_service.dart';
import '../widgets/mod_list.dart';

class TopScreen extends StatefulWidget {
  final String searchQuery;
  const TopScreen({super.key, this.searchQuery = ''});

  @override
  State<TopScreen> createState() => _TopScreenState();
}

class _TopScreenState extends State<TopScreen> {
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
          final mods = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: ModList(
                  mods: mods,
                  searchQuery: widget.searchQuery,
                ),
              ),
              const BannerAdWidget(),
            ],
          );
        },
      ),
    );
  }
}
