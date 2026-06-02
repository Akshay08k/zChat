import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../services/chatService.dart';
import '../services/mediaService.dart';
import '../models/messageModel.dart';
import '../widgets/messageBubble.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String peerId;
  final String peerName;
  final String? peerPhoto;

  const ChatRoomScreen({
    required this.chatId,
    required this.peerId,
    required this.peerName,
    this.peerPhoto,
    super.key,
  });

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _textController = TextEditingController();
  final ChatService _chatService = ChatService();
  final MediaService _mediaService = MediaService();
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  late DatabaseReference _messagesRef;
  late StreamSubscription<DatabaseEvent> _msgSub;
  List<MessageModel> _messages = [];
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _messagesRef = _chatService.messagesRef(widget.chatId);

    _msgSub = _messagesRef.onValue.listen((event) async {
      final map = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final list = <MessageModel>[];

      map.forEach((key, value) {
        try {
          list.add(MessageModel.fromJson(value));
        } catch (_) {}
      });

      // Sort messages by timestamp
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      setState(() => _messages = list);
      await _markMessagesRead();
    });
  }

  @override
  void dispose() {
    _msgSub.cancel();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _markMessagesRead() async {
    for (var msg in _messages) {
      if (msg.senderId != uid && (msg.isRead?[uid] ?? false) == false) {
        await _chatService.messagesRef(widget.chatId).child(msg.id).child('isRead').child(uid).set(true);
      }
    }
  }

  void _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final chatMeta = await _chatService.chatMeta(widget.chatId);
    final members = (chatMeta?['members'] as Map?)?.keys.cast<String>().toList() ?? [];
    final isReadMap = {for (var m in members) m: m == uid};

    final msg = MessageModel(
      id: const Uuid().v4(),
      senderId: uid,
      text: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      isRead: isReadMap,
    );

    await _chatService.sendMessage(chatId: widget.chatId, message: msg);
    _textController.clear();
  }

  // Send an image message
  void _sendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final url = await _mediaService.uploadImageToCloudinary(file);
    if (url == null) return;

    final chatMeta = await _chatService.chatMeta(widget.chatId);
    final members = (chatMeta?['members'] as Map?)?.keys.cast<String>().toList() ?? [];
    final isReadMap = {for (var m in members) m: m == uid};

    final msg = MessageModel(
      id: const Uuid().v4(),
      senderId: uid,
      text: '',
      mediaUrl: url,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      isRead: isReadMap,
    );

    await _chatService.sendMessage(chatId: widget.chatId, message: msg);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primary,
              backgroundImage: widget.peerPhoto != null && widget.peerPhoto!.isNotEmpty ? NetworkImage(widget.peerPhoto!) : null,
              child: widget.peerPhoto == null || widget.peerPhoto!.isEmpty
                  ? Icon(Icons.person, color: colorScheme.onPrimary, size: 18)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  _buildPresenceStatus(theme),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[_messages.length - 1 - index];
                      return MessageBubble(
                        message: msg,
                        isMe: msg.senderId == uid,
                        peerUid: widget.peerId,
                        peerPhoto: widget.peerPhoto,
                      );
                    },
                  ),
          ),
          _buildInputBar(colorScheme),
        ],
      ),
    );
  }

  Widget _buildPresenceStatus(ThemeData theme) {
    if (widget.peerId.isEmpty) {
      return Text(
        'Group chat',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: _db.child('presence/${widget.peerId}').onValue,
      builder: (context, snapshot) {
        final raw = snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;
        final isOnline = raw?['isOnline'] == true;
        final statusText = isOnline ? 'online' : _lastSeenLabel(raw?['lastSeen'] as int?);

        return Text(
          statusText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isOnline ? Colors.green : theme.colorScheme.onSurfaceVariant,
            fontWeight: isOnline ? FontWeight.w600 : FontWeight.w400,
          ),
        );
      },
    );
  }

  String _lastSeenLabel(int? timestamp) {
    if (timestamp == null) return 'offline';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;

    if (isToday) {
      return 'last seen ${DateFormat.Hm().format(dt)}';
    }
    return 'last seen ${DateFormat('d MMM, HH:mm').format(dt)}';
  }

  Widget _buildInputBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.image_outlined, color: colorScheme.primary),
            onPressed: _sendImage,
            iconSize: 24,
            tooltip: 'Send Image',
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendText(),
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send_rounded, color: colorScheme.onPrimary, size: 20),
              onPressed: _sendText,
              tooltip: 'Send',
            ),
          ),
        ],
      ),
    );
  }
}
