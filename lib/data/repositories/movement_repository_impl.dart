import '../../domain/models/category.dart';
import '../../domain/models/movement.dart';
import '../../domain/repositories/movement_repository.dart';
import '../../domain/rules/month_rules.dart';
import '../local/app_database.dart' as db;
import '../mappers/category_mapper.dart';
import '../mappers/movement_mapper.dart';

/// Implementación de [MovementRepository] sobre Drift.
///
/// La relación movimiento→categoría se resuelve en aplicación (igual que el
/// origen Room): se cargan las categorías y se asocian por `categoryId`.
class MovementRepositoryImpl implements MovementRepository {
  MovementRepositoryImpl(this._db);

  final db.AppDatabase _db;

  @override
  Future<int> add(Movement movement) =>
      _db.insertMovement(movement.toCompanion());

  @override
  Future<int> delete(int id) => _db.deleteMovement(id);

  @override
  Future<Movement?> getById(int id) async {
    final row = await _db.getMovementById(id);
    if (row == null) return null;
    final category = await _db.getCategoryById(row.categoryId);
    if (category == null) return null; // categoría ausente: estado defensivo.
    return row.toDomain(category.toDomain());
  }

  @override
  Future<List<Movement>> getAll() async => _join(await _db.getAllMovements());

  @override
  Future<List<Movement>> getByMonth(int year, int month) async {
    final range = monthRangeMs(year, month);
    return _join(await _db.getMovementsBetween(range.startMs, range.endMs));
  }

  /// Asocia cada fila de movimiento con su categoría usando un único lookup.
  Future<List<Movement>> _join(List<db.Movement> rows) async {
    if (rows.isEmpty) return const [];
    final categoriesById = <int, Category>{
      for (final c in await _db.getAllCategories()) c.id: c.toDomain(),
    };
    return [
      for (final row in rows)
        if (categoriesById[row.categoryId] case final category?)
          row.toDomain(category),
    ];
  }
}
