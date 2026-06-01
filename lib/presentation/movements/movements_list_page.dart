import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/cuantito_colors.dart';
import '../../core/format/formatters.dart';
import '../../domain/models/movement.dart';
import '../../domain/models/transaction_type.dart';
import '../categories/icon_catalog.dart';
import 'movements_list_notifier.dart';

/// Lista mensual de movimientos con resumen (rediseño "Movimientos").
class MovementsListPage extends ConsumerWidget {
  const MovementsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(movementsListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => context.canPop() ? context.pop() : context.go('/'),
            ),
            Expanded(
              child: asyncState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _ErrorView(
                  onRetry: () => ref.invalidate(movementsListProvider),
                ),
                data: (state) {
                  final notifier = ref.read(movementsListProvider.notifier);
                  return Column(
                    children: [
                      _MonthSelector(
                        label: state.monthLabel,
                        canGoToNext: state.canGoToNext,
                        onPrevious: notifier.goToPreviousMonth,
                        onNext: notifier.goToNextMonth,
                      ),
                      _SummaryCard(
                        expenseCents: state.totals.expenseCents,
                        incomeCents: state.totals.incomeCents,
                        balanceCents: state.totals.balanceCents,
                      ),
                      Expanded(
                        child: state.movements.isEmpty
                            ? const _EmptyView()
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                itemCount: state.movements.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final m = state.movements[index];
                                  return _MovementRow(
                                    movement: m,
                                    onTap: () => context.pushNamed(
                                      'detail',
                                      pathParameters: {'id': '${m.id}'},
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Material(
            color: c.surface2,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onBack,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back_ios_new, size: 18, color: c.textMedium),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Movimientos',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.label,
    required this.canGoToNext,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final bool canGoToNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
            color: c.textMedium,
            tooltip: 'Mes anterior',
          ),
          SizedBox(
            width: 160,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            // Deshabilitado en el mes en curso (RN-004).
            onPressed: canGoToNext ? onNext : null,
            icon: const Icon(Icons.chevron_right),
            color: c.textMedium,
            disabledColor: c.textDim,
            tooltip: 'Mes siguiente',
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.expenseCents,
    required this.incomeCents,
    required this.balanceCents,
  });

  final int expenseCents;
  final int incomeCents;
  final int balanceCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<CuantitoColors>()!;
    final balancePositive = balanceCents >= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _SummaryColumn(
                    label: 'Egresos',
                    value: '-${formatCents(expenseCents)}',
                    color: c.expense,
                  ),
                ),
                VerticalDivider(color: c.hairline, width: 1, thickness: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: _SummaryColumn(
                      label: 'Ingresos',
                      value: '+${formatCents(incomeCents)}',
                      color: c.income,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Divider(color: c.hairline, height: 1),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('Balance',
                    style: theme.textTheme.bodyMedium?.copyWith(color: c.textDim)),
                Text(
                  '${balancePositive ? '+' : '-'}${formatCents(balanceCents.abs())}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: balancePositive ? c.income : c.expense,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<CuantitoColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: c.textDim,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement, required this.onTap});

  final Movement movement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<CuantitoColors>()!;
    final isE = movement.type == TransactionType.egreso;
    final amountColor = isE ? c.expense : c.income;
    final hasDesc =
        movement.description != null && movement.description!.isNotEmpty;
    final subtitle = [
      _rowDate(movement.dateTime),
      movement.method.label,
      if (hasDesc) movement.description!,
    ].join(' · ');

    return Material(
      color: c.surface1,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconForName(movement.category.iconName),
                    color: c.textMedium, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.textTheme.bodySmall?.copyWith(color: c.textDim),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${isE ? '−' : '+'}${formatCents(movement.amountCents)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fecha compacta para la fila: "Hoy" / "Ayer" / "d MMM yyyy".
String _rowDate(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📭', style: TextStyle(fontSize: 36, color: c.textDim)),
          const SizedBox(height: 12),
          Text('Sin movimientos este mes',
              style: TextStyle(color: c.textDim, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('No se pudieron cargar los movimientos'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
