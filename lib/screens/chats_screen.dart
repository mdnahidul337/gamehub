import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';

import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';
import '../utils/theme.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final bool isAdmin = auth.currentUser?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Chat'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      ),
      body: isAdmin ? const _AdminChatList() : const _UserChat(),
    );
  }
}

class _UserChat extends StatefulWidget {
  const _UserChat();

  @override
  _UserChatState createState() => _UserChatState();
}

class _UserChatState extends State<_UserChat> {
  final DBService _db = DBService();
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  void _send(AuthService auth) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final name = auth.currentUser?.username ?? 'Guest';
    final uid = auth.currentUser!.uid;
    final msg = {
      'uid': uid,
      'name': name,
      'text': text,
      'ts': DateTime.now().millisecondsSinceEpoch
    };
    await _db.sendChatMessage('support_$uid', msg);
    _ctrl.clear();
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
    return _ChatRoom(
      roomId: 'support_${auth.currentUser!.uid}',
      auth: auth,
      db: _db,
      ctrl: _ctrl,
      scroll: _scroll,
      send: () => _send(auth),
    );
  }
}

class _AdminChatList extends StatefulWidget {
  const _AdminChatList();

  @override
  __AdminChatListState createState() => __AdminChatListState();
}

class __AdminChatListState extends State<_AdminChatList> {
  late Future<List<AppUser>> _users;
  final DBService _db = DBService();

  @override
  void initState() {
    super.initState();
    _users = _db.listUsers().then((users) => users
        .map((u) => AppUser.fromMap(u['id'], u))
        .where((u) => u.role != 'admin')
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppUser>>(
      future: _users,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No support chats found.'));
        }
        final users = snapshot.data!;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              title: Text(user.username),
              subtitle: Text(user.email),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: Text('Chat with ${user.username}')),
                      body: _AdminChatRoom(user: user),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AdminChatRoom extends StatefulWidget {
  final AppUser user;
  const _AdminChatRoom({required this.user});

  @override
  _AdminChatRoomState createState() => _AdminChatRoomState();
}

class _AdminChatRoomState extends State<_AdminChatRoom> {
  final DBService _db = DBService();
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  void _send(AuthService auth) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final name = auth.currentUser?.username ?? 'Admin';
    final uid = auth.currentUser!.uid;
    final msg = {
      'uid': uid,
      'name': name,
      'text': text,
      'ts': DateTime.now().millisecondsSinceEpoch
    };
    await _db.sendChatMessage('support_${widget.user.uid}', msg);
    _ctrl.clear();
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
    return _ChatRoom(
      roomId: 'support_${widget.user.uid}',
      auth: auth,
      db: _db,
      ctrl: _ctrl,
      scroll: _scroll,
      send: () => _send(auth),
    );
  }
}

class _ChatRoom extends StatefulWidget {
  const _ChatRoom({
    required this.roomId,
    required this.auth,
    required this.db,
    required this.ctrl,
    required this.scroll,
    required this.send,
  });

  final String roomId;
  final AuthService auth;
  final DBService db;
  final TextEditingController ctrl;
  final ScrollController scroll;
  final VoidCallback send;

  @override
  State<_ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<_ChatRoom> {
  late Stream<DatabaseEvent> _chatStream;

  @override
  void initState() {
    super.initState();
    _chatStream = widget.db.streamChatMessages(widget.roomId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<DatabaseEvent>(
            stream: _chatStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
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
                controller: widget.scroll,
                itemCount: msgs.length,
                itemBuilder: (context, i) {
                  final m = msgs[i];
                  final mine = m['uid'] == widget.auth.currentUser?.uid;
                  return ListTile(
                    title: Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: mine
                              ? AppTheme.mainBlue
                              : AppTheme.lightGray,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          m['text'] ?? '',
                          style: TextStyle(
                              color: mine ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                    subtitle: Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${m['name'] ?? 'User'} • ${DateTime.fromMillisecondsSinceEpoch((m['ts'] ?? 0) as int).toLocal()}',
                          style: AppTheme.textTheme.titleSmall,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.ctrl,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.lightGray,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  ),
                  onSubmitted: (_) => widget.send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: AppTheme.mainBlue),
                onPressed: widget.send,
              )
            ],
          ),
        )
      ],
    );
  }
}
