import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Placeholder de la pantalla de Onboarding (3 slides).
/// Implementación real en F9.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Onboarding (placeholder · F9)'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Comenzar'),
            ),
          ],
        ),
      ),
    );
  }
}
