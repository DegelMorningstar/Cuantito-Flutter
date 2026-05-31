import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/cuantito_colors.dart';
import '../../core/format/formatters.dart';
import '../../domain/models/movement.dart';
import '../../domain/models/transaction_type.dart';
import '../categories/icon_catalog.dart';
import 'detail_movement_notifier.dart';

/// Detalle de un movimiento con opción de eliminar (porta `DetailMovementScreen`).
class DetailMovementPage extends ConsumerWidget {
  const DetailMovementPage({super.key, required this.movementId});

  final int movementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = detailMovementProvider(movementId);

    // Tras eliminar, vuelve atrás (la lista ya fue invalidada en el notifier).
    ref.listen(provider, (previous, next) {
      if (next.value?.isDeleted ?? false) {
        if (context.mounted) context.pop();
      }
    });

    final asyncState = ref.watch(provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Movimiento'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _MissingMovementView(),
          data: (state) {
            final movement = state.movement;
            if (movement == null) return const _MissingMovementView();
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MainContent(movement: movement),
                _DeleteFooter(
                  onDelete: () => _confirmAndDelete(context, ref),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Pide confirmación antes de eliminar (el borrado es irreversible; mejora la
  /// UX no resuelta del origen, que eliminaba sin preguntar).
  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: const Text('¿Seguro que deseas eliminar este registro?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(detailMovementProvider(movementId).notifier).delete();
    }
  }
}

class _MainContent extends StatelessWidget {
  const _MainContent({required this.movement});

  final Movement movement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CuantitoColors>()!;
    final color =
        movement.type == TransactionType.ingreso ? colors.income : colors.expense;
    final hasDescription =
        movement.description != null && movement.description!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    iconForName(movement.category.iconName),
                    size: 48,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                movement.type.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(color: color),
              ),
              const SizedBox(height: 12),
              Text(
                formatCents(movement.amountCents),
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                hasDescription ? movement.description! : movement.category.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              if (hasDescription)
                _DetailRow(label: 'Categoría:', value: movement.category.name),
              _DetailRow(
                label: 'Fecha:',
                value: formatLongDate(movement.dateTime),
              ),
              _DetailRow(label: 'Método de pago:', value: movement.method.label),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteFooter extends StatelessWidget {
  const _DeleteFooter({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CuantitoColors>()!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton.icon(
          onPressed: onDelete,
          style: FilledButton.styleFrom(backgroundColor: colors.expense),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Eliminar Registro'),
        ),
      ),
    );
  }
}

class _MissingMovementView extends StatelessWidget {
  const _MissingMovementView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          const Text('No se encontró el movimiento'),
        ],
      ),
    );
  }
}
