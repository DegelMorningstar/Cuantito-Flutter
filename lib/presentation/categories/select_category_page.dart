import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../domain/models/category.dart';
import 'icon_catalog.dart';

/// Selección de la categoría para un movimiento (RN-006).
///
/// Devuelve la [Category] elegida con `context.pop(category)` —resultado de
/// navegación tipado, en lugar del `popUpTo` frágil del origen (R-09)—. El
/// botón "Agregar" abre [NewCategoryPage]; al volver, la lista se refresca
/// porque `categoriesProvider` se invalida tras crear una categoría.
class SelectCategoryPage extends ConsumerWidget {
  const SelectCategoryPage({super.key, this.selectedCategoryId});

  final int? selectedCategoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('newCategory'),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('No se pudieron cargar las categorías.\n$e',
                textAlign: TextAlign.center),
          ),
        ),
        data: (categories) => _CategoryList(
          categories: categories,
          // Si no llega selección, se preselecciona la primera (RN-006).
          selectedId: selectedCategoryId ??
              (categories.isEmpty ? null : categories.first.id),
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.categories, required this.selectedId});

  final List<Category> categories;
  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      // Estado vacío seguro: no revienta sin categorías (mitiga R-03).
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aún no tienes categorías.\nToca "Agregar" para crear la primera.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = category.id == selectedId;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              iconForName(category.iconName),
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(category.name),
          trailing: isSelected
              ? Icon(Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary)
              : null,
          selected: isSelected,
          onTap: () => context.pop(category),
        );
      },
    );
  }
}
