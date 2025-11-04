import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';
import '../services/db_service.dart';

class WorldChatScreen extends StatefulWidget {
  const WorldChatScreen({super.key});

  @override
  State<WorldChatScreen> createState() => _WorldChatScreenState();
}

class _WorldChatScreenState extends State<WorldChatScreen> {
  final _messageController = TextEditingController();
  bool? _isJoined;

  @override
  void initState() {
    super.initState();
    _checkIfJoined();
  }

  Future<void> _checkIfJoined() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final db = Provider.of<DBService>(context, listen: false);
    final uid = auth.currentUser!.uid;
    final isMember = await db.isChatMember('world_chat', uid);
    setState(() {
      _isJoined = isMember;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final db = Provider.of<DBService>(context, listen: false);
    final uid = auth.currentUser!.uid;
    final username = auth.currentUser!.username;

    return Scaffold(
      appBar: AppBar(
        title: const Text('World Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: db.streamChatMessages('world_chat'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('No messages yet.'));
                }
                final data = snapshot.data!.snapshot.value as Map;
                final messages = data.entries.map((e) {
                  final value = e.value as Map;
                  return {
                    'id': e.key,
                    'uid': value['uid'],
                    'username': value['username'],
                    'text': value['text'],
                    'ts': value['ts'],
                  };
                }).toList();
                messages.sort((a, b) => b['ts'].compareTo(a['ts']));

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['uid'] == uid;
                    final timestamp = DateTime.fromMillisecondsSinceEpoch(
                        message['ts']);
                    final formattedTime =
                        DateFormat.jm().format(timestamp);

                    return ListTile(
                      title: Text(
                        message['username'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isMe ? Colors.blue : Colors.black,
                        ),
                      ),
                      subtitle: Text(message['text']),
                      trailing: Text(formattedTime),
                    );
                  },
                );
              },
            ),
          ),
          if (_isJoined == null)
            const Center(child: CircularProgressIndicator())
          else if (_isJoined!)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Enter a message...',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      if (_messageController.text.isNotEmpty) {
                        final message = {
                          'uid': uid,
                          'username': username,
                          'text': _messageController.text,
                          'ts': DateTime.now().millisecondsSinceEpoch,
                        };
                        db.sendChatMessage('world_chat', message);
                        _messageController.clear();
                      }
                    },
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () async {
                  await db.joinChat('world_chat', uid, username);
                  setState(() {
                    _isJoined = true;
                  });
                },
                child: const Text('Join Chat'),
              ),
            ),
        ],
      ),
    );
  }
}
