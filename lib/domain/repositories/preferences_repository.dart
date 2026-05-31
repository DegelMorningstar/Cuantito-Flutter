/// Contrato de preferencias del usuario (estado de onboarding, RN-009).
abstract interface class PreferencesRepository {
  /// Verdadero hasta que el onboarding se completa una vez.
  bool get showOnboarding;

  Future<void> completeOnboarding();
}
