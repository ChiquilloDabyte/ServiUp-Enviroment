import 'package:flutter/material.dart';

import '../../core/theme/app_dimensions.dart';
import '../../models/chat_message_model.dart';
import '../../models/enums/message_type.dart';

class ChatMessagesList extends StatelessWidget {
  const ChatMessagesList({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.canLoadOlder,
    required this.onLoadOlder,
  });

  final List<ChatMessageModel> messages;
  final String currentUserId;
  final bool canLoadOlder;
  final VoidCallback onLoadOlder;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.mobileMargin,
        vertical: AppSpacing.sm,
      ),
      itemCount: messages.length + (canLoadOlder ? 1 : 0),
      itemBuilder: (context, index) {
        if (canLoadOlder && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Center(
              child: TextButton.icon(
                onPressed: onLoadOlder,
                icon: const Icon(Icons.history_rounded),
                label: const Text('Cargar mensajes anteriores'),
              ),
            ),
          );
        }

        final message = messages[index - (canLoadOlder ? 1 : 0)];
        return _MessageBubble(
          message: message,
          own: message.senderId == currentUserId,
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.own});

  final ChatMessageModel message;
  final bool own;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final availableWidth = MediaQuery.sizeOf(context).width;
    final maxBubbleWidth =
        (availableWidth * 0.76).clamp(240.0, 560.0).toDouble();
    final isImage =
        message.type == MessageType.image && message.imageUrl != null;

    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        padding: EdgeInsets.all(isImage ? AppSpacing.xxs : AppSpacing.sm),
        decoration: BoxDecoration(
          color: own ? colors.primaryContainer : colors.surfaceContainerHighest,
          border: Border.all(
            color:
                own
                    ? colors.primary.withValues(alpha: 0.18)
                    : colors.outlineVariant.withValues(alpha: 0.65),
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(own ? AppRadius.lg : AppRadius.sm),
            bottomRight: Radius.circular(own ? AppRadius.sm : AppRadius.lg),
          ),
        ),
        child:
            isImage
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.network(
                    message.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, _, _) => Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.broken_image_outlined),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Imagen no disponible',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                  ),
                )
                : Text(
                  message.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: own ? colors.onPrimaryContainer : colors.onSurface,
                  ),
                ),
      ),
    );
  }
}
