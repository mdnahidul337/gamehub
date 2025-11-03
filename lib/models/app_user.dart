class AppUser {
  final String uid;
  final String email;
  final String role; // 'user' or 'admin'
  final int coins;
  final bool banned;

  AppUser(
      {required this.uid,
      required this.email,
      required this.role,
      required this.coins,
      required this.banned});

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'coins': coins,
      'banned': banned,
    };
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) {
    return AppUser(
      uid: uid,
      email: m['email'] ?? '',
      role: m['role'] ?? 'user',
      coins:
          (m['coins'] is int) ? m['coins'] : int.tryParse('${m['coins']}') ?? 0,
      banned: m['banned'] == true,
    );
  }
}
