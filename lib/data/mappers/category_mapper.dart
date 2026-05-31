import '../../domain/models/category.dart';
import '../local/app_database.dart' as db;

/// Conversión entre la fila Drift `Category` y el modelo de dominio [Category].
extension CategoryRowMapper on db.Category {
  Category toDomain() => Category(id: id, name: name, iconName: iconName);
}
