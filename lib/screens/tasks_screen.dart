import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../models/task_item.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final DBService _db = DBService();
  late Future<List<TaskItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _db.listTasks();
  }

  Future<void> _refresh() async {
    setState(() => _future = _db.listTasks());
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final uid = auth.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: uid == null
                        ? null
                        : () async {
                            final awarded =
                                await _db.giveDailyLoginBonus(uid, 2);
                            if (awarded) {
                              await auth.refreshCurrentUser();
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Daily login bonus awarded: 2 coins')));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Daily bonus already claimed')));
                            }
                          },
                    child: const Text('Claim Daily Login (2 coins)'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: uid == null
                      ? null
                      : () async {
                          final ok = await _db.watchAdAndAward(uid, 2);
                          if (ok) {
                            await auth.refreshCurrentUser();
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Thanks! +2 coins')));
                          }
                        },
                  child: const Text('Watch Ad (+2)'),
                )
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TaskItem>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done)
                  return const Center(child: CircularProgressIndicator());
                final tasks = snap.data ?? [];
                if (tasks.isEmpty)
                  return const Center(child: Text('No tasks found'));
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, i) {
                      final t = tasks[i];
                      return FutureBuilder<bool>(
                        future: uid == null
                            ? Future.value(false)
                            : _db.hasUserCompletedTask(uid, t.id!),
                        builder: (context, csnap) {
                          final completed = csnap.data ?? false;
                          return ListTile(
                            leading: t.thumbnailUrl != null
                                ? Image.network(t.thumbnailUrl!,
                                    width: 48, height: 48, fit: BoxFit.cover)
                                : const Icon(Icons.task),
                            title: Text(t.title),
                            subtitle:
                                Text('${t.points} coins • ${t.description}'),
                            trailing: completed
                                ? const Text('Completed',
                                    style: TextStyle(color: Colors.green))
                                : ElevatedButton(
                                    onPressed: uid == null
                                        ? null
                                        : () async {
                                            final awarded =
                                                await _db.completeTaskForUser(
                                                    uid, t.id!, t.points);
                                            if (awarded) {
                                              await auth.refreshCurrentUser();
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                          'Task completed! +${t.points} coins')));
                                              _refresh();
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: Text(
                                                          'Already completed')));
                                            }
                                          },
                                    child: const Text('Complete')),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
