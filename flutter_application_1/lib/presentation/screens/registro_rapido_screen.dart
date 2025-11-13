import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaccion_model.dart';
import '../../app_providers.dart';

class RegistroRapidoScreen extends ConsumerStatefulWidget {
  const RegistroRapidoScreen({super.key});

  @override
  ConsumerState<RegistroRapidoScreen> createState() => _RegistroRapidoScreenState();
}

class _RegistroRapidoScreenState extends ConsumerState<RegistroRapidoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  int? _selectedCuentaId;
  int? _selectedCategoriaId;

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCuentaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona una cuenta')));
      return;
    }

    final monto = double.tryParse(_montoController.text.replaceAll(',', '.')) ?? 0.0;
    final tipo = _selectedCategoriaId == null ? 'Egreso' : 'Egreso'; // simple default; could infer by category

    final t = Transaccion(
      fecha: DateTime.now().toIso8601String(),
      monto: monto,
      descripcion: 'Registro rápido',
      cuentaId: _selectedCuentaId!,
      subcategoriaId: _selectedCategoriaId,
      tipo: tipo,
    );

    await ref.read(transaccionNotifierProvider.notifier).addTransaccion(t);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transacción registrada')));
    _montoController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final transacciones = ref.watch(transaccionNotifierProvider);
    final cuentasAsync = ref.watch(cuentasListProvider);
    final categoriasAsync = ref.watch(categoriasListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Registro rápido')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _montoController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Monto'),
                          autofocus: true,
                          validator: (v) {
                            final parsed = double.tryParse(v?.replaceAll(',', '.') ?? '0');
                            if (parsed == null || parsed <= 0) return 'Ingresa un monto válido > 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _guardar,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Cuenta dropdown
                  cuentasAsync.when(
                    data: (cuentas) {
                      if (_selectedCuentaId == null && cuentas.isNotEmpty) _selectedCuentaId = cuentas.first.id;
                      return DropdownButtonFormField<int>(
                        value: _selectedCuentaId,
                        decoration: const InputDecoration(labelText: 'Cuenta'),
                        items: cuentas.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.nombre} — ${c.saldoInicial.toStringAsFixed(2)}'))).toList(),
                        onChanged: (v) => setState(() => _selectedCuentaId = v),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Error cargando cuentas'),
                  ),

                  const SizedBox(height: 8),

                  // Categoria dropdown
                  categoriasAsync.when(
                    data: (cats) {
                      if (_selectedCategoriaId == null && cats.isNotEmpty) _selectedCategoriaId = cats.first.id;
                      return DropdownButtonFormField<int>(
                        value: _selectedCategoriaId,
                        decoration: const InputDecoration(labelText: 'Categoría'),
                        items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.nombre}'))).toList(),
                        onChanged: (v) => setState(() => _selectedCategoriaId = v),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Error cargando categorías'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Lista de transacciones
            Expanded(
              child: transacciones.isEmpty
                  ? const Center(child: Text('No hay transacciones aún'))
                  : ListView.separated(
                      itemCount: transacciones.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final t = transacciones[index];
                        return Dismissible(
                          key: ValueKey(t.id ?? index),
                          background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            final res = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirmar'),
                                content: const Text('¿Eliminar esta transacción?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar')),
                                ],
                              ),
                            );
                            return res == true;
                          },
                          onDismissed: (_) async {
                            if (t.id != null) await ref.read(transaccionNotifierProvider.notifier).deleteTransaccion(t.id!);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transacción eliminada')));
                          },
                          child: ListTile(
                            title: Text('${t.tipo} — ${t.monto.toStringAsFixed(2)}'),
                            subtitle: Text(t.descripcion ?? ''),
                            trailing: Text(
                              DateTime.tryParse(t.fecha) != null
                                  ? '${DateTime.parse(t.fecha).day}/${DateTime.parse(t.fecha).month}/${DateTime.parse(t.fecha).year}'
                                  : t.fecha,
                            ),
                          ),
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
