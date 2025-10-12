import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
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

  ChatRoomScreen({
    required this.chatId,
    required this.peerId,
    required this.peerName,
    this.peerPhoto,
  });

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _textController = TextEditingController();
  final ChatService _chatService = ChatService();
  final MediaService _mediaService = MediaService();
  late DatabaseReference _messagesRef;
  late StreamSubscription<DatabaseEvent> _msgSub;
  List<MessageModel> _messages = [];
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _messagesRef = _chatService.messagesRef(widget.chatId);

    // Listen to messages
    _msgSub = _messagesRef.onValue.listen((event) async {
      final map = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final list = <MessageModel>[];
      map.forEach((k, v) {
        try {
          list.add(MessageModel.fromJson(v));
        } catch (_) {}
      });
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      setState(() => _messages = list);

      // Mark messages read
      await _markMessagesRead();
    });
  }

  @override
  void dispose() {
    _msgSub.cancel();
    super.dispose();
  }

  // Mark messages as read for current user
  Future<void> _markMessagesRead() async {
    for (var msg in _messages) {
      if (msg.senderId != uid && (msg.isRead?[uid] ?? false) == false) {
        await _chatService.messagesRef(widget.chatId)
            .child(msg.id)
            .child('isRead')
            .child(uid)
            .set(true);
      }
    }
  }

  // Send text message
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey.shade900),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.teal.shade600,
              backgroundImage: widget.peerPhoto != null && widget.peerPhoto!.isNotEmpty
                  ? NetworkImage(widget.peerPhoto!)
                  : null,
              child: widget.peerPhoto == null || widget.peerPhoto!.isEmpty
                  ? Icon(Icons.person, color: Colors.white, size: 18)
                  : null,
            ),
            SizedBox(width: 12),
            Text(
              widget.peerName,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
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
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                ),
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
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.image_outlined, color: Colors.grey.shade600),
            onPressed: _sendImage,
            iconSize: 26,
            tooltip: 'Send Image',
          ),
          SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _textController,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade900),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.teal.shade600,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _sendText,
              tooltip: 'Send',
            ),
          ),
        ],
      ),
    );
  }
}