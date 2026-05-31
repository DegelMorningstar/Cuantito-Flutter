import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';

/// Contenido de un slide del onboarding (porta `OnboardingPage` del origen).
///
/// Las ilustraciones son las del origen: se convirtieron de *VectorDrawable* de
/// Android a SVG (ver `tool/generate_onboarding_svgs.dart`) y se muestran con
/// `flutter_svg`, conservando nitidez a cualquier resolución.
class _OnboardingSlide {
  const _OnboardingSlide({
    required this.asset,
    required this.title,
    required this.description,
  });

  final String asset;
  final String title;
  final String description;
}

const List<_OnboardingSlide> _slides = [
  _OnboardingSlide(
    asset: 'assets/onboarding/onboarding_one.svg',
    title: 'Registro de gastos y de ingresos',
    description:
        'Anota tus transacciones diarias de forma rápida y sencilla para tener '
        'un control total de tus finanzas.',
  ),
  _OnboardingSlide(
    asset: 'assets/onboarding/onboarding_two.svg',
    title: 'Mis gastos',
    description:
        'Visualiza la lista de tus gastos para entender a dónde va tu dinero.',
  ),
  _OnboardingSlide(
    asset: 'assets/onboarding/onboarding_three.svg',
    title: 'Categorías',
    description:
        'Organiza tus gastos por categorías para identificar áreas de ahorro y '
        'optimizar tu presupuesto.',
  ),
];

/// Pantalla de Onboarding (primera ejecución, RN-009). Porta `OnboardingScreen`:
/// un `PageView` de 3 slides con indicadores e botones Siguiente/Saltar.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage == _slides.length - 1;

  /// Avanza al siguiente slide o, en el último, finaliza.
  void _onNext() {
    if (_isLastPage) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Completa el onboarding (RN-009) y navega al inicio (NewMovement). El guard
  /// del router ya no devolverá a esta pantalla.
  Future<void> _finish() async {
    await ref.read(completeOnboardingProvider)();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) =>
                    _SlideContent(slide: _slides[index]),
              ),
            ),
            _OnboardingControls(
              pageCount: _slides.length,
              currentPage: _currentPage,
              isLastPage: _isLastPage,
              onNext: _onNext,
              onSkip: _finish,
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideContent extends StatelessWidget {
  const _SlideContent({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            slide.asset,
            height: 250,
            fit: BoxFit.contain,
            semanticsLabel: slide.title,
          ),
          const SizedBox(height: 32),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _OnboardingControls extends StatelessWidget {
  const _OnboardingControls({
    required this.pageCount,
    required this.currentPage,
    required this.isLastPage,
    required this.onNext,
    required this.onSkip,
  });

  final int pageCount;
  final int currentPage;
  final bool isLastPage;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < pageCount; i++)
                _PageDot(active: i == currentPage),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: onNext,
              child: Text(isLastPage ? 'Finalizar' : 'Siguiente'),
            ),
          ),
          // "Saltar" se oculta en el último slide (paridad con el origen).
          if (!isLastPage)
            TextButton(onPressed: onSkip, child: const Text('Saltar')),
        ],
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? colors.primary : colors.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
