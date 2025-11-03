class ModItem {
  final String? id;
  final String title;
  final String about;
  final String category;
  final int price;
  final List<String> screenshots;
  final String? fileUrl;
  final String status; // e.g., 'published', 'draft'
  final int? createdAt;
  final bool unlisted;
  final int downloads;
  final String publisherName;

  ModItem({
    this.id,
    required this.title,
    required this.about,
    required this.category,
    this.price = 0,
    this.screenshots = const [],
    this.fileUrl,
    this.status = 'published',
    this.createdAt,
    this.unlisted = false,
    this.downloads = 0,
    this.publisherName = 'Admin', // Default value
  });

  ModItem copyWith({
    String? id,
    String? title,
    String? about,
    String? category,
    int? price,
    List<String>? screenshots,
    String? fileUrl,
    String? status,
    int? createdAt,
    bool? unlisted,
    int? downloads,
    String? publisherName,
  }) {
    return ModItem(
      id: id ?? this.id,
      title: title ?? this.title,
      about: about ?? this.about,
      category: category ?? this.category,
      price: price ?? this.price,
      screenshots: screenshots ?? this.screenshots,
      fileUrl: fileUrl ?? this.fileUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      unlisted: unlisted ?? this.unlisted,
      downloads: downloads ?? this.downloads,
      publisherName: publisherName ?? this.publisherName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'about': about,
      'category': category,
      'price': price,
      'screenshots': screenshots,
      'fileUrl': fileUrl,
      'status': status,
      'createdAt': createdAt ?? DateTime.now().millisecondsSinceEpoch,
      'unlisted': unlisted,
      'downloads': downloads,
      'publisherName': publisherName,
    };
  }

  factory ModItem.fromMap(String id, Map<String, dynamic> m) {
    return ModItem(
      id: id,
      title: m['title'] ?? '',
      about: m['about'] ?? '',
      category: m['category'] ?? '',
      price:
          (m['price'] is int) ? m['price'] : int.tryParse('${m['price']}') ?? 0,
      screenshots:
          (m['screenshots'] is List) ? List<String>.from(m['screenshots']) : [],
      fileUrl: m['fileUrl'],
      status: m['status'] ?? 'published',
      createdAt: (m['createdAt'] is int)
          ? m['createdAt']
          : int.tryParse('${m['createdAt']}') ??
              DateTime.now().millisecondsSinceEpoch,
      unlisted: m['unlisted'] == true,
      downloads: (m['downloads'] is int)
          ? m['downloads']
          : int.tryParse('${m['downloads']}') ?? 0,
      publisherName: m['publisherName'] ?? 'Admin',
    );
  }
}
