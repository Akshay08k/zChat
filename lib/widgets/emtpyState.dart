import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onStartChat;
  final VoidCallback onCreateGroup;

  const EmptyState({Key? key, required this.onStartChat, required this.onCreateGroup}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No conversations yet',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onStartChat,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Start a chat'),
          ),
          TextButton.icon(
            onPressed: onCreateGroup,
            icon: Icon(Icons.group_add, color: colorScheme.primary),
            label: Text('Create a group', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }
}
