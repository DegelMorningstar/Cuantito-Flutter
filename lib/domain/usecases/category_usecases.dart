import '../exceptions.dart';
import '../models/category.dart';
import '../repositories/category_repository.dart';

/// Crear una categoría validando nombre no vacío y unicidad (RN-005).
class AddCategory {
  const AddCategory(this._repository);
  final CategoryRepository _repository;

  /// Devuelve el id generado. Lanza [EmptyCategoryNameException] si el nombre
  /// (recortado) está vacío, o [CategoryAlreadyExistsException] si ya existe.
  Future<int> call({required String name, required String iconName}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const EmptyCategoryNameException();
    if (await _repository.existsByName(trimmed)) {
      throw const CategoryAlreadyExistsException();
    }
    return _repository.add(name: trimmed, iconName: iconName);
  }
}

/// Todas las categorías (orden por nombre).
class GetAllCategories {
  const GetAllCategories(this._repository);
  final CategoryRepository _repository;

  Future<List<Category>> call() => _repository.getAll();
}

/// Una categoría por id o `null`.
class GetCategoryById {
  const GetCategoryById(this._repository);
  final CategoryRepository _repository;

  Future<Category?> call(int id) => _repository.getById(id);
}
