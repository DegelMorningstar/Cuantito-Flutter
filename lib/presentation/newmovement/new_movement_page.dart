import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/cuantito_colors.dart';
import '../../core/di/providers.dart';
import '../../domain/models/transaction_type.dart';
import '../categories/category_sheet.dart';
import '../categories/icon_catalog.dart';
import '../widgets/date_sheet.dart';
import '../widgets/numeric_keypad.dart';
import 'new_movement_notifier.dart';
import 'new_movement_state.dart';

/// Pantalla principal: registrar un ingreso/egreso (rediseño). El monto es el
/// protagonista; debajo, chips de Fecha/Método/Categoría/Nota y el teclado.
class NewMovementPage extends ConsumerStatefulWidget {
  const NewMovementPage({super.key});

  @override
  ConsumerState<NewMovementPage> createState() => _NewMovementPageState();
}

class _NewMovementPageState extends ConsumerState<NewMovementPage>
    with SingleTickerProviderStateMixin {
  final _descriptionController = TextEditingController();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  bool _showDesc = false;
  bool _saved = false;

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
    _shake.dispose();
    super.dispose();
  }

  void _selectType(TransactionType type) {
    if (ref.read(newMovementProvider).type != type) {
      ref.read(newMovementProvider.notifier).toggleType();
    }
  }

  Future<void> _save() async {
    final result = await ref.read(newMovementProvider.notifier).save();
    if (!mounted) return;
    switch (result) {
      case SaveResult.success:
        _descriptionController.clear();
        setState(() {
          _saved = true;
          _showDesc = false;
        });
        await Future<void>.delayed(const Duration(milliseconds: 950));
        if (mounted) setState(() => _saved = false);
      case SaveResult.invalidAmount:
        _shake.forward(from: 0);
      case SaveResult.noCategory:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Selecciona una categoría')));
    }
  }

  Color _accent() {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    return ref.read(newMovementProvider).type == TransactionType.egreso
        ? c.expense
        : c.income;
  }

  Future<void> _pickDate() async {
    final picked = await showDateSheet(
      context,
      initial: ref.read(newMovementProvider).dateTime,
      accent: _accent(),
    );
    if (picked != null) {
      ref.read(newMovementProvider.notifier).setDate(picked);
    }
  }

  Future<void> _pickCategory() async {
    final result = await showCategorySheet(
      context,
      selectedId: ref.read(newMovementProvider).category.id,
      accent: _accent(),
    );
    if (result != null) {
      ref.read(newMovementProvider.notifier).setCategory(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newMovementProvider);
    final notifier = ref.read(newMovementProvider.notifier);
    final c = Theme.of(context).extension<CuantitoColors>()!;
    final isE = state.type == TransactionType.egreso;
    final tColor = isE ? c.expense : c.income;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onHistory: () => context.pushNamed('movements')),
            Expanded(
              child: _AmountHero(
                amount: state.amount,
                tColor: tColor,
                isExpense: isE,
                saved: _saved,
                shake: _shake,
                onToggleType: notifier.toggleType,
              ),
            ),
            _ChipsRow(
              state: state,
              tColor: tColor,
              showDesc: _showDesc,
              onDate: _pickDate,
              onMethod: notifier.toggleMethod,
              onCategory: _pickCategory,
              onNote: () => setState(() => _showDesc = !_showDesc),
            ),
            if (_showDesc)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: TextField(
                  controller: _descriptionController,
                  onChanged: notifier.setDescription,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Añadir nota...',
                    filled: true,
                    fillColor: c.surface1,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: tColor.withValues(alpha: 0.35), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: tColor, width: 1.5),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
              child: NumericKeypad(
                type: state.type,
                amountIsZero: state.amount == '0.00',
                saved: _saved,
                onKey: notifier.onKey,
                onBackspace: notifier.onBackspace,
                onSelectType: _selectType,
                onSave: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onHistory});

  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'cuantito',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.9,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          _CircleButton(
            icon: Icons.history,
            onTap: onHistory,
            color: c.surface2,
            iconColor: c.textMedium,
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}

