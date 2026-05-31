import '../repositories/preferences_repository.dart';

/// Estado del onboarding (RN-009): `true` si aún debe mostrarse.
class GetOnboardingStatus {
  const GetOnboardingStatus(this._repository);
  final PreferencesRepository _repository;

  bool call() => _repository.showOnboarding;
}

/// Marcar el onboarding como completado (RN-009).
class CompleteOnboarding {
  const CompleteOnboarding(this._repository);
  final PreferencesRepository _repository;

  Future<void> call() => _repository.completeOnboarding();
}
