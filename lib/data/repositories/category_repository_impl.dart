import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../local/app_database.dart' as db;
import '../mappers/category_mapper.dart';

/// Implementación de [CategoryRepository] sobre Drift.
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._db);

  final db.AppDatabase _db;

  @override
  Future<List<Category>> getAll() async =>
      (await _db.getAllCategories()).map((c) => c.toDomain()).toList();

  @override
  Future<Category?> getById(int id) async =>
      (await _db.getCategoryById(id))?.toDomain();

  @override
  Future<bool> existsByName(String name) async =>
      (await _db.getCategoryByName(name)) != null;

  @override
  Future<int> add({required String name, required String iconName}) =>
      _db.insertCategory(
        db.CategoriesCompanion.insert(name: name, iconName: iconName),
      );
}
