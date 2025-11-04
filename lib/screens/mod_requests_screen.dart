import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/db_service.dart';

class ModRequestsScreen extends StatelessWidget {
  const ModRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final db = Provider.of<DBService>(context, listen: false);
    final uid = auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Mod Requests'),
      ),
      body: StreamBuilder(
        stream: db.streamUserModRequests(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No mod requests found.'));
          }
          final data = snapshot.data!.snapshot.value as Map;
          final requests = data.entries.map((e) {
            final value = e.value as Map;
            return {
              'id': e.key,
              'modName': value['modName'],
              'status': value['status'],
            };
          }).toList();

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return ListTile(
                title: Text(request['modName']),
                trailing: Text(request['status']),
              );
            },
          );
        },
      ),
    );
  }
}
