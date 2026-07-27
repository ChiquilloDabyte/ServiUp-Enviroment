import 'package:flutter/material.dart';

import '../../core/theme/app_dimensions.dart';

typedef ProposalResult = ({double price, String conditions});

class ProposalDialog extends StatefulWidget {
  const ProposalDialog({super.key});

  @override
  State<ProposalDialog> createState() => _ProposalDialogState();
}

class _ProposalDialogState extends State<ProposalDialog> {
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
    Navigator.pop<ProposalResult>(context, (
      price: price,
      conditions: _conditionsController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.handshake_outlined),
      title: const Text('Nueva propuesta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Precio',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _conditionsController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Condiciones o detalles',
              alignLabelWithHint: true,
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
