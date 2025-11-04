class AppUser {
  final String uid;
  final String email;
  final String username;
  final String role; // 'user' or 'admin'
  final int coins;
  final bool banned;
  final String? firstName;
  final String? lastName;
  final String? bio;

  AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.role,
    required this.coins,
    required this.banned,
    this.firstName,
    this.lastName,
    this.bio,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'role': role,
      'coins': coins,
      'banned': banned,
      'firstName': firstName,
      'lastName': lastName,
      'bio': bio,
    };
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) {
    return AppUser(
      uid: uid,
      email: m['email'] ?? '',
      username: m['username'] ?? '',
      role: m['role'] ?? 'user',
      coins:
          (m['coins'] is int) ? m['coins'] : int.tryParse('${m['coins']}') ?? 0,
      banned: m['banned'] == true,
      firstName: m['firstName'],
      lastName: m['lastName'],
      bio: m['bio'],
    );
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? username,
    String? role,
    int? coins,
    bool? banned,
    String? firstName,
    String? lastName,
    String? bio,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      coins: coins ?? this.coins,
      banned: banned ?? this.banned,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      bio: bio ?? this.bio,
    );
  }
}
