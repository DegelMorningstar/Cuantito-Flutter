import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../domain/exceptions.dart';
import 'icon_catalog.dart';

/// Creación de una categoría: nombre + icono del catálogo (RN-005, RN-008).
///
/// Valida nombre vacío y duplicado mostrando un `SnackBar` (equivalente a los
/// `Toast` del origen). Al guardar con éxito invalida `categoriesProvider` y
/// devuelve `true` por navegación.
class NewCategoryPage extends ConsumerStatefulWidget {
  const NewCategoryPage({super.key});

  @override
  ConsumerState<NewCategoryPage> createState() => _NewCategoryPageState();
}

class _NewCategoryPageState extends ConsumerState<NewCategoryPage> {
  final _nameController = TextEditingController();
  String _selectedIconName = kDefaultIconName;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(addCategoryProvider)(
        name: _nameController.text,
        iconName: _selectedIconName,
      );
      ref.invalidate(categoriesProvider);
      if (mounted) context.pop(true);
    } on EmptyCategoryNameException catch (e) {
      _showMessage(e.message);
    } on CategoryAlreadyExistsException catch (e) {
      _showMessage(e.message);
      _nameController.clear(); // limpia el campo, como el origen.
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva categoría'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colors.primaryContainer,
                  child: Icon(
                    iconForName(_selectedIconName),
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _save(),
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la categoría',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final group in catalogIconGroups)
                  _IconGroupSection(
                    group: group,
                    selectedIconName: _selectedIconName,
                    onSelected: (name) =>
                        setState(() => _selectedIconName = name),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconGroupSection extends StatelessWidget {
  const _IconGroupSection({
    required this.group,
    required this.selectedIconName,
    required this.onSelected,
  });

  final IconGroup group;
  final String selectedIconName;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            group.label,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final catalogIcon in group.icons)
              _IconButton(
                icon: catalogIcon.icon,
                isSelected: catalogIcon.name == selectedIconName,
                color: colors,
                onTap: () => onSelected(catalogIcon.name),
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final ColorScheme color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? color.primaryContainer : color.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: color.primary, width: 2)
              : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? color.onPrimaryContainer : color.onSurfaceVariant,
        ),
      ),
    );
  }
}
