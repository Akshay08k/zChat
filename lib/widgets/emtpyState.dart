import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onStartChat;
  final VoidCallback onCreateGroup;

  const EmptyState({Key? key, required this.onStartChat, required this.onCreateGroup}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No conversations yet', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onStartChat,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Start a chat'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[700]),
          ),
          TextButton.icon(
            onPressed: onCreateGroup,
            icon: const Icon(Icons.group_add, color: Colors.blueGrey),
            label: const Text('Create a group', style: TextStyle(color: Colors.blueGrey)),
          ),
        ],
      ),
    );
  }
}
