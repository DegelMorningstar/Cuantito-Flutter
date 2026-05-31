import '../models/category.dart';

/// Contrato de acceso a categorías. La implementación vive en `data/`.
abstract interface class CategoryRepository {
  /// Todas las categorías, ordenadas por nombre.
  Future<List<Category>> getAll();

  Future<Category?> getById(int id);

  /// Verdadero si ya existe una categoría con ese `name` exacto (RN-005).
  Future<bool> existsByName(String name);

  /// Inserta la categoría y devuelve su `id` generado.
  Future<int> add({required String name, required String iconName});
}
