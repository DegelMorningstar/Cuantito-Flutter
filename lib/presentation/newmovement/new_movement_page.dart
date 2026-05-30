import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Placeholder de la pantalla principal: registrar un nuevo movimiento.
/// Implementación real (teclado numérico, háptica, etc.) en F6.
class NewMovementPage extends StatelessWidget {
  const NewMovementPage({super.key, this.categoryId});

  /// Categoría seleccionada que regresa desde [SelectCategoryPage].
  final int? categoryId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo movimiento'),
        leading: IconButton(
          icon: const Icon(Icons.menu_book_outlined),
          tooltip: 'Onboarding',
          onPressed: () => context.go('/onboarding'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Nuevo movimiento (placeholder · F6)'),
            const SizedBox(height: 8),
            Text('categoryId recibido: ${categoryId ?? '—'}'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/categories'),
              icon: const Icon(Icons.category_outlined),
              label: const Text('Elegir categoría'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/movements'),
              icon: const Icon(Icons.list_alt_outlined),
              label: const Text('Ver movimientos'),
            ),
          ],
        ),
      ),
    );
  }
}
