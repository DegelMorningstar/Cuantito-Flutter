import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/di/providers.dart';
import '../../domain/models/category.dart';
import '../categories/icon_catalog.dart';
import '../widgets/numeric_keypad.dart';
import 'new_movement_notifier.dart';

/// Pantalla principal: registrar un ingreso/egreso (start destination tras el
/// onboarding). Porta `NewMovementScreen` + `NewMovementViewModel`.
class NewMovementPage extends ConsumerStatefulWidget {
  const NewMovementPage({super.key});

  @override
  ConsumerState<NewMovementPage> createState() => _NewMovementPageState();
}

class _NewMovementPageState extends ConsumerState<NewMovementPage> {
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Preselecciona la primera categoría disponible (RN-006).
    ref.read(categoriesProvider.future).then((categories) {
      if (mounted && categories.isNotEmpty) {
        ref
            .read(newMovementProvider.notifier)
            .setDefaultCategoryIfUnset(categories.first);
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final result = await ref.read(newMovementProvider.notifier).save();
    if (!mounted) return;
    switch (result) {
      case SaveResult.success:
        _descriptionController.clear();
        _showMessage('Registrado con éxito');
      case SaveResult.invalidAmount:
        _showMessage('El monto no puede ser cero');
      case SaveResult.noCategory:
        _showMessage('Selecciona una categoría');
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final current = ref.read(newMovementProvider).dateTime;
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isAfter(now) ? now : current,
      firstDate: DateTime(2000),
      lastDate: now, // no se permiten fechas futuras.
    );
    if (picked != null) {
      ref.read(newMovementProvider.notifier).setDate(picked);
    }
  }

  Future<void> _pickCategory() async {
    final current = ref.read(newMovementProvider).category.id;
    final result = await context.pushNamed<Category>(
      'categories',
      queryParameters: {'selectedCategoryId': '$current'},
    );
    if (result != null) {
      ref.read(newMovementProvider.notifier).setCategory(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newMovementProvider);
    final notifier = ref.read(newMovementProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo movimiento'),
        actions: [
          IconButton(
            tooltip: 'Ver movimientos',
            icon: const Icon(Icons.list_alt_outlined),
            onPressed: () => context.pushNamed('movements'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: [
                    Text(
                      '¿Qué registramos hoy?',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    Text('Fecha', style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(DateFormat('dd/MM/yyyy').format(state.dateTime)),
                    ),
                    const SizedBox(height: 24),
                    Text('Monto', style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          r'$',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          state.amount,
                          style: theme.textTheme.displaySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _descriptionController,
                onChanged: notifier.setDescription,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.edit_note),
                  hintText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _CategoryButton(
                category: state.category,
                onPressed: _pickCategory,
              ),
            ),
            const SizedBox(height: 8),
            NumericKeypad(
              method: state.method,
              type: state.type,
              onKey: notifier.onKey,
              onBackspace: notifier.onBackspace,
              onSave: _save,
              onToggleMethod: notifier.toggleMethod,
              onToggleType: notifier.toggleType,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({required this.category, required this.onPressed});

  final Category category;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(iconForName(category.iconName)),
        label: Text(category.name),
      ),
    );
  }
}
