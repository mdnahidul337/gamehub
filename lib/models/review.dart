class Reply {
  final String id;
  final String userId;
  final String username;
  final String text;
  final int createdAt;

  Reply({
    required this.id,
    required this.userId,
    required this.username,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'text': text,
      'createdAt': createdAt,
    };
  }

  factory Reply.fromMap(String id, Map<String, dynamic> map) {
    return Reply(
      id: id,
      userId: map['userId'] ?? '',
      username: map['username'] ?? 'Anonymous',
      text: map['text'] ?? '',
      createdAt: map['createdAt'] ?? 0,
    );
  }
}

class Review {
  final String id;
  final String userId;
  final String username;
  final String text;
  final double rating;
  final int createdAt;
  final List<Reply> replies;

  Review({
    required this.id,
    required this.userId,
    required this.username,
    required this.text,
    required this.rating,
    required this.createdAt,
    this.replies = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'text': text,
      'rating': rating,
      'createdAt': createdAt,
    };
  }

  factory Review.fromMap(String id, Map<String, dynamic> map) {
    final repliesMap = map['replies'] as Map?;
    final replies = <Reply>[];
    if (repliesMap != null) {
      repliesMap.forEach((key, value) {
        replies.add(Reply.fromMap(key, Map<String, dynamic>.from(value)));
      });
    }

    return Review(
      id: id,
      userId: map['userId'] ?? '',
      username: map['username'] ?? 'Anonymous',
      text: map['text'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      createdAt: map['createdAt'] ?? 0,
      replies: replies,
    );
  }
}
