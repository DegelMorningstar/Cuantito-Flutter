import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Placeholder del listado de movimientos del mes + totales.
/// Implementación real en F7.
class MovementsListPage extends StatelessWidget {
  const MovementsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Lista de movimientos (placeholder · F7)'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/movements/detail/1'),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Abrir detalle (ej. id=1)'),
            ),
          ],
        ),
      ),
    );
  }
}
