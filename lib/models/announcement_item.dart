class AnnouncementItem {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final int timestamp;

  AnnouncementItem({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.timestamp,
  });

  factory AnnouncementItem.fromMap(Map<String, dynamic> map) {
    return AnnouncementItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      timestamp: map['ts'] ?? 0,
    );
  }
}
