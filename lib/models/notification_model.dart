class NotificationModel {
  final int id;
  final String message;
  final String type;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.message,
    required this.type,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['created_at']?.toString();
    final readAtValue = json['read_at']?.toString();

    return NotificationModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      message: json['message']?.toString() ?? json['smg']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      createdAt: DateTime.tryParse(createdAtValue ?? '') ?? DateTime.now(),
      readAt: readAtValue == null || readAtValue.isEmpty
          ? null
          : DateTime.tryParse(readAtValue),
    );
  }

  bool get isRead => readAt != null;
}
