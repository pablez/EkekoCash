import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/fondo_model.dart';
import '../../data/models/asignacion_model.dart';
import '../../app_providers.dart';
import '../../data/repositories/fondo_repository.dart';

class FondosScreen extends ConsumerStatefulWidget {
  const FondosScreen({super.key});

  @override
  ConsumerState<FondosScreen> createState() => _FondosScreenState();
}

class _FondosScreenState extends ConsumerState<FondosScreen> {
  final _nombreCtrl = TextEditingController();
  final _metaCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _metaCtrl.dispose();
    super.dispose();
  }

  Future<void> _crearFondo() async {
    final nombre = _nombreCtrl.text.trim();
    final meta = double.tryParse(_metaCtrl.text.replaceAll(',', '.')) ?? 0.0;
    if (nombre.isEmpty || meta <= 0) return;
    final f = Fondo(nombre: nombre, metaMonto: meta);
    await ref.read(fondosNotifierProvider.notifier).addFondo(f);
    _nombreCtrl.clear();
    _metaCtrl.clear();
  }

  Future<void> _showAsignaciones(Fondo f) async {
    final repo = ref.read(fondoRepositoryProvider);
    await showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return FutureBuilder<List<AsignacionAhorro>>(
          future: repo.getAsignacionesByFondo(f.id!),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            final items = snap.data ?? [];
            if (items.isEmpty) return SizedBox(height: 200, child: Center(child: Text('No hay asignaciones')));
            return SizedBox(
              height: 300,
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final a = items[i];
                  return ListTile(
                    title: Text('${a.montoAsignado.toStringAsFixed(2)}'),
                    subtitle: Text('Transacción: ${a.transaccionId}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () async {
                        await repo.deleteAsignacion(a.id!);
                        // refresh fondos list
                        await ref.read(fondosNotifierProvider.notifier).refresh();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asignación eliminada')));
                        Navigator.of(context).pop();
                        await _showAsignaciones(f); // reopen to refresh
                      },
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fondos = ref.watch(fondosNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Fondos')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: _metaCtrl, decoration: const InputDecoration(labelText: 'Meta monto'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _crearFondo, child: const Text('Crear fondo')),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: fondos.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final f = fondos[i];
                  return ListTile(
                    title: Text(f.nombre),
                    subtitle: Text('Meta: ${f.metaMonto.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.list),
                      onPressed: () => _showAsignaciones(f),
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
