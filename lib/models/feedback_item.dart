class FeedbackItem {
  final String id;
  final String message;
  final String createdBy;
  final DateTime createdAt;

  FeedbackItem({
    required this.id,
    required this.message,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'message': message,
    'createdBy': createdBy,
    'createdAt': createdAt,
  };

  static FeedbackItem fromMap(String id, Map<String, dynamic> m) {
    return FeedbackItem(
      id: id,
      message: (m['message'] ?? '') as String,
      createdBy: (m['createdBy'] ?? '') as String,
      createdAt: (m['createdAt'] as dynamic).toDate(),
    );
  }
}
