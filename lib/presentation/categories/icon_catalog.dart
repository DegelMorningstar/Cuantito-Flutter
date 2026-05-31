import 'package:flutter/material.dart';

/// Catálogo de iconos para categorías (capa de **presentación**: aquí sí viven
/// los `IconData`, manteniendo el dominio puro — R-07).
///
/// Portado de `catalogIconsList.kt` (9 grupos, 54 iconos). El `name` canónico es
/// el `ImageVector.name` de Compose (`"Filled.<Icono>"`), que es **exactamente
/// lo que persistía** la app Android en `CategoryEntity.icon` (`icon = icon.name`).
/// Usar la misma clave garantiza que tanto las categorías nuevas como las
/// **migradas desde Room (F3)** resuelvan su icono.
///
/// La resolución `name → IconData` es tolerante (RN-008 / R-02): si el nombre no
/// está en el catálogo, cae al icono por defecto (`gastosDiariosIcons.first()`).
@immutable
class CatalogIcon {
  const CatalogIcon(this.name, this.icon);

  /// `ImageVector.name` de Compose, p. ej. `"Filled.ShoppingCart"`. Es lo que se
  /// persiste en `Category.iconName`.
  final String name;
  final IconData icon;
}

/// Grupo temático de iconos (los 9 grupos del catálogo original).
@immutable
class IconGroup {
  const IconGroup(this.label, this.icons);

  final String label;
  final List<CatalogIcon> icons;
}

/// Nombre del icono por defecto (fallback, RN-008): `gastosDiariosIcons.first()`.
const String kDefaultIconName = 'Filled.ShoppingCart';

/// Catálogo agrupado: 9 grupos × 6 iconos = 54 (paridad con `catalogIconsList.kt`).
const List<IconGroup> catalogIconGroups = [
  IconGroup('Gastos diarios', [
    CatalogIcon('Filled.ShoppingCart', Icons.shopping_cart),
    CatalogIcon('Filled.Fastfood', Icons.fastfood),
    CatalogIcon('Filled.LocalGroceryStore', Icons.local_grocery_store),
    CatalogIcon('Filled.LocalMall', Icons.local_mall),
    CatalogIcon('Filled.Coffee', Icons.coffee),
    CatalogIcon('Filled.Restaurant', Icons.restaurant),
  ]),
  IconGroup('Transporte', [
    CatalogIcon('Filled.DirectionsCar', Icons.directions_car),
    CatalogIcon('Filled.DirectionsBus', Icons.directions_bus),
    CatalogIcon('Filled.LocalTaxi', Icons.local_taxi),
    CatalogIcon('Filled.TwoWheeler', Icons.two_wheeler),
    CatalogIcon('Filled.DirectionsSubway', Icons.directions_subway),
    CatalogIcon('Filled.AirplanemodeActive', Icons.airplanemode_active),
  ]),
  IconGroup('Hogar', [
    CatalogIcon('Filled.Home', Icons.home),
    CatalogIcon('Filled.Lightbulb', Icons.lightbulb),
    CatalogIcon('Filled.LocalLaundryService', Icons.local_laundry_service),
    CatalogIcon('Filled.Wifi', Icons.wifi),
    CatalogIcon('Filled.Water', Icons.water),
    CatalogIcon('Filled.Build', Icons.build),
  ]),
  IconGroup('Salud', [
    CatalogIcon('Filled.LocalHospital', Icons.local_hospital),
    CatalogIcon('Filled.MedicalServices', Icons.medical_services),
    CatalogIcon('Filled.Favorite', Icons.favorite),
    CatalogIcon('Filled.Spa', Icons.spa),
    CatalogIcon('Filled.FitnessCenter', Icons.fitness_center),
    CatalogIcon('Filled.Healing', Icons.healing),
  ]),
  IconGroup('Educación', [
    CatalogIcon('Filled.School', Icons.school),
    CatalogIcon('Filled.MenuBook', Icons.menu_book),
    CatalogIcon('Filled.AutoStories', Icons.auto_stories),
    CatalogIcon('Filled.Book', Icons.book),
    CatalogIcon('Filled.Create', Icons.create),
    CatalogIcon('Filled.LaptopChromebook', Icons.laptop_chromebook),
  ]),
  IconGroup('Entretenimiento', [
    CatalogIcon('Filled.Movie', Icons.movie),
    CatalogIcon('Filled.MusicNote', Icons.music_note),
    CatalogIcon('Filled.VideogameAsset', Icons.videogame_asset),
    CatalogIcon('Filled.SportsSoccer', Icons.sports_soccer),
    CatalogIcon('Filled.Casino', Icons.casino),
    CatalogIcon('Filled.LocalBar', Icons.local_bar),
  ]),
  IconGroup('Trabajo', [
    CatalogIcon('Filled.Work', Icons.work),
    CatalogIcon('Filled.BusinessCenter', Icons.business_center),
    CatalogIcon('Filled.AttachMoney', Icons.attach_money),
    CatalogIcon('Filled.TrendingUp', Icons.trending_up),
    CatalogIcon('Filled.Assessment', Icons.assessment),
    CatalogIcon('Filled.RequestQuote', Icons.request_quote),
  ]),
  IconGroup('Finanzas', [
    CatalogIcon('Filled.Money', Icons.money),
    CatalogIcon('Filled.Savings', Icons.savings),
    CatalogIcon('Filled.AccountBalance', Icons.account_balance),
    CatalogIcon('Filled.CreditCard', Icons.credit_card),
    CatalogIcon('Filled.ReceiptLong', Icons.receipt_long),
    CatalogIcon('Filled.Wallet', Icons.wallet),
  ]),
  IconGroup('Familia', [
    CatalogIcon('Filled.FamilyRestroom', Icons.family_restroom),
    CatalogIcon('Filled.Favorite', Icons.favorite),
    CatalogIcon('Filled.EmojiPeople', Icons.emoji_people),
    CatalogIcon('Filled.ChildFriendly', Icons.child_friendly),
    CatalogIcon('Filled.Elderly', Icons.elderly),
    CatalogIcon('Filled.Group', Icons.group),
  ]),
];

/// Índice `name → IconData` construido una sola vez para resolución O(1).
/// (`Filled.Favorite` aparece en dos grupos —Salud y Familia—, como en el
/// original; al deduplicar apunta al mismo `IconData`.)
final Map<String, IconData> _iconsByName = {
  for (final group in catalogIconGroups)
    for (final icon in group.icons) icon.name: icon.icon,
};

/// `IconData` del icono por defecto (`ShoppingCart`).
final IconData kDefaultIcon = _iconsByName[kDefaultIconName]!;

/// Resuelve el `IconData` de un `iconName` persistido. Si no está en el
/// catálogo, devuelve el icono por defecto (RN-008, degradación silenciosa).
IconData iconForName(String name) => _iconsByName[name] ?? kDefaultIcon;
