import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../models/messageModel.dart';
import 'notificationService.dart';
class ChatService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Create or get chat ID for 1-1 (sorted user ids)
  String chatIdFor(String a, String b) {
    final list = [a, b]..sort();
    return list.join('_');
  }

  Future<String?> _uidForUsername(String username) async {
    final snap = await _db.child('usernames/${username.trim().toLowerCase()}').get();
    return snap.value as String?;
  }

  Future<String> ensureDirectChatByUsername({required String myUid, required String targetUsername}) async {
    final otherUid = await _uidForUsername(targetUsername);
    if (otherUid == null) throw Exception('User "$targetUsername" not found');
    if (otherUid == myUid) throw Exception('Cannot chat with yourself');


    final chatId = chatIdFor(myUid, otherUid);
    final chatMetaRef = _db.child('chats/$chatId/meta');
    final metaSnap = await chatMetaRef.get();

    if (metaSnap.value == null) {
      await chatMetaRef.set({
        'type': 'direct',
        'members': {myUid: true, otherUid: true},
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      // Index chat for both users
      await _db.child('userChats/$myUid/$chatId').set({'peerUid': otherUid});
      await _db.child('userChats/$otherUid/$chatId').set({'peerUid': myUid});
    }
    return chatId;
  }

  Future<Map<String, dynamic>?> chatMeta(String chatId) async {
    final snap = await _db.child('chats/$chatId/meta').get();
    return (snap.value as Map?)?.cast<String, dynamic>();
  }

  Future<void> sendMessage({
    required String chatId,
    required MessageModel message,
    bool sendNotification = true, //No Notification Spam
  }) async {
    final ref = _db.child('chats/$chatId/messages/${message.id}');

    final chatMetaSnap = await _db.child('chats/$chatId/meta/members').get();
    final membersMap = (chatMetaSnap.value as Map?)?.cast<String, bool>() ?? {};

    final isReadMap = {for (var uid in membersMap.keys) uid: uid == message.senderId};

    final msgData = {
      ...message.toJson(),
      'isRead': isReadMap,
      'notificationSent': sendNotification,
    };

    await ref.set(msgData);

    await _db.child('chats/$chatId/lastMessage').set({
      'text': message.text,
      'timestamp': message.timestamp,
      'senderId': message.senderId,
      'isRead': isReadMap,
    });

    if (sendNotification) {
      final senderSnap = await _db.child('users/${message.senderId}').get();
      final senderName = (senderSnap.value as Map?)?['name'] ?? 'Someone';

      for (final uid in membersMap.keys) {
        if (uid == message.senderId) continue;

        final tokenSnap = await _db.child('fcmTokens/$uid').get();
        final token = tokenSnap.value as String?;
        if (token != null) {
          await NotificationService.sendPushNotification(
            fcmToken: token,
            title: senderName,
            body: message.text,
          );
        }
      }
    }
  }


  DatabaseReference messagesRef(String chatId) => _db.child('chats/$chatId/messages');

  Future<void> setUserOnline(String uid, bool online) async {
    await _db.child('presence/$uid').set({
      'isOnline': online,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    });
  }
  Future<String> createGroup({required String name, required String creatorUid, required List<String> memberUsernames}) async {
    final memberUids = <String>{creatorUid};
    for (final uname in memberUsernames) {
      if (uname.trim().isEmpty) continue;
      final uid = await _uidForUsername(uname);
      if (uid != null) memberUids.add(uid);
    }
    if (memberUids.length < 2) throw Exception('Add at least one more member');

    final groupId = const Uuid().v4();
    await _db.child('chats/$groupId/meta').set({
      'type': 'group',
      'name': name,
      'members': {for (final id in memberUids) id: true},
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'createdBy': creatorUid,
    });
    for (final uid in memberUids) {
      await _db.child('userChats/$uid/$groupId').set({'group': true});
    }
    return groupId;
  }
}
