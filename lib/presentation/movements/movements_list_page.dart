import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/cuantito_colors.dart';
import '../../core/format/formatters.dart';
import '../../domain/models/movement.dart';
import '../../domain/models/transaction_type.dart';
import '../categories/icon_catalog.dart';
import 'movements_list_notifier.dart';
import 'movements_list_state.dart';

/// Lista mensual de movimientos con totales (porta `MovementsListScreen`).
class MovementsListPage extends ConsumerWidget {
  const MovementsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(movementsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorView(
            onRetry: () => ref.invalidate(movementsListProvider),
          ),
          data: (state) => _MovementsBody(state: state),
        ),
      ),
    );
  }
}

class _MovementsBody extends ConsumerWidget {
  const _MovementsBody({required this.state});

  final MovementsListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(movementsListProvider.notifier);
    return Column(
      children: [
        _MonthSelector(
          label: state.monthLabel,
          canGoToNext: state.canGoToNext,
          onPrevious: notifier.goToPreviousMonth,
          onNext: notifier.goToNextMonth,
        ),
        _AmountSummary(
          showExpenses: state.showExpenses,
          totalCents: state.summaryCents,
          onTap: notifier.toggleSummary,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              'Historial',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
        Expanded(
          child: state.movements.isEmpty
              ? const _EmptyView()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: state.movements.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final movement = state.movements[index];
                    return _MovementItem(
                      movement: movement,
                      onTap: () => context.pushNamed(
                        'detail',
                        pathParameters: {'id': '${movement.id}'},
                      ),
                    );
                  },
                ),
        ),
      ],
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton.filledTonal(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Mes anterior',
          ),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          IconButton.filledTonal(
            // Deshabilitado en el mes en curso: no se permiten meses futuros (RN-004).
            onPressed: canGoToNext ? onNext : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Mes siguiente',
          ),
        ],
      ),
    );
  }
}

class _AmountSummary extends StatelessWidget {
  const _AmountSummary({
    required this.showExpenses,
    required this.totalCents,
    required this.onTap,
  });

  final bool showExpenses;
  final int totalCents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CuantitoColors>()!;
    final label = showExpenses ? 'Total Gastos' : 'Total Ingresos';
    final color = showExpenses ? colors.expense : colors.income;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(label, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 4),
                Text(
                  formatCents(totalCents),
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MovementItem extends StatelessWidget {
  const _MovementItem({required this.movement, required this.onTap});

  final Movement movement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CuantitoColors>()!;
    final amountColor = movement.type == TransactionType.egreso
        ? colors.expense
        : colors.income;
    final hasDescription =
        movement.description != null && movement.description!.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          foregroundColor: theme.colorScheme.onSecondaryContainer,
          child: Icon(iconForName(movement.category.iconName)),
        ),
        title: Text(
          hasDescription ? movement.description! : movement.category.name,
        ),
        subtitle: hasDescription ? Text(movement.category.name) : null,
        trailing: Text(
          formatCents(movement.amountCents),
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: amountColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          const Text('Sin movimientos este mes'),
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
