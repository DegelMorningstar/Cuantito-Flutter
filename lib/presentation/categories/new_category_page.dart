import 'package:flutter/material.dart';

/// Placeholder de la creación de categoría (nombre + icono).
/// Implementación real en F5.
class NewCategoryPage extends StatelessWidget {
  const NewCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva categoría')),
      body: const Center(
        child: Text('Crear categoría (placeholder · F5)'),
      ),
    );
  }
}
