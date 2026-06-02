import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chatService.dart';
import '../services/authService.dart';
import '../screens/chatRoomScreen.dart';

Future<void> showStartChatDialog(BuildContext context) async {
  final controller = TextEditingController();
  await showDialog(
    context: context,
    builder: (ctx) {
      final colorScheme = Theme.of(ctx).colorScheme;
      return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start Chat',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a username to start chatting',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Enter username',
                prefixIcon: const Icon(Icons.alternate_email, size: 22),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final myUid = Provider.of<AuthService>(context, listen: false).currentUser!.uid;
                    final uname = controller.text.trim();
                    if (uname.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a username'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    try {
                      final chatId = await Provider.of<ChatService>(context, listen: false)
                          .ensureDirectChatByUsername(myUid: myUid, targetUsername: uname);
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomScreen(
                            chatId: chatId,
                            peerId: '',
                            peerName: '@$uname',
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  child: Text(
                  'Start Chat',
                  style: TextStyle(
                    fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    },
  );
}