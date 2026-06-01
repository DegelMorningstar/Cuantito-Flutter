import 'package:flutter/material.dart';

import '../../app/theme/cuantito_colors.dart';

/// Contenedor de bottom sheet del rediseño: superficie `s1`, esquinas
/// superiores redondeadas (24), manija de arrastre y título centrado. El
/// contenido se desplaza si excede la altura disponible.
class CuantitoSheet extends StatelessWidget {
  const CuantitoSheet({super.key, this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.hairline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    if (title != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        title!,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              Flexible(child: SingleChildScrollView(child: child)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
