class CategoryItem {
  final String? id;
  final String title;
  final String? description;

  CategoryItem({this.id, required this.title, this.description});

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
      };

  factory CategoryItem.fromMap(String id, Map<String, dynamic> m) {
    return CategoryItem(
      id: id,
      title: m['title'] ?? '',
      description: m['description'],
    );
  }
}
