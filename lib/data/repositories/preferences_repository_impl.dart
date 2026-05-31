import '../../domain/repositories/preferences_repository.dart';
import '../preferences/preferences_service.dart';

/// Implementación de [PreferencesRepository] sobre [PreferencesService]
/// (`shared_preferences`).
class PreferencesRepositoryImpl implements PreferencesRepository {
  PreferencesRepositoryImpl(this._service);

  final PreferencesService _service;

  @override
  bool get showOnboarding => _service.showOnboarding;

  @override
  Future<void> completeOnboarding() => _service.completeOnboarding();
}
