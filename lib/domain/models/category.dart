/// Categoría de un movimiento. Modelo de dominio **puro**: `iconName` es el
/// nombre del icono (String); el mapeo a `IconData` ocurre en presentación
/// (F5, mitiga R-02/R-07).
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconName,
  });

  /// `0` indica una categoría aún no persistida.
  final int id;
  final String name;
  final String iconName;

  Category copyWith({int? id, String? name, String? iconName}) => Category(
        id: id ?? this.id,
        name: name ?? this.name,
        iconName: iconName ?? this.iconName,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          other.id == id &&
          other.name == name &&
          other.iconName == iconName;

  @override
  int get hashCode => Object.hash(id, name, iconName);

  @override
  String toString() => 'Category(id: $id, name: $name, iconName: $iconName)';
}
