class ChatListItem {
  final String chatId;
  final String title;
  final String? subtitle;
  final bool isGroup;
  final String? peerUid;
  final String? profilePhoto;
  final int unreadCount;
  final int? lastTimestamp;

  ChatListItem({
    required this.chatId,
    required this.title,
    this.subtitle,
    this.isGroup = false,
    this.peerUid,
    this.profilePhoto,
    this.unreadCount = 0,
    this.lastTimestamp,
  });
}