class _AmountHero extends StatelessWidget {
  const _AmountHero({
    required this.amount,
    required this.tColor,
    required this.isExpense,
    required this.saved,
    required this.shake,
    required this.onToggleType,
  });

  final String amount;
  final Color tColor;
  final bool isExpense;
  final bool saved;
  final AnimationController shake;
  final VoidCallback onToggleType;

  double get _fontSize {
    final l = amount.length;
    if (l <= 4) return 72;
    if (l <= 6) return 60;
    if (l <= 8) return 48;
    return 40;
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    final isZero = amount == '0.00';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Badge de tipo (tappable).
        GestureDetector(
          onTap: onToggleType,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: tColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: tColor.withValues(alpha: 0.30)),
            ),
            child: Text(
              '${isExpense ? '−' : '+'} ${isExpense ? 'EGRESO' : 'INGRESO'}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: tColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        // Monto.
        AnimatedBuilder(
          animation: shake,
          builder: (context, child) {
            final dx = math.sin(shake.value * math.pi * 5) * 8 * (1 - shake.value);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: saved
              ? Column(
                  children: [
                    Icon(Icons.check_circle, color: c.income, size: 64),
                    const SizedBox(height: 10),
                    Text('Guardado',
                        style: TextStyle(
                            color: c.income, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        r'$',
                        style: TextStyle(
                          fontSize: _fontSize * 0.36,
                          fontWeight: FontWeight.w300,
                          color: tColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: _fontSize,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        letterSpacing: -1.5,
                        color: isZero ? tColor.withValues(alpha: 0.30) : tColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ChipsRow extends StatelessWidget {
  const _ChipsRow({
    required this.state,
    required this.tColor,
    required this.showDesc,
    required this.onDate,
    required this.onMethod,
    required this.onCategory,
    required this.onNote,
  });

  final NewMovementState state;
  final Color tColor;
  final bool showDesc;
  final VoidCallback onDate;
  final VoidCallback onMethod;
  final VoidCallback onCategory;
  final VoidCallback onNote;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: Row(
        children: [
          _Chip(
            icon: Icons.calendar_today_outlined,
            label: _fechaLabel(state.dateTime),
            tColor: tColor,
            onTap: onDate,
          ),
          const SizedBox(width: 8),
          _Chip(
            icon: Icons.credit_card_outlined,
            label: state.method.label,
            tColor: tColor,
            onTap: onMethod,
          ),
          const SizedBox(width: 8),
          _Chip(
            iconWidget: Icon(iconForName(state.category.iconName), size: 15),
            label: state.category.name,
            tColor: tColor,
            onTap: onCategory,
          ),
          const SizedBox(width: 8),
          _Chip(
            icon: Icons.edit_outlined,
            label: 'Nota',
            tColor: tColor,
            active: showDesc,
            onTap: onNote,
          ),
        ],
      ),
    );
  }
}

/// Etiqueta de fecha estilo diseño: "Hoy" / "Ayer" / "d MMM".
String _fechaLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
  return '${d.day} ${months[d.month - 1]}';
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.tColor,
    required this.onTap,
    this.icon,
    this.iconWidget,
    this.active = false,
  });

  final String label;
  final Color tColor;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? iconWidget;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    final on = active;
    return Material(
      color: on ? tColor.withValues(alpha: 0.14) : c.surface1,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: on ? tColor.withValues(alpha: 0.45) : c.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconWidget != null)
                IconTheme.merge(
                  data: IconThemeData(color: on ? c.textMedium : c.textMedium),
                  child: iconWidget!,
                )
              else if (icon != null)
                Icon(icon, size: 15, color: c.textMedium),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: on
                      ? Theme.of(context).colorScheme.onSurface
                      : c.textMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
