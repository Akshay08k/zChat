class ChatModel {
  String chatId;
  List<String> members;
  String? lastMessage;
  int? lastTimestamp;

  ChatModel({
    required this.chatId,
    required this.members,
    this.lastMessage,
    this.lastTimestamp,
  });

  Map<String, dynamic> toJson() => {
    'chatId': chatId,
    'members': members,
    'lastMessage': lastMessage,
    'lastTimestamp': lastTimestamp,
  };

  static ChatModel fromJson(Map<dynamic, dynamic> json) => ChatModel(
    chatId: json['chatId'],
    members: List<String>.from(json['members']),
    lastMessage: json['lastMessage'],
    lastTimestamp: json['lastTimestamp'],
  );
}
