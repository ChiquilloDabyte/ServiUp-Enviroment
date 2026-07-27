import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    required this.message,
    required this.onViewDirectory,
  });

  final String message;
  final VoidCallback onViewDirectory;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      leading: const Icon(Icons.cloud_off_outlined),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: onViewDirectory,
          child: const Text('Ver directorio'),
        ),
      ],
    );
  }
}
