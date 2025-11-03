import 'package:firebase_database/firebase_database.dart';

import '../models/mod_item.dart';
import '../models/task_item.dart';

class DBService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<List<ModItem>> listMods() async {
    final event = await _db.child('mods').once();
    final Map? val = event.snapshot.value as Map?;
    if (val == null) return [];
    final items = <ModItem>[];
    val.forEach((key, v) {
      try {
        items.add(ModItem.fromMap(key, Map<String, dynamic>.from(v)));
      } catch (_) {}
    });
    // sort by createdAt desc if available
    items.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
    return items;
  }

  Future<ModItem?> getMod(String id) async {
    final event = await _db.child('mods/$id').once();
    if (event.snapshot.value == null) return null;
    return ModItem.fromMap(
        id, Map<String, dynamic>.from(event.snapshot.value as Map));
  }

  Future<String> createMod(ModItem item) async {
    final ref = _db.child('mods').push();
    final id = ref.key!;
    await ref.set(item.copyWith(id: id).toMap());
    return id;
  }

  Future<void> updateMod(ModItem item) async {
    if (item.id == null) throw ArgumentError('Mod id required');
    await _db.child('mods/${item.id}').update(item.toMap());
  }

  Future<void> deleteMod(String id) async {
    await _db.child('mods/$id').remove();
  }

  Future<void> setUnlisted(String id, bool unlist) async {
    await _db.child('mods/$id').update({'unlisted': unlist});
  }

  Future<void> incrementDownloads(String id) async {
    final ref = _db.child('mods/$id/downloads');
    // Use a transaction to increment atomically
    await ref.runTransaction((mutableData) {
      int current = 0;
      final md = mutableData as dynamic;
      final v = md.value;
      if (v != null) {
        current = (v as int?) ?? int.tryParse('$v') ?? 0;
      }
      md.value = current + 1;
      return Transaction.success(mutableData);
    });
  }

  /// Check if user has purchased (owns) a mod
  Future<bool> hasUserPurchased(String uid, String modId) async {
    final event = await _db.child('user_mods/$uid/$modId').once();
    return event.snapshot.value != null;
  }

  /// Purchase a mod: attempts to deduct `price` coins from user's balance atomically.
  /// On success writes ownership under /user_mods/{uid}/{modId} and logs under /purchases.
  /// Returns a map { 'success': bool, 'message': String }
  Future<Map<String, dynamic>> purchaseMod(
      String uid, String modId, int price) async {
    if (price <= 0) return {'success': false, 'message': 'Invalid price'};
    final coinsRef = _db.child('users/$uid/coins');
    // transaction to deduct coins
    final result = await coinsRef.runTransaction((mutableData) {
      int current = 0;
      final md = mutableData as dynamic;
      final v = md.value;
      if (v != null) {
        current = (v as int?) ?? int.tryParse('$v') ?? 0;
      }
      if (current < price) {
        return Transaction.abort();
      }
      mutableData!.value = current - price;
      return Transaction.success(mutableData);
    });
    if (result.committed == false) {
      return {'success': false, 'message': 'Not enough coins'};
    }

    // write ownership and purchase log
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await _db
          .child('user_mods/$uid/$modId')
          .set({'purchasedAt': now, 'price': price});
      final pRef = _db.child('purchases').push();
      await pRef.set({'uid': uid, 'modId': modId, 'price': price, 'ts': now});
      // increment mod purchases/downloads counter
      await incrementDownloads(modId);
      return {'success': true, 'message': 'Purchased'};
    } catch (e) {
      // In the unlikely event we failed after deducting coins, attempt to refund
      try {
        await coinsRef.runTransaction((mutableData) {
          int current = 0;
          final md = mutableData as dynamic;
          final v = md.value;
          if (v != null) {
            current = (v as int?) ?? int.tryParse('$v') ?? 0;
          }
          md.value = current + price;
          return Transaction.success(mutableData);
        });
      } catch (_) {}
      return {'success': false, 'message': 'Purchase failed'};
    }
  }

  // --- Tasks and user-task operations ---
  Future<List<TaskItem>> listTasks() async {
    final event = await _db.child('tasks').once();
    final Map? val = event.snapshot.value as Map?;
    if (val == null) return [];
    final items = <TaskItem>[];
    val.forEach((key, v) {
      try {
        items.add(TaskItem.fromMap(key, Map<String, dynamic>.from(v)));
      } catch (_) {}
    });
    return items;
  }

  Future<String> createTask(TaskItem t) async {
    final ref = _db.child('tasks').push();
    final id = ref.key!;
    await ref.set(t.toMap());
    return id;
  }

  Future<void> updateTask(String id, TaskItem t) async {
    await _db.child('tasks/$id').update(t.toMap());
  }

  Future<void> deleteTask(String id) async {
    await _db.child('tasks/$id').remove();
  }

  Future<bool> hasUserCompletedTask(String uid, String taskId) async {
    final event = await _db.child('user_tasks/$uid/$taskId').once();
    return event.snapshot.value != null;
  }

  /// Completes a task for a user (if not already completed) and awards points to the user's coins.
  /// Returns true if awarded, false if already completed.
  Future<bool> completeTaskForUser(
      String uid, String taskId, int points) async {
    final ref = _db.child('user_tasks/$uid/$taskId');
    final event = await ref.once();
    if (event.snapshot.value != null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    await ref.set({'completedAt': now, 'points': points});
    await incrementUserCoins(uid, points);
    return true;
  }

  Future<void> incrementUserCoins(String uid, int amount) async {
    final ref = _db.child('users/$uid/coins');
    await ref.runTransaction((mutableData) {
      int current = 0;
      final md = mutableData as dynamic;
      final v = md.value;
      if (v != null) {
        current = (v as int?) ?? int.tryParse('$v') ?? 0;
      }
      md.value = current + amount;
      return Transaction.success(mutableData);
    });
  }

  /// Daily login bonus: awards `points` once per calendar day. Returns true if awarded.
  Future<bool> giveDailyLoginBonus(String uid, int points) async {
    final key =
        DateTime.now().toUtc().toIso8601String().split('T').first; // YYYY-MM-DD
    final ref = _db.child('user_daily/$uid/lastDate');
    final event = await ref.once();
    final last = event.snapshot.value as String?;
    if (last == key) return false;
    await ref.set(key);
    await incrementUserCoins(uid, points);
    return true;
  }

  /// Watch ad stub: award points immediately and record a simple event. Returns true on success.
  Future<bool> watchAdAndAward(String uid, int points) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final evRef = _db.child('user_ads/$uid').push();
    await evRef.set({'ts': now, 'points': points});
    await incrementUserCoins(uid, points);
    return true;
  }

  Future<List<String>> listCategories() async {
    final event = await _db.child('categories').once();
    final Map? val = event.snapshot.value as Map?;
    if (val == null) return [];
    final cats = <String>[];
    val.forEach((k, v) {
      if (v is Map && v['title'] != null) cats.add(v['title']);
    });
    return cats;
  }

  // --- Categories CRUD ---
  Future<List<Map<String, dynamic>>> listCategoryItems() async {
    final event = await _db.child('categories').once();
    final Map? val = event.snapshot.value as Map?;
    if (val == null) return [];
    final out = <Map<String, dynamic>>[];
    val.forEach((k, v) {
      try {
        out.add({'id': k, ...Map<String, dynamic>.from(v)});
      } catch (_) {}
    });
    return out;
  }

  Future<String> createCategory(Map<String, dynamic> m) async {
    final ref = _db.child('categories').push();
    final id = ref.key!;
    await ref.set(m);
    return id;
  }

  Future<void> updateCategory(String id, Map<String, dynamic> m) async {
    await _db.child('categories/$id').update(m);
  }

  Future<void> deleteCategory(String id) async {
    await _db.child('categories/$id').remove();
  }

  // --- Announcements CRUD ---
  Future<List<Map<String, dynamic>>> listAnnouncements() async {
    final event = await _db.child('announcements').once();
    final Map? val = event.snapshot.value as Map?;
    if (val == null) return [];
    final out = <Map<String, dynamic>>[];
    val.forEach((k, v) {
      try {
        out.add({'id': k, ...Map<String, dynamic>.from(v)});
      } catch (_) {}
    });
    out.sort((a, b) => (b['ts'] ?? 0).compareTo(a['ts'] ?? 0));
    return out;
  }

  Future<String> createAnnouncement(Map<String, dynamic> m) async {
    final ref = _db.child('announcements').push();
    final id = ref.key!;
    await ref.set(m);
    return id;
  }

  Future<void> updateAnnouncement(String id, Map<String, dynamic> m) async {
    await _db.child('announcements/$id').update(m);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.child('announcements/$id').remove();
  }

  // --- User admin helpers ---
  /// List all users as maps with `id` included.
  Future<List<Map<String, dynamic>>> listUsers() async {
    final event = await _db.child('users').once();
    final Map? val = event.snapshot.value as Map?;
    if (val == null) return [];
    final out = <Map<String, dynamic>>[];
    val.forEach((k, v) {
      try {
        out.add({'id': k, ...Map<String, dynamic>.from(v)});
      } catch (_) {}
    });
    return out;
  }

  /// Update a user's fields (e.g. coins, banned, role)
  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    await _db.child('users/$uid').update(fields);
  }

  /// List recent purchases, sorted by ts desc. Returns list of maps including id.
  Future<List<Map<String, dynamic>>> listRecentPurchases(
      {int limit = 20}) async {
    final q = _db.child('purchases').orderByChild('ts').limitToLast(limit);
    final event = await q.once();
    final Map? val = event.snapshot.value as Map?;
    if (val == null) return [];
    final out = <Map<String, dynamic>>[];
    val.forEach((k, v) {
      try {
        out.add({'id': k, ...Map<String, dynamic>.from(v)});
      } catch (_) {}
    });
    out.sort((a, b) => (b['ts'] ?? 0).compareTo(a['ts'] ?? 0));
    return out;
  }

  /// Return top mods by downloads. Uses existing listMods() then sorts.
  Future<List<ModItem>> listTopMods({int limit = 10}) async {
    final all = await listMods();
    all.sort((a, b) => b.downloads.compareTo(a.downloads));
    if (all.length <= limit) return all;
    return all.sublist(0, limit);
  }

  // --- Chat helpers ---
  /// Stream chat messages for a room as DatabaseEvent.onValue stream.
  Stream<DatabaseEvent> streamChatMessages(String roomId) {
    return _db.child('chats/$roomId').orderByChild('ts').onValue;
  }

  /// Send a chat message to a room. Message should include at least { 'uid', 'name', 'text', 'ts' }
  Future<void> sendChatMessage(
      String roomId, Map<String, dynamic> message) async {
    await _db.child('chats/$roomId').push().set(message);
  }
}
