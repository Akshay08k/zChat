import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/chatTitle.dart';
import '../widgets/emtpyState.dart';
import '../dialogs/startChatDialog.dart';
import '../dialogs/createGroupDialog.dart';
import '../services/authService.dart';
import '../services/chatService.dart';
import '../models/chatListItemModel.dart';
import 'profileScreen.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  String? username;
  String? profilePhoto;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    final uid = Provider.of<AuthService>(context, listen: false).currentUser!.uid;
  }

 @override
  void dispose() {
    final uid = Provider.of<AuthService>(context, listen: false).currentUser!.uid;
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final data = await Provider.of<AuthService>(context, listen: false).getUserData();
    setState(() {
      username = data['username'];
      profilePhoto = data['photoUrl'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser!;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen())),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: CircleAvatar(
              backgroundColor: Colors.teal.shade600,
              backgroundImage: (profilePhoto != null && profilePhoto!.isNotEmpty) ? NetworkImage(profilePhoto!) : null,
              child: (profilePhoto == null || profilePhoto!.isEmpty)
                  ? Text(
                username != null ? username![0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              )
                  : null,
            ),
          ),
        ),
        title: Text(
          'Chats',
          style: TextStyle(
            color: Colors.grey.shade900,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_alt_1_outlined, color: Colors.grey.shade700),
            onPressed: () => showStartChatDialog(context),
            tooltip: 'Start Chat',
          ),
          IconButton(
            icon: Icon(Icons.group_add_outlined, color: Colors.grey.shade700),
            onPressed: () => showCreateGroupDialog(context),
            tooltip: 'Create Group',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
            offset: Offset(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'logout') auth.signOut();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.grey.shade700, size: 20),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _db.child('userChats/${user.uid}').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.teal.shade600,
                strokeWidth: 2.5,
              ),
            );
          }

          final event = snapshot.data as DatabaseEvent?;
          final chatsIndex = event?.snapshot.value as Map<dynamic, dynamic>?;

          if (chatsIndex == null || chatsIndex.isEmpty) {
            return EmptyState(
              onStartChat: () => showStartChatDialog(context),
              onCreateGroup: () => showCreateGroupDialog(context),
            );
          }

          final chatIds = chatsIndex.keys.map((e) => e.toString()).toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: chatIds.length,
            itemBuilder: (context, index) {
              final chatId = chatIds[index];
              return StreamBuilder(
                stream: _db.child('chats/$chatId/lastMessage').onValue,
                builder: (context, msgSnapshot) {
                  final lastMsgData = (msgSnapshot.data as DatabaseEvent?)
                      ?.snapshot
                      .value as Map<dynamic, dynamic>? ??
                      {};

                  final unreadMap = (lastMsgData['unread'] as Map<dynamic, dynamic>? ?? {});
                  final unreadCount = (unreadMap[user.uid] as int?) ?? 0;

                  return FutureBuilder<ChatListItem?>(
                    future: _buildChatListItem(chatId, user.uid, unreadCount),
                    builder: (context, chatItemSnapshot) {
                      if (!chatItemSnapshot.hasData) {
                        return SizedBox.shrink();
                      }
                      final item = chatItemSnapshot.data!;
                      return ChatTile(item: item);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<ChatListItem?> _buildChatListItem(String chatId, String myUid, int unreadCount) async {
    final chatSnap = await _db.child('chats/$chatId/meta').get();
    final chatData = chatSnap.value as Map<dynamic, dynamic>?;

    if (chatData == null) return null;

    final membersMap = (chatData['members'] as Map<dynamic, dynamic>? ?? {});
    final members = membersMap.keys.cast<String>().toList();
    final isGroup = (chatData['type'] as String? ?? 'direct') == 'group';

    final lastMessageSnap = await _db.child('chats/$chatId/lastMessage').get();
    final lastMessageData = lastMessageSnap.value as Map<dynamic, dynamic>? ?? {};
    final lastText = lastMessageData['text'] as String?;
    final lastTimestamp = lastMessageData['timestamp'] as int?;


    //checking it is group or not
    if (isGroup) {
      final groupName = chatData['name'] as String? ?? 'Group Chat';
      return ChatListItem(
        chatId: chatId,
        title: groupName,
        subtitle: lastText,
        isGroup: true,
        unreadCount: unreadCount,
        lastTimestamp: lastTimestamp,
      );
    } else {
      final peerUid = members.firstWhere((uid) => uid != myUid, orElse: () => '');
      if (peerUid.isEmpty) return null;

      final peerSnap = await _db.child('users/$peerUid').get();
      final peerData = peerSnap.value as Map<dynamic, dynamic>?;

      final peerName = peerData?['name'] as String? ?? 'User';
      final username = peerData?['username'] as String?;
      final profilePhoto = peerData?['photoUrl'] as String?;

      return ChatListItem(
        chatId: chatId,
        title: peerName,
        subtitle: username != null ? '@$username' : lastText,
        isGroup: false,
        peerUid: peerUid,
        unreadCount: unreadCount,
        profilePhoto: profilePhoto,
        lastTimestamp: lastTimestamp,
      );
    }
  }
}
