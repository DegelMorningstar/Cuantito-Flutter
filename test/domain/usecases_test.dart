// Casos de uso con repositorios falsos: validaciones de negocio
// (RN-001, RN-005, RN-009).

import 'package:cuantito/domain/exceptions.dart';
import 'package:cuantito/domain/models/category.dart';
import 'package:cuantito/domain/models/movement.dart';
import 'package:cuantito/domain/models/payment_method.dart';
import 'package:cuantito/domain/models/transaction_type.dart';
import 'package:cuantito/domain/repositories/category_repository.dart';
import 'package:cuantito/domain/repositories/movement_repository.dart';
import 'package:cuantito/domain/repositories/preferences_repository.dart';
import 'package:cuantito/domain/usecases/category_usecases.dart';
import 'package:cuantito/domain/usecases/movement_usecases.dart';
import 'package:cuantito/domain/usecases/onboarding_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCategoryRepository implements CategoryRepository {
  final List<Category> _items = [];
  var _seq = 0;

  @override
  Future<int> add({required String name, required String iconName}) async {
    final id = ++_seq;
    _items.add(Category(id: id, name: name, iconName: iconName));
    return id;
  }

  @override
  Future<bool> existsByName(String name) async =>
      _items.any((c) => c.name == name);

  @override
  Future<List<Category>> getAll() async => List.unmodifiable(_items);

  @override
  Future<Category?> getById(int id) async {
    final matches = _items.where((c) => c.id == id);
    return matches.isEmpty ? null : matches.first;
  }
}

class _FakeMovementRepository implements MovementRepository {
  final List<Movement> added = [];

  @override
  Future<int> add(Movement movement) async {
    added.add(movement);
    return added.length;
  }

  @override
  Future<int> delete(int id) async => 1;
  @override
  Future<List<Movement>> getAll() async => added;
  @override
  Future<Movement?> getById(int id) async => null;
  @override
  Future<List<Movement>> getByMonth(int year, int month) async => added;
}

class _FakePreferencesRepository implements PreferencesRepository {
  bool _show = true;
  @override
  bool get showOnboarding => _show;
  @override
  Future<void> completeOnboarding() async => _show = false;
}

Movement _movement({required int cents}) => Movement(
      id: 0,
      amountCents: cents,
      description: null,
      category: const Category(id: 1, name: 'X', iconName: 'i'),
      method: PaymentMethod.debito,
      type: TransactionType.egreso,
      dateTime: DateTime(2026, 5, 1),
    );

void main() {
  group('AddMovement (RN-001)', () {
    test('rechaza monto no positivo y no persiste', () async {
      final repo = _FakeMovementRepository();
      final addMovement = AddMovement(repo);

      expect(
        () => addMovement(_movement(cents: 0)),
        throwsA(isA<InvalidAmountException>()),
      );
      expect(repo.added, isEmpty);
    });

    test('persiste un monto válido', () async {
      final repo = _FakeMovementRepository();
      final id = await AddMovement(repo)(_movement(cents: 1500));
      expect(id, 1);
      expect(repo.added.single.amountCents, 1500);
    });
  });

  group('AddCategory (RN-005)', () {
    test('nombre vacío lanza EmptyCategoryNameException', () {
      expect(
        () => AddCategory(_FakeCategoryRepository())(name: '  ', iconName: 'i'),
        throwsA(isA<EmptyCategoryNameException>()),
      );
    });

    test('nombre duplicado lanza CategoryAlreadyExistsException', () async {
      final repo = _FakeCategoryRepository();
      final addCategory = AddCategory(repo);
      await addCategory(name: 'Comida', iconName: 'i');

      expect(
        () => addCategory(name: 'Comida', iconName: 'i'),
        throwsA(isA<CategoryAlreadyExistsException>()),
      );
    });

    test('recorta el nombre antes de validar y guardar', () async {
      final repo = _FakeCategoryRepository();
      await AddCategory(repo)(name: '  Salario  ', iconName: 'i');
      expect((await repo.getAll()).single.name, 'Salario');
    });
  });

  group('Onboarding (RN-009)', () {
    test('estado inicial true; completar lo deja en false', () async {
      final repo = _FakePreferencesRepository();
      expect(GetOnboardingStatus(repo)(), isTrue);
      await CompleteOnboarding(repo)();
      expect(GetOnboardingStatus(repo)(), isFalse);
    });
  });
}
