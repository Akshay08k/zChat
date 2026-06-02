import 'package:flutter/material.dart';
import '../models/chatListItemModel.dart';
import '../screens/chatRoomScreen.dart';

class ChatTile extends StatelessWidget {
  final ChatListItem item;

  const ChatTile({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainer,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: item.profilePhoto != null ? NetworkImage(item.profilePhoto!) : null,
          backgroundColor: colorScheme.primary.withOpacity(0.2),
          child: item.profilePhoto == null
              ? Icon(item.isGroup ? Icons.group : Icons.person, color: colorScheme.primary)
              : null,
        ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: item.subtitle != null && item.subtitle!.isNotEmpty
            ? Text(
                item.subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.lastTimestamp != null)
              Text(
                _formatTime(item.lastTimestamp!),
                style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            const SizedBox(height: 4),
            item.unreadCount > 0
                ? CircleAvatar(
                    radius: 11,
                    backgroundColor: colorScheme.primary,
                    child: Text(
                      item.unreadCount > 99 ? '99+' : item.unreadCount.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : Icon(Icons.chevron_right, color: colorScheme.outline),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(
                chatId: item.chatId,
                peerId: item.peerUid ?? '',
                peerName: item.title,
                peerPhoto: item.profilePhoto,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${dt.day}/${dt.month}';
  }
}
