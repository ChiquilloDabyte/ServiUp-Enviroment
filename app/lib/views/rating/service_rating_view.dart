import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/firestore_service.dart';

class ServiceRatingView extends StatefulWidget {
  const ServiceRatingView({
    super.key,
    required this.requestId,
    required this.providerId,
    required this.clientId,
  });

  final String requestId;
  final String providerId;
  final String clientId;

  @override
  State<ServiceRatingView> createState() => _ServiceRatingViewState();
}

class _ServiceRatingViewState extends State<ServiceRatingView> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  String get _ratingText {
    switch (_rating) {
      case 1:
        return 'Muy malo';
      case 2:
        return 'Malo';
      case 3:
        return 'Regular';
      case 4:
        return 'Bueno';
      case 5:
        return 'Excelente';
      default:
        return 'Selecciona una calificación';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calificar servicio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.verified,
              color: Colors.green,
              size: 70,
            ),

            const SizedBox(height: 20),

            Text(
              'Servicio completado',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 12),

            const Text(
              '¿Cómo fue tu experiencia con el servicio?',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),
            Text(
              'Tu opinión ayuda a mejorar la calidad del servicio.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _ratingText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
                hintText: 'Cuéntanos cómo fue tu experiencia...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  if (_rating == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Selecciona una calificación antes de continuar.',
                        ),
                      ),
                    );
                    return;
                  }

                  final firestore = FirestoreService();

                  await firestore.ratings.add({
                    'requestId': widget.requestId,
                    'providerId': widget.providerId,
                    'clientId': widget.clientId,
                    'rating': _rating,
                    'comment': _commentController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Gracias por tu calificación!'),
                    ),
                  );

                  Navigator.pop(context);
                },
                icon: const Icon(Icons.send),
                label: const Text('Enviar calificación'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}