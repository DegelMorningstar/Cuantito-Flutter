import 'package:shared_preferences/shared_preferences.dart';

/// Acceso a preferencias locales.
///
/// Por ahora solo la bandera de onboarding (RN-009). Nota: la app Android
/// usaba el archivo `cuantito_preferences`; `shared_preferences` mantiene su
/// propio almacén, así que el onboarding podría mostrarse una vez más tras la
/// migración (no implica pérdida de datos del usuario).
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const _onboardingKey = 'onboarding_state';

  /// Verdadero hasta que el usuario completa el onboarding una vez.
  bool get showOnboarding => _prefs.getBool(_onboardingKey) ?? true;

  Future<void> completeOnboarding() => _prefs.setBool(_onboardingKey, false);
}
