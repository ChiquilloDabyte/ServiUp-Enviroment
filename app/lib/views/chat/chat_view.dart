import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_dimensions.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/chat_viewmodel.dart';
import '../../domain/viewmodels/offer_viewmodel.dart';
import '../../models/chat_model.dart';
import '../../models/enums/chat_status.dart';
import '../../models/offer_model.dart';
import '../../widgets/chat/chat_composer.dart';
import '../../widgets/chat/chat_messages_list.dart';
import '../../widgets/chat/chat_offer_panel.dart';
import '../../widgets/chat/proposal_dialog.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/responsive_content.dart';

class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final _messageController = TextEditingController();
  final _picker = ImagePicker();
  int _messageLimit = 50;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendText(ChatModel chat, String userId) async {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;
    try {
      await ref
          .read(chatViewModelProvider.notifier)
          .sendText(chat: chat, senderId: userId, text: text);
      _messageController.clear();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _sendImage(ChatModel chat, String userId) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (image == null) return;
    try {
      await ref
          .read(chatViewModelProvider.notifier)
          .sendImage(chat: chat, senderId: userId, file: File(image.path));
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _showProposalDialog(ChatModel chat, String userId) async {
    final result = await showDialog<ProposalResult>(
      context: context,
      builder: (context) => const ProposalDialog(),
    );
    if (result == null) return;

    final user = ref.read(currentUserProfileProvider).value;
    try {
      await ref
          .read(offerViewModelProvider.notifier)
          .createProposal(
            chatId: chat.id,
            actorId: userId,
            actorRole: user?.role.value ?? 'client',
            proposedPrice: result.price,
            conditions: result.conditions,
          );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _accept(OfferModel offer, String userId) async {
    try {
      await ref
          .read(offerViewModelProvider.notifier)
          .acceptOffer(offer: offer, actorId: userId);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _reject(OfferModel offer, String userId) async {
    try {
      await ref
          .read(offerViewModelProvider.notifier)
          .rejectOffer(offer: offer, actorId: userId);
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(chatErrorMessage(error))));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProfileProvider).value;
    final chatState = ref.watch(chatDetailProvider(widget.chatId));
    final messages = ref.watch(
      chatMessagePageProvider((chatId: widget.chatId, limit: _messageLimit)),
    );
    final offers = ref.watch(chatOffersProvider(widget.chatId));
    final sending = ref.watch(chatViewModelProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Conversación')),
      body: chatState.when(
        loading: () => const LoadingView(),
        error: (error, _) => Center(child: Text(chatErrorMessage(error))),
        data: (chat) {
          if (chat == null || currentUser == null) {
            return const Center(child: Text('Conversación no encontrada.'));
          }
          if (!chat.containsParticipant(currentUser.id)) {
            return const Center(child: Text('No tienes acceso a este chat.'));
          }
          if (chat.unreadFor(currentUser.id) > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref
                  .read(chatViewModelProvider.notifier)
                  .markAsRead(chat, currentUser.id);
            });
          }

          final writable = chat.status == ChatStatus.active;
          return ResponsiveContent(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                offers.when(
                  loading: () => const LinearProgressIndicator(minHeight: 4),
                  error: (_, _) => const SizedBox.shrink(),
                  data:
                      (items) => ChatOfferPanel(
                        offers: items,
                        userId: currentUser.id,
                        writable: writable,
                        onNewProposal:
                            () => _showProposalDialog(chat, currentUser.id),
                        onAccept: (offer) => _accept(offer, currentUser.id),
                        onReject: (offer) => _reject(offer, currentUser.id),
                      ),
                ),
                Expanded(
                  child: messages.when(
                    loading: () => const LoadingView(),
                    error:
                        (error, _) =>
                            Center(child: Text(chatErrorMessage(error))),
                    data:
                        (items) => ChatMessagesList(
                          messages: items,
                          currentUserId: currentUser.id,
                          canLoadOlder: items.length >= _messageLimit,
                          onLoadOlder:
                              () => setState(() => _messageLimit += 50),
                        ),
                  ),
                ),
                if (!writable)
                  const _ReadOnlyNotice()
                else
                  ChatComposer(
                    controller: _messageController,
                    sending: sending,
                    onSendImage: () => _sendImage(chat, currentUser.id),
                    onSendText: () => _sendText(chat, currentUser.id),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.mobileMargin,
          AppSpacing.xs,
          AppSpacing.mobileMargin,
          AppSpacing.sm,
        ),
        padding: const EdgeInsets.all(AppSpacing.gutter),
        decoration: BoxDecoration(
          color: colors.secondaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: colors.onSecondaryContainer,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Esta conversación está disponible solo para lectura.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
