import 'package:flutter/material.dart';
import '../models/messageModel.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String? peerPhoto;
  final String? peerUid; // For read receipts

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.peerPhoto,
    this.peerUid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = isMe ? Colors.tealAccent : Colors.grey[300];
    final textColor = isMe ? Colors.black : Colors.black87;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
      bottomLeft: isMe ? Radius.circular(12) : Radius.circular(0),
      bottomRight: isMe ? Radius.circular(0) : Radius.circular(12),
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
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: radius,
              ),
              child: Column(
                crossAxisAlignment: align,
                children: [
                  if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        message.mediaUrl!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey[400],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                    : null,
                                color: Colors.teal,
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
                  SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      if (isMe) ...[
                        SizedBox(width: 4),
                        Icon(
                          isRead ? Icons.done_all : Icons.done,
                          size: 16,
                          color: isRead ? Colors.blue : Colors.grey[600],
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
      // Today
      final hours = dt.hour.toString().padLeft(2, '0');
      final mins = dt.minute.toString().padLeft(2, '0');
      return "$hours:$mins";
    } else if (difference == 1) {
      // Yesterday
      return "Yesterday";
    } else {
      // Older messages
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      return "$day/$month/$year";
    }
  }

}
