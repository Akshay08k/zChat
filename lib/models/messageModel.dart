class MessageModel {
  String id;
  String senderId;
  String text;
  String? mediaUrl;
  int timestamp;
  Map<String, bool>? isRead; // key = uid, value = true/false

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.mediaUrl,
    required this.timestamp,
    this.isRead,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'text': text,
    'mediaUrl': mediaUrl,
    'timestamp': timestamp,
    'isRead': isRead ?? {},
  };

  static MessageModel fromJson(Map<dynamic, dynamic> json) => MessageModel(
    id: json['id'] as String,
    senderId: json['senderId'] as String,
    text: json['text'] as String,
    mediaUrl: json['mediaUrl'] as String?,
    timestamp: json['timestamp'] as int,
    isRead: (json['isRead'] as Map<dynamic, dynamic>?)?.cast<String, bool>(),
  );
}
