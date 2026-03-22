class Post {
  const Post({
    this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final int? id;
  final String title;
  final String body;
  final int createdAt;

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'body': body,
      'created_at': createdAt,
    };
  }

  /// Returns null if the row is missing required fields or has wrong types (corrupted data).
  static Post? tryFromMap(Map<String, Object?> map) {
    try {
      final id = map['id'];
      final title = map['title'];
      final body = map['body'];
      final createdAt = map['created_at'];
      if (title is! String || body is! String) return null;
      if (createdAt is! int) return null;
      final idInt = id is int ? id : null;
      return Post(
        id: idInt,
        title: title,
        body: body,
        createdAt: createdAt,
      );
    } on Object {
      return null;
    }
  }
}
