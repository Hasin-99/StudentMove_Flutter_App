class AnnouncementItem {
  const AnnouncementItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isPinned,
    required this.publishAt,
  });

  final String id;
  final String title;
  final String body;
  final bool isPinned;
  final DateTime publishAt;

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    final rawDate = '${json['publish_at'] ?? ''}';
    return AnnouncementItem(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      body: '${json['body'] ?? ''}',
      isPinned: json['is_pinned'] == true,
      publishAt: DateTime.tryParse(rawDate) ?? DateTime.now(),
    );
  }
}
