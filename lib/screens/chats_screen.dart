import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';

import '../services/db_service.dart';
import '../services/auth_service.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final DBService _db = DBService();
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  String _activeRoom = 'world';

  void _send(AuthService auth) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final name = auth.currentUser?.email ?? 'Guest';
    final uid = auth.currentUser?.uid ??
        'anon_${DateTime.now().millisecondsSinceEpoch}';
    final msg = {
      'uid': uid,
      'name': name,
      'text': text,
      'ts': DateTime.now().millisecondsSinceEpoch
    };
    await _db.sendChatMessage(_activeRoom, msg);
    _ctrl.clear();
    // scroll to bottom after a delay to let stream update
    Future.delayed(const Duration(milliseconds: 250), () {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
          bottom:
              const TabBar(tabs: [Tab(text: 'World'), Tab(text: 'Support')]),
        ),
        body: TabBarView(children: [
          _buildRoom('world', auth),
          _buildRoom('support_${auth.currentUser?.uid ?? 'guest'}', auth),
        ]),
      ),
    );
  }

  Widget _buildRoom(String roomId, AuthService auth) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<DatabaseEvent>(
            stream: _db.streamChatMessages(roomId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              final Map? map = snap.data?.snapshot.value as Map?;
              final msgs = <Map<String, dynamic>>[];
              if (map != null) {
                map.forEach((k, v) {
                  try {
                    final m = Map<String, dynamic>.from(v);
                    m['id'] = k;
                    msgs.add(m);
                  } catch (_) {}
                });
                msgs.sort((a, b) => (a['ts'] ?? 0).compareTo(b['ts'] ?? 0));
              }
              return ListView.builder(
                controller: _scroll,
                itemCount: msgs.length,
                itemBuilder: (context, i) {
                  final m = msgs[i];
                  final mine = m['uid'] == auth.currentUser?.uid;
                  return ListTile(
                    title: Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: mine
                              ? Colors.blue.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(m['text'] ?? ''),
                      ),
                    ),
                    subtitle: Align(
                        alignment:
                            mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Text(
                            '${m['name'] ?? 'User'} • ${DateTime.fromMillisecondsSinceEpoch((m['ts'] ?? 0) as int)}',
                            style: const TextStyle(fontSize: 12))),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(hintText: 'Message...'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _send(auth),
              )
            ],
          ),
        )
      ],
    );
  }
}
