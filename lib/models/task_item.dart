class TaskItem {
  final String? id;
  final String title;
  final String description;
  final int points;
  final String? thumbnailUrl;
  final String? taskUrl;

  TaskItem(
      {this.id,
      required this.title,
      this.description = '',
      this.points = 0,
      this.thumbnailUrl,
      this.taskUrl});

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'points': points,
      'thumbnailUrl': thumbnailUrl,
      'taskUrl': taskUrl,
    };
  }

  factory TaskItem.fromMap(String id, Map<String, dynamic> m) {
    return TaskItem(
      id: id,
      title: m['title'] ?? '',
      description: m['description'] ?? '',
      points: (m['points'] is int)
          ? m['points']
          : int.tryParse('${m['points']}') ?? 0,
      thumbnailUrl: m['thumbnailUrl'],
      taskUrl: m['taskUrl'],
    );
  }
}
