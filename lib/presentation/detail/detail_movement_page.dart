import 'package:flutter/material.dart';

/// Placeholder del detalle de un movimiento (con opción de eliminar).
/// Implementación real en F8.
class DetailMovementPage extends StatelessWidget {
  const DetailMovementPage({super.key, required this.movementId});

  final int movementId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: Center(
        child: Text('Detalle del movimiento #$movementId (placeholder · F8)'),
      ),
    );
  }
}
