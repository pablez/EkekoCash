import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_providers.dart';
import '../../data/models/categoria_model.dart';

class CategoriasScreen extends ConsumerWidget {
  const CategoriasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categorias = ref.watch(categoriasNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: ListView.separated(
        itemCount: categorias.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final c = categorias[index];
          return Slidable(
            key: ValueKey(c.categoriaId ?? index),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              children: [
                CustomSlidableAction(
                  onPressed: (ctx) => _showEditor(context, ref, c),
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.95),
                  foregroundColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.edit, size: 22, color: Colors.white),
                    const SizedBox(height: 6),
                    Text('Editar', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
                CustomSlidableAction(
                  onPressed: (ctx) async {
                    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Confirmar'), content: Text('Eliminar ${c.nombre}?'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar'))]));
                    if (ok == true) await ref.read(categoriasNotifierProvider.notifier).deleteCategoria(c.categoriaId!);
                  },
                  backgroundColor: Colors.redAccent.shade400,
                  foregroundColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.delete, size: 22, color: Colors.white),
                    const SizedBox(height: 6),
                    Text('Eliminar', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ],
            ),
            child: ListTile(
              leading: c.iconName != null
                  ? CircleAvatar(
                      backgroundColor: c.colorHex != null ? Color(int.parse(c.colorHex!.replaceFirst('#', '0xFF'))) : Colors.transparent,
                      child: Padding(padding: const EdgeInsets.all(6), child: SvgPicture.asset('assets/icons/${c.iconName}.svg', color: c.colorHex != null ? Colors.white : null)),
                    )
                  : (c.colorHex != null ? CircleAvatar(backgroundColor: Color(int.parse(c.colorHex!.replaceFirst('#', '0xFF')))) : null),
              title: Text(c.nombre),
              subtitle: Text(c.tipo),
              trailing: IconButton(icon: const Icon(Icons.list), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GastosPorCategoriaScreen(categoria: c)))),
              onTap: () => _showEditor(context, ref, c),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditor(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditor(BuildContext context, WidgetRef ref, Categoria? c) {
    final nombreController = TextEditingController(text: c?.nombre ?? '');
    String tipo = c?.tipo ?? 'Egreso';

    showDialog(context: context, builder: (ctx) {
      String selectedColor = c?.colorHex ?? '';
      String selectedIcon = c?.iconName ?? '';
      String errorText = '';
      final predefined = ['#FF5722', '#4CAF50', '#2196F3', '#FFC107', '#9C27B0', '#F44336', ''];
      final icons = [
        'money', 'food', 'shopping', 'cart', 'water', 'thunder', 'gas', 'drumstick', 'car', 'tshirt', 'pill', 'tooth', 'gift',
        'home', 'bank', 'education', 'entertainment', 'health', 'wifi', 'phone', 'coffee', 'book', 'sport', 'beauty', 'fuel'
      ];

      return StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: Text(c == null ? 'Nueva categoría' : 'Editar categoría'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nombreController, decoration: InputDecoration(labelText: 'Nombre', errorText: errorText.isEmpty ? null : errorText)),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: Text('Icono')),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: icons.map((icon) {
                  final isSelected = selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => selectedIcon = icon),
                    child: Container(
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.grey.shade200 : Colors.transparent,
                        border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300, width: isSelected ? 2 : 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SvgPicture.asset('assets/icons/$icon.svg', semanticsLabel: icon, color: isSelected ? Colors.black : null),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: Text('Color')), 
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: predefined.map((hex) {
                  final display = hex.isEmpty ? null : Color(int.parse(hex.replaceFirst('#', '0xFF')));
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = hex),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: display ?? Colors.transparent,
                        border: Border.all(color: selectedColor == hex ? Colors.black : Colors.grey.shade300, width: selectedColor == hex ? 2 : 1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: display == null ? const Icon(Icons.clear, size: 18) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: RadioListTile<String>(value: 'Ingreso', groupValue: tipo, title: const Text('Ingreso'), onChanged: (v) => setState(() => tipo = v!))),
                Expanded(child: RadioListTile<String>(value: 'Egreso', groupValue: tipo, title: const Text('Egreso'), onChanged: (v) => setState(() => tipo = v!))),
              ])
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            TextButton(onPressed: () async {
              final nombre = nombreController.text.trim();
              if (nombre.isEmpty) {
                setState(() => errorText = 'Nombre requerido');
                return;
              }
              final color = selectedColor.trim();
              if (c == null) {
                await ref.read(categoriasNotifierProvider.notifier).addCategoria(Categoria(
                  nombre: nombre,
                  tipo: tipo,
                  colorHex: color.isEmpty ? null : color,
                  iconName: selectedIcon.isEmpty ? null : selectedIcon,
                ));
              } else {
                await ref.read(categoriasNotifierProvider.notifier).updateCategoria(Categoria(
                  categoriaId: c.categoriaId,
                  nombre: nombre,
                  tipo: tipo,
                  colorHex: color.isEmpty ? null : color,
                  iconName: selectedIcon.isEmpty ? null : selectedIcon,
                ));
              }
              Navigator.of(ctx).pop();
            }, child: const Text('Guardar'))
          ],
        );
      });
    });
  }
}

class GastosPorCategoriaScreen extends ConsumerWidget {
  final Categoria categoria;
  const GastosPorCategoriaScreen({required this.categoria, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(categoriaRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Gastos: ${categoria.nombre}')),
      body: FutureBuilder(
        future: repo.getTransaccionesByCategoria(categoria.categoriaId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          final List trans = snapshot.data as List? ?? [];
          if (trans.isEmpty) return const Center(child: Text('No hay transacciones en esta categoría'));
          return ListView.separated(
            itemCount: trans.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final t = trans[index];
              return ListTile(
                title: Text('${t.tipo} — ${t.monto.toStringAsFixed(2)}'),
                subtitle: Text(t.descripcion ?? ''),
                trailing: Text(DateTime.tryParse(t.fecha) != null ? '${DateTime.parse(t.fecha).day}/${DateTime.parse(t.fecha).month}/${DateTime.parse(t.fecha).year}' : t.fecha),
              );
            },
          );
        },
      ),
    );
  }
}
