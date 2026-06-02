import 'package:flutter/material.dart';
import '../models/messageModel.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String? peerPhoto;
  final String? peerUid;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.peerPhoto,
    this.peerUid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isMe ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest;
    final textColor = isMe ? colorScheme.onPrimaryContainer : colorScheme.onSurface;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
    );

    bool isRead = false;
    if (isMe && peerUid != null) {
      isRead = message.isRead?[peerUid!] ?? false;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: radius,
              ),
              child: Column(
                crossAxisAlignment: align,
                children: [
                  if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        message.mediaUrl!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return SizedBox(
                            width: 200,
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (message.text.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: message.mediaUrl != null ? 8.0 : 0),
                      child: Text(
                        message.text,
                        style: TextStyle(color: textColor, fontSize: 15),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isRead ? Icons.done_all : Icons.done,
                          size: 16,
                          color: isRead ? Colors.blue : colorScheme.onSurfaceVariant,
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(dt.year, dt.month, dt.day);

    final difference = today.difference(msgDate).inDays;

    if (difference == 0) {
      final hours = dt.hour.toString().padLeft(2, '0');
      final mins = dt.minute.toString().padLeft(2, '0');
      return '$hours:$mins';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      return '$day/$month/$year';
    }
  }
}
