import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/chat_viewmodel.dart';
import '../../domain/viewmodels/offer_viewmodel.dart';
import '../../models/chat_model.dart';
import '../../models/enums/chat_status.dart';
import '../../models/enums/message_type.dart';
import '../../models/enums/offer_status.dart';
import '../../models/offer_model.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading_view.dart';

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
    final result = await showDialog<({double price, String conditions})>(
      context: context,
      builder: (context) => const _ProposalDialog(),
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
          return Column(
            children: [
              offers.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
                data:
                    (items) => _OfferPanel(
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
                  data: (items) {
                    final canLoadOlder = items.length >= _messageLimit;
                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length + (canLoadOlder ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (canLoadOlder && index == 0) {
                          return Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() => _messageLimit += 50);
                              },
                              child: const Text('Cargar mensajes anteriores'),
                            ),
                          );
                        }
                        final message = items[index - (canLoadOlder ? 1 : 0)];
                        final own = message.senderId == currentUser.id;
                        return Align(
                          alignment:
                              own
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 300),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  own
                                      ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                      : Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child:
                                message.type == MessageType.image &&
                                        message.imageUrl != null
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        message.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, _, _) => const Text(
                                              'Imagen no disponible',
                                            ),
                                      ),
                                    )
                                    : Text(message.text),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (!writable)
                const MaterialBanner(
                  content: Text(
                    'Esta conversación está disponible solo para lectura.',
                  ),
                  actions: [SizedBox.shrink()],
                )
              else
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Enviar imagen',
                          onPressed:
                              sending
                                  ? null
                                  : () => _sendImage(chat, currentUser.id),
                          icon: const Icon(Icons.image_outlined),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            maxLength: 2000,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Escribe un mensaje',
                              counterText: '',
                            ),
                          ),
                        ),
                        IconButton.filled(
                          tooltip: 'Enviar',
                          onPressed:
                              sending
                                  ? null
                                  : () => _sendText(chat, currentUser.id),
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProposalDialog extends StatefulWidget {
  const _ProposalDialog();

  @override
  State<_ProposalDialog> createState() => _ProposalDialogState();
}

class _ProposalDialogState extends State<_ProposalDialog> {
  final _priceController = TextEditingController();
  final _conditionsController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  void _submit() {
    final price = double.tryParse(_priceController.text.replaceAll(',', '.'));
    if (price == null || price <= 0) return;
    Navigator.pop(context, (
      price: price,
      conditions: _conditionsController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva propuesta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Precio'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _conditionsController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Condiciones o detalles',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Enviar')),
      ],
    );
  }
}

class _OfferPanel extends StatelessWidget {
  const _OfferPanel({
    required this.offers,
    required this.userId,
    required this.writable,
    required this.onNewProposal,
    required this.onAccept,
    required this.onReject,
  });

  final List<OfferModel> offers;
  final String userId;
  final bool writable;
  final VoidCallback onNewProposal;
  final ValueChanged<OfferModel> onAccept;
  final ValueChanged<OfferModel> onReject;

  @override
  Widget build(BuildContext context) {
    final active =
        offers
            .where((offer) => offer.status == OfferStatus.pending)
            .firstOrNull;
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        leading: const Icon(Icons.handshake_outlined),
        title: Text(
          active == null
              ? 'Historial de propuestas'
              : 'Propuesta: ${formatCurrency(active.proposedPrice)}',
        ),
        subtitle:
            active == null
                ? Text('${offers.length} propuesta(s)')
                : Text(
                  active.conditions?.isNotEmpty == true
                      ? active.conditions!
                      : 'Sin condiciones adicionales',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        trailing:
            writable
                ? IconButton(
                  tooltip: 'Nueva propuesta',
                  onPressed: onNewProposal,
                  icon: const Icon(Icons.add),
                )
                : null,
        children: [
          if (active != null && active.createdById != userId && writable)
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => onReject(active),
                  child: const Text('Rechazar'),
                ),
                FilledButton(
                  onPressed: () => onAccept(active),
                  child: const Text('Aceptar'),
                ),
              ],
            ),
          for (final offer in offers)
            ListTile(
              dense: true,
              title: Text(
                'Versión ${offer.revision}: '
                '${formatCurrency(offer.proposedPrice)}',
              ),
              subtitle: Text(offer.conditions ?? offer.message),
              trailing: Text(offer.status.label),
            ),
        ],
      ),
    );
  }
}
