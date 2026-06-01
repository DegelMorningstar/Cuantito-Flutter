import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/cuantito_colors.dart';
import '../../core/di/providers.dart';
import '../../domain/exceptions.dart';
import '../../domain/models/category.dart';
import '../widgets/cuantito_sheet.dart';
import 'icon_catalog.dart';

/// Muestra el bottom sheet de categorías (rediseño): grilla de selección con
/// tile "Nueva" que abre el formulario de creación. Devuelve la [Category]
/// elegida o creada, o `null` si se cierra sin elegir.
///
/// Usa los mismos casos de uso que las pantallas (no toca dominio/datos):
/// `categoriesProvider`, `addCategoryProvider`.
Future<Category?> showCategorySheet(
  BuildContext context, {
  required int? selectedId,
  required Color accent,
}) {
  return showModalBottomSheet<Category>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CategorySheet(selectedId: selectedId, accent: accent),
  );
}

class _CategorySheet extends ConsumerStatefulWidget {
  const _CategorySheet({required this.selectedId, required this.accent});

  final int? selectedId;
  final Color accent;

  @override
  ConsumerState<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends ConsumerState<_CategorySheet> {
  bool _creating = false;
  final _nameController = TextEditingController();
  String _selectedIconName = kDefaultIconName;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final id = await ref.read(addCategoryProvider)(
        name: _nameController.text,
        iconName: _selectedIconName,
      );
      ref.invalidate(categoriesProvider);
      if (mounted) {
        Navigator.of(context).pop(
          Category(
            id: id,
            name: _nameController.text.trim(),
            iconName: _selectedIconName,
          ),
        );
      }
    } on EmptyCategoryNameException catch (e) {
      _message(e.message);
    } on CategoryAlreadyExistsException catch (e) {
      _message(e.message);
      _nameController.clear();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return CuantitoSheet(
      title: _creating ? 'Nueva categoría' : 'Categoría',
      child: _creating ? _buildForm() : _buildGrid(),
    );
  }

  Widget _buildGrid() {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text('No se pudieron cargar las categorías.\n$e',
            textAlign: TextAlign.center),
      ),
      data: (categories) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.15,
          children: [
            for (final cat in categories)
              _CategoryTile(
                icon: iconForName(cat.iconName),
                label: cat.name,
                selected: cat.id == widget.selectedId,
                accent: widget.accent,
                onTap: () => Navigator.of(context).pop(cat),
              ),
            // Tile "Nueva".
            _NewTile(onTap: () => setState(() => _creating = true)),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    final accent = widget.accent;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _formLabel('Icono'),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final group in catalogIconGroups) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 6),
                      child: Text(group.label,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: c.textDim)),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final ci in group.icons)
                          _IconChoice(
                            icon: ci.icon,
                            selected: ci.name == _selectedIconName,
                            accent: accent,
                            onTap: () =>
                                setState(() => _selectedIconName = ci.name),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _formLabel('Nombre'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(iconForName(_selectedIconName), size: 22, color: c.textMedium),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _create(),
                    decoration: const InputDecoration(
                      hintText: 'Ej: Mascotas',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                            _creating = false;
                            _nameController.clear();
                          }),
                  style: TextButton.styleFrom(
                    backgroundColor: c.surface2,
                    foregroundColor: c.textMedium,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _saving ? null : _create,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Crear categoría'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formLabel(String text) {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: c.textDim,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    return Material(
      color: selected ? accent.withValues(alpha: 0.16) : c.surface2,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent.withValues(alpha: 0.5) : Colors.transparent,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26,
                  color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: c.textMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewTile extends StatelessWidget {
  const _NewTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: DottedBorderBox(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 26, color: c.textDim),
            const SizedBox(height: 6),
            Text('Nueva',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: c.textDim)),
          ],
        ),
      ),
    );
  }
}

/// Caja con borde punteado (tile "Nueva").
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.surface3, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      child: child,
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.2) : c.surface2,
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: accent, width: 2) : null,
        ),
        child: Icon(icon,
            size: 22,
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : c.textMedium),
      ),
    );
  }
}
