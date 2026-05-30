import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Placeholder de la selección de categoría para un movimiento.
/// Implementación real (catálogo de iconos, etc.) en F5.
class SelectCategoryPage extends StatelessWidget {
  const SelectCategoryPage({super.key, this.selectedCategoryId});

  final int? selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Seleccionar categoría (placeholder · F5)'),
            const SizedBox(height: 8),
            Text('seleccionada: ${selectedCategoryId ?? '—'}'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/categories/new'),
              icon: const Icon(Icons.add),
              label: const Text('Agregar categoría'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              // Simula devolver la categoría elegida a Nuevo movimiento.
              onPressed: () => context.go('/?categoryId=1'),
              child: const Text('Elegir categoría 1'),
            ),
          ],
        ),
      ),
    );
  }
}
