import '../../domain/repositories/category_repository.dart';

/// Categorías iniciales (decisión F0: hacer seed). Sus `iconName` coinciden con
/// claves del catálogo de iconos de presentación (`icon_catalog.dart`).
const List<({String name, String iconName})> kInitialCategories = [
  (name: 'Comida', iconName: 'Filled.Restaurant'),
  (name: 'Transporte', iconName: 'Filled.DirectionsCar'),
  (name: 'Hogar', iconName: 'Filled.Home'),
  (name: 'Salud', iconName: 'Filled.LocalHospital'),
  (name: 'Entretenimiento', iconName: 'Filled.Movie'),
  (name: 'Salario', iconName: 'Filled.AttachMoney'),
];

/// Inserta las categorías iniciales **solo si la tabla está vacía** (mitiga
/// R-03: evita que `categories.first()` reviente sin datos). Se ejecuta tras la
/// migración legada (F3), de modo que no duplica datos ya importados.
Future<bool> seedCategoriesIfEmpty(CategoryRepository repository) async {
  if ((await repository.getAll()).isNotEmpty) return false;
  for (final c in kInitialCategories) {
    await repository.add(name: c.name, iconName: c.iconName);
  }
  return true;
}
