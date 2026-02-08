import 'package:flutter/material.dart';

class AvailabilityFilter extends StatelessWidget {
  final Map<String, dynamic> availability;
  final Function(Map<String, dynamic>) onAvailabilityChanged;

  const AvailabilityFilter({
    super.key,
    required this.availability,
    required this.onAvailabilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Disponibilidade',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF6A1B9A),
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Aberto agora'),
          value: availability['openNow'] ?? false,
          onChanged: (value) {
            onAvailabilityChanged({
              ...availability,
              'openNow': value ?? false,
            });
          },
          activeColor: const Color(0xFFFF6B35),
        ),
        CheckboxListTile(
          title: const Text('Urgências 24h'),
          value: availability['emergency24h'] ?? false,
          onChanged: (value) {
            onAvailabilityChanged({
              ...availability,
              'emergency24h': value ?? false,
            });
          },
          activeColor: const Color(0xFFFF6B35),
        ),
      ],
    );
  }
}