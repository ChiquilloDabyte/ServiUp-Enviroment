import 'package:flutter/material.dart';

import '../models/user_model.dart';

class ProviderCard extends StatelessWidget {
  const ProviderCard({
    super.key, 
    required this.provider, 
    this.onTap
  });

  final UserModel provider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: provider.photoUrl != null
            ? CircleAvatar(backgroundImage: NetworkImage(provider.photoUrl!))
            : const CircleAvatar(child: Icon(Icons.person)),
        title: Text(provider.name),
        subtitle: provider.serviceCategories.isEmpty
            ? const Text('Sin categorías registradas')
            : Wrap(
                spacing: 6,
                runSpacing: 4,
                children: provider.serviceCategories
                    .map((c) => Chip(label: Text(c)))
                    .toList(),
              ),
        trailing: provider.rating > 0
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(provider.rating.toStringAsFixed(1)),
                ],
              )
            : null,
      ),
    );
  }
}