// Catálogo de iconos y resolución tolerante (RN-008 / R-02).

import 'package:cuantito/presentation/categories/icon_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('paridad con el origen: 9 grupos × 6 = 54 iconos', () {
    expect(catalogIconGroups.length, 9);
    for (final group in catalogIconGroups) {
      expect(group.icons.length, 6, reason: group.label);
    }
    final total =
        catalogIconGroups.fold<int>(0, (n, g) => n + g.icons.length);
    expect(total, 54);
  });

  test('iconForName resuelve nombres del catálogo', () {
    expect(iconForName('Filled.ShoppingCart'), Icons.shopping_cart);
    expect(iconForName('Filled.Restaurant'), Icons.restaurant);
    expect(iconForName('Filled.DirectionsCar'), Icons.directions_car);
  });

  test('iconForName cae al icono por defecto si no existe (RN-008)', () {
    expect(iconForName('NoExiste'), kDefaultIcon);
    expect(iconForName(''), kDefaultIcon);
    expect(kDefaultIcon, Icons.shopping_cart);
    expect(iconForName(kDefaultIconName), kDefaultIcon);
  });
}
