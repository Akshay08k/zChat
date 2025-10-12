import 'package:flutter/material.dart';
import '../models/chatListItemModel.dart';
import '../screens/chatRoomScreen.dart';

class ChatTile extends StatelessWidget {
  final ChatListItem item;

  const ChatTile({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: item.profilePhoto != null ? NetworkImage(item.profilePhoto!) : null,
          backgroundColor: Colors.blueGrey[200],
          child: item.profilePhoto == null
              ? Icon(item.isGroup ? Icons.group : Icons.person, color: Colors.white)
              : null,
        ),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,style: TextStyle(color: Colors.black),),
        subtitle: item.subtitle != null
            ? Text(item.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis,style: TextStyle(color: Colors.grey),)
            : null,
        trailing: item.unreadCount > 0
            ? CircleAvatar(
          radius: 12,
          backgroundColor: Colors.redAccent,
          child: Text(
            item.unreadCount.toString(),
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        )
            : const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(
                chatId: item.chatId,
                peerId:item.peerUid ?? '',
                peerName: item.title,
                peerPhoto: item.profilePhoto,
              ),
            ),
          );
        },
      ),
    );
  }
}
