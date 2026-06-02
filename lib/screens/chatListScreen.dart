import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/chatTitle.dart';
import '../widgets/emtpyState.dart';
import '../dialogs/startChatDialog.dart';
import '../dialogs/createGroupDialog.dart';
import '../services/authService.dart';
import '../services/chatService.dart';
import '../services/themeService.dart';
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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    final uid = Provider.of<AuthService>(context, listen: false).currentUser!.uid;
    Provider.of<ChatService>(context, listen: false).setUserOnline(uid, true);
  }

  @override
  void dispose() {
    final uid = Provider.of<AuthService>(context, listen: false).currentUser!.uid;
    Provider.of<ChatService>(context, listen: false).setUserOnline(uid, false);
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final data = await Provider.of<AuthService>(context, listen: false).getUserData();
    setState(() {
      username = data['username'];
      profilePhoto = data['photoUrl'];
    });
  }

  void _onMenuSelected(String value) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final themeService = Provider.of<ThemeService>(context, listen: false);

    switch (value) {
      case 'theme_light':
        themeService.setThemeMode(ThemeMode.light);
        break;
      case 'theme_dark':
        themeService.setThemeMode(ThemeMode.dark);
        break;
      case 'theme_system':
        themeService.setThemeMode(ThemeMode.system);
        break;
      case 'logout':
        auth.signOut();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen())),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: CircleAvatar(
              backgroundColor: colorScheme.primary,
              backgroundImage: (profilePhoto != null && profilePhoto!.isNotEmpty) ? NetworkImage(profilePhoto!) : null,
              child: (profilePhoto == null || profilePhoto!.isEmpty)
                  ? Text(
                      username != null ? username![0].toUpperCase() : '?',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        title: const Text(
          'zChat',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => showStartChatDialog(context),
            tooltip: 'Start Chat',
          ),
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            onPressed: () => showCreateGroupDialog(context),
            tooltip: 'Create Group',
          ),
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: _onMenuSelected,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'theme_light', child: Text('Theme: Light')),
              PopupMenuItem(value: 'theme_dark', child: Text('Theme: Dark')),
              PopupMenuItem(value: 'theme_system', child: Text('Theme: System')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search chats or messages',
                prefixIcon: const Icon(Icons.search),
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _db.child('userChats/${user.uid}').onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 2.5));
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

                return FutureBuilder<List<ChatListItem>>(
                  future: _loadChatListItems(chatIds, user.uid),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                          strokeWidth: 2.5,
                        ),
                      );
                    }
                    final items = snap.data!;
                    if (items.isEmpty) {
                      return EmptyState(
                        onStartChat: () => showStartChatDialog(context),
                        onCreateGroup: () => showCreateGroupDialog(context),
                      );
                    }

                    final filteredItems = _searchQuery.isEmpty
                        ? items
                        : items.where((item) {
                            final title = item.title.toLowerCase();
                            final subtitle = item.subtitle?.toLowerCase() ?? '';
                            return title.contains(_searchQuery) || subtitle.contains(_searchQuery);
                          }).toList();

                    if (filteredItems.isEmpty) {
                      return Center(
                        child: Text(
                          'No chats match "$_searchQuery"',
                          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) => ChatTile(item: filteredItems[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<ChatListItem>> _loadChatListItems(List<String> chatIds, String myUid) async {
    final db = FirebaseDatabase.instance.ref();
    final futures = chatIds.map((chatId) async {
      final chatSnap = await db.child('chats/$chatId/meta').get();
      final chatData = chatSnap.value as Map<dynamic, dynamic>?;
      if (chatData == null) return null;

      final membersMap = (chatData['members'] as Map<dynamic, dynamic>? ?? {});
      final members = membersMap.keys.cast<String>().toList();
      final isGroup = (chatData['type'] as String? ?? 'direct') == 'group';

      final lastMessageSnap = await db.child('chats/$chatId/lastMessage').get();
      final lastMessageData = lastMessageSnap.value as Map<dynamic, dynamic>? ?? {};
      final lastText = lastMessageData['text'] as String?;
      final lastTimestamp = lastMessageData['timestamp'] as int?;
      final unreadCount = (lastMessageData['unread'] as Map<dynamic, dynamic>? ?? {})[myUid] as int? ?? 0;

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

        final peerSnap = await db.child('users/$peerUid').get();
        final peerData = peerSnap.value as Map<dynamic, dynamic>?;

        final peerName = peerData?['name'] as String? ?? 'User';
        final profilePhoto = peerData?['photoUrl'] as String?;

        return ChatListItem(
          chatId: chatId,
          title: peerName,
          subtitle: lastText,
          isGroup: false,
          peerUid: peerUid,
          unreadCount: unreadCount,
          profilePhoto: profilePhoto,
          lastTimestamp: lastTimestamp,
        );
      }
    }).toList();

    final results = await Future.wait(futures);
    final items = results.whereType<ChatListItem>().toList();
    items.sort((a, b) => (b.lastTimestamp ?? 0).compareTo(a.lastTimestamp ?? 0));
    return items;
  }
}
