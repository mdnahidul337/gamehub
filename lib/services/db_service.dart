import 'package:firebase_database/firebase_database.dart';

import '../models/coin_package.dart';
import '../models/mod_item.dart';
import '../models/review.dart';
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
    await ref.runTransaction((Object? post) {
      if (post == null) {
        return Transaction.success(1);
      }
      final value = post as int;
      return Transaction.success(value + 1);
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
    final result = await coinsRef.runTransaction((Object? post) {
      if (post == null) {
        return Transaction.abort();
      }
      final value = post as int;
      if (value < price) {
        return Transaction.abort();
      }
      return Transaction.success(value - price);
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
        await coinsRef.runTransaction((Object? post) {
          if (post == null) {
            return Transaction.success(price);
          }
          final value = post as int;
          return Transaction.success(value + price);
        });
      } catch (e) {
        // Log this critical error, as user may have lost coins
        print(
            'CRITICAL: Failed to refund user $uid for $price coins after a failed purchase. Error: $e');
      }
      return {
        'success': false,
        'message': 'Purchase failed. If coins were deducted, please contact support.'
      };
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
    await ref.runTransaction((Object? post) {
      if (post == null) {
        return Transaction.success(amount);
      }
      final value = post as int;
      return Transaction.success(value + amount);
    });
  }

  /// Daily login bonus: awards `points` if 24 hours have passed since the last claim.
  /// Returns true if awarded, false otherwise.
  Future<bool> giveDailyLoginBonus(String uid, int points) async {
    final ref = _db.child('user_daily/$uid/lastClaimTimestamp');
    final event = await ref.once();
    final lastClaimTimestamp = event.snapshot.value as int?;

    final now = DateTime.now().millisecondsSinceEpoch;

    if (lastClaimTimestamp != null) {
      final twentyFourHoursInMillis = 24 * 60 * 60 * 1000;
      if (now - lastClaimTimestamp < twentyFourHoursInMillis) {
        return false; // Not enough time has passed
      }
    }

    // Use a transaction to ensure atomicity
    final transactionResult = await ref.runTransaction((Object? currentValue) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentValue != null) {
        final lastClaim = currentValue as int;
        final twentyFourHoursInMillis = 24 * 60 * 60 * 1000;
        if (currentTime - lastClaim < twentyFourHoursInMillis) {
          return Transaction.abort(); // Abort if another claim was made recently
        }
      }
      return Transaction.success(currentTime);
    });

    if (transactionResult.committed) {
      await incrementUserCoins(uid, points);
      return true;
    } else {
      return false;
    }
  }

  Future<bool> hasClaimedDailyBonus(String uid) async {
    final ref = _db.child('user_daily/$uid/lastClaimTimestamp');
    final event = await ref.once();
    final lastClaimTimestamp = event.snapshot.value as int?;

    if (lastClaimTimestamp == null) {
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final twentyFourHoursInMillis = 24 * 60 * 60 * 1000;

    return now - lastClaimTimestamp < twentyFourHoursInMillis;
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

  Future<List<Map<String, dynamic>>> listUserPurchases(String uid) async {
    final q = _db.child('payments').orderByChild('uid').equalTo(uid);
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
    final q = _db.child('payments').orderByChild('ts').limitToLast(limit);
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

  Future<void> joinChat(String roomId, String uid, String username) async {
    await _db.child('chat_members/$roomId/$uid').set({
      'username': username,
      'joinedAt': DateTime.now().millisecondsSinceEpoch
    });
  }

  Future<bool> isChatMember(String roomId, String uid) async {
    final event = await _db.child('chat_members/$roomId/$uid').once();
    return event.snapshot.value != null;
  }

  Future<String> createModRequest(Map<String, dynamic> request) async {
    final ref = _db.child('mod_requests').push();
    final id = ref.key!;
    await ref.set(request);
    return id;
  }

  Stream<DatabaseEvent> streamUserModRequests(String uid) {
    final query = _db.child('mod_requests').orderByChild('uid').equalTo(uid);
    return query.onValue;
  }

  // --- Payment admin ---
  Future<void> approvePayment(String paymentId, String uid, int amount) async {
    await _db.child('payments/$paymentId').update({'status': 'approved'});
    await incrementUserCoins(uid, amount);
  }

  Future<void> rejectPayment(String paymentId) async {
    await _db.child('payments/$paymentId').update({'status': 'rejected'});
  }

  Future<Map<String, dynamic>> submitPayment(
      String uid,
      String username,
      CoinPackage package,
      String mobileNumber,
      String transactionId,
      String paymentMethod) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final payment = {
        'uid': uid,
        'username': username,
        'package': package.toMap(),
        'mobileNumber': mobileNumber,
        'transactionId': transactionId,
        'paymentMethod': paymentMethod,
        'status': 'pending',
        'ts': now,
      };
      await _db.child('payments').push().set(payment);
      return {'success': true, 'message': 'Submission received.'};
    } catch (e) {
      return {'success': false, 'message': 'Submission failed.'};
    }
  }

  // --- Review and Reply System ---

  /// Add a review for a mod.
  Future<void> addReview(String modId, Review review) async {
    await _db.child('reviews/$modId').push().set(review.toMap());
  }

  /// Add a reply to a review.
  Future<void> addReply(String modId, String reviewId, Reply reply) async {
    await _db.child('reviews/$modId/$reviewId/replies').push().set(reply.toMap());
  }

  /// Stream reviews for a mod.
  Stream<DatabaseEvent> streamReviews(String modId) {
    return _db.child('reviews/$modId').onValue;
  }
}
