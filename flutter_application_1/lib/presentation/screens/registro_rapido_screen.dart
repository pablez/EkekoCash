import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../data/models/transaccion_model.dart';
import '../../data/models/asignacion_model.dart';
import '../../data/models/fondo_model.dart';
import '../../app_providers.dart';

class RegistroRapidoScreen extends ConsumerStatefulWidget {
  const RegistroRapidoScreen({super.key});

  @override
  ConsumerState<RegistroRapidoScreen> createState() => _RegistroRapidoScreenState();
}

class _RegistroRapidoScreenState extends ConsumerState<RegistroRapidoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  String _selectedTipo = 'Egreso';
  bool _isAsignDialogOpen = false;
  int? _selectedCuentaId;
  int? _selectedCategoriaId;

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCuentaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona una cuenta')));
      return;
    }

    if (_selectedTipo == 'Egreso' && _selectedCategoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona una categoría para gastos')));
      return;
    }

    final monto = double.tryParse(_montoController.text.replaceAll(',', '.')) ?? 0.0;
    final tipo = _selectedTipo;

    final t = Transaccion(
      fecha: DateTime.now().toIso8601String(),
      monto: monto,
      descripcion: _descripcionController.text.isEmpty ? null : _descripcionController.text,
      cuentaId: _selectedCuentaId!,
      categoriaId: _selectedCategoriaId,
      tipo: tipo,
    );

    final inserted = await ref.read(transaccionNotifierProvider.notifier).addTransaccion(t);
    if (!mounted) return;
    final repo = ref.read(fondoRepositoryProvider);
    double assignedTotal = 0.0;
    if (inserted.id != null) {
      final asignsForTx = await repo.getAsignacionesByTransaccion(inserted.id!);
      assignedTotal = asignsForTx.fold<double>(0.0, (s, a) => s + a.montoAsignado);
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      content: Row(
        children: [
          const Expanded(child: Text('Transacción registrada')),
          if (assignedTotal > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(12)),
              child: Text('Asignado: ${assignedTotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
        ],
      ),
      action: SnackBarAction(label: 'Asignar', onPressed: () {
        // abrir diálogo de asignación si el usuario decide hacerlo
        _maybeAskAsignacion(inserted);
      }),
      duration: const Duration(seconds: 6),
    ));

    // Mostrar animación de confirmación breve (asset local) pero retrasada
    // para no bloquear inmediatamente la pantalla (permite interactuar con el SnackBar en tests).
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      // Mostrar un overlay ligero y no modal con la animación (auto-cierra)
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Registro confirmado',
        barrierColor: Colors.transparent,
        pageBuilder: (ctx, a1, a2) {
          return SafeArea(
            child: Builder(builder: (ctx) {
              Future.delayed(const Duration(milliseconds: 1200), () {
                if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
              });
              return Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(color: Theme.of(context).dialogBackgroundColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)]),
                  padding: const EdgeInsets.all(12),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(width: 80, height: 80, child: Lottie.asset('assets/animations/success.json', repeat: false)),
                    const SizedBox(height: 8),
                    const Text('¡Registrado!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
                ),
              );
            }),
          );
        },
        transitionBuilder: (ctx, a1, a2, child) => FadeTransition(opacity: CurvedAnimation(parent: a1, curve: Curves.easeOut), child: child),
        transitionDuration: const Duration(milliseconds: 200),
      );
    });

    // Si es ingreso, abrir diálogo de asignación automáticamente (no await para no bloquear flujo)
    if (t.tipo == 'Ingreso') {
      _maybeAskAsignacion(inserted);
    }
    _montoController.clear();
  }

  Future<void> _maybeAskAsignacion(Transaccion t) async {
    // Sólo preguntar por asignación si es un ingreso
    if (t.tipo != 'Ingreso') return;
    final fondos = ref.read(fondosNotifierProvider);
    // Evitar reentradas: si ya hay un diálogo abierto no abrir otro
    if (_isAsignDialogOpen) return;
        
    if (fondos.isEmpty) return;

    // Precompute assigned amount for the initial fondo
    final repo = ref.read(fondoRepositoryProvider);
    int currentAssignedCents = 0;
    if (fondos.isNotEmpty) {
      final asigns = await repo.getAsignacionesByFondo(fondos.first.id!);
      currentAssignedCents = asigns.fold<int>(0, (s, a) => s + a.montoAsignadoCents);
    }

    _isAsignDialogOpen = true;
    await showDialog<bool>(
      context: context,
      builder: (ctx) {
        int? selectedFondoId = fondos.first.id;
        double percent = 0.0;
        double assignedAmount = 0.0;
        int currentAssigned = currentAssignedCents; // cents
        final assignController = TextEditingController();

        return StatefulBuilder(builder: (context, setState) {
          final Fondo currentFondo = fondos.firstWhere((ft) => ft.id == selectedFondoId, orElse: () => fondos.first);
          final double fondoMeta = currentFondo.metaMonto; // in currency units
          final double alreadyAssigned = currentAssigned / 100.0;
          final double remainingForFondo = (fondoMeta - alreadyAssigned).clamp(0.0, double.infinity);

          final double maxAssignable = remainingForFondo < t.monto ? remainingForFondo : t.monto;
          final double maxPercent = t.monto > 0 ? (maxAssignable / t.monto) * 100.0 : 0.0;

          void updateFromPercent(double p) {
            percent = p.clamp(0.0, maxPercent);
            assignedAmount = (t.monto * percent / 100.0);
            assignController.text = assignedAmount.toStringAsFixed(2);
          }

          void updateFromAmount(String text) {
            final parsed = double.tryParse(text.replaceAll(',', '.')) ?? 0.0;
            final clamped = parsed.clamp(0.0, maxAssignable);
            assignedAmount = clamped;
            percent = t.monto > 0 ? (assignedAmount / t.monto) * 100.0 : 0.0;
            setState(() {});
          }

          // initialize controllers
          if (assignController.text.isEmpty) assignController.text = '0.00';

          return AlertDialog(
            title: const Text('Asignar a fondo'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedFondoId,
                    items: fondos.map((f) => DropdownMenuItem(value: f.id, child: Text(f.nombre))).toList(),
                    onChanged: (v) async {
                      selectedFondoId = v;
                      if (v != null) {
                        final asigns = await repo.getAsignacionesByFondo(v);
                        setState(() {
                          currentAssigned = asigns.fold<int>(0, (s, a) => s + a.montoAsignadoCents);
                        });
                      }
                      setState(() {});
                    },
                    decoration: const InputDecoration(labelText: 'Fondo'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Meta: ${fondoMeta.toStringAsFixed(2)}'),
                      Text('Asignado: ${alreadyAssigned.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: percent,
                          min: 0.0,
                          max: maxPercent > 0 ? maxPercent : 0.0,
                          divisions: maxPercent > 0 ? (maxPercent.clamp(1.0, 100.0)).round() : 1,
                          label: '${percent.toStringAsFixed(0)}%',
                          onChanged: maxPercent > 0
                              ? (v) => setState(() => updateFromPercent(v))
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: assignController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            labelText: 'Monto',
                            prefixIcon: Icon(Icons.monetization_on, size: 18),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          ),
                          onChanged: (s) => updateFromAmount(s),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(alignment: Alignment.centerLeft, child: Text('Asignando: ${assignedAmount.toStringAsFixed(2)}')),
                  const SizedBox(height: 6),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Saldo restante: ${(remainingForFondo - assignedAmount).clamp(0.0, double.infinity).toStringAsFixed(2)}')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
              TextButton(
                onPressed: (assignedAmount <= 0 || assignedAmount > maxAssignable || selectedFondoId == null || t.id == null)
                    ? null
                    : () async {
                        final usecase = ref.read(createAsignacionUseCaseProvider);
                        await usecase.execute(AsignacionAhorro(montoAsignado: assignedAmount, transaccionId: t.id!, fondoId: selectedFondoId!));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Asignado ${assignedAmount.toStringAsFixed(2)} al fondo')));
                        Navigator.of(ctx).pop(true);
                      },
                child: const Text('Confirmar'),
              ),
            ],
          );
        });
      },
    );

    _isAsignDialogOpen = false;
    return;
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
                  // Tipo: Ingreso / Egreso
                  Row(
                    children: [
                      ToggleButtons(
                        isSelected: [_selectedTipo == 'Ingreso', _selectedTipo == 'Egreso'],
                        onPressed: (index) => setState(() {
                          _selectedTipo = index == 0 ? 'Ingreso' : 'Egreso';
                        }),
                        children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Ingreso')), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Egreso'))],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _descripcionController,
                          decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                        ),
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
                        items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
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
                            // Guardar copia para posible undo
                            final deleted = Transaccion(
                              id: t.id,
                              fecha: t.fecha,
                              monto: t.monto,
                              descripcion: t.descripcion,
                              cuentaId: t.cuentaId,
                              subcategoriaId: t.subcategoriaId,
                              miembroId: t.miembroId,
                              tipo: t.tipo,
                            );

                            final messenger = ScaffoldMessenger.of(context);
                            if (t.id != null) await ref.read(transaccionNotifierProvider.notifier).deleteTransaccion(t.id!);
                            messenger.clearSnackBars();
                            messenger.showSnackBar(SnackBar(
                              content: const Text('Transacción eliminada'),
                              action: SnackBarAction(
                                label: 'UNDO',
                                onPressed: () async {
                                  // Re-crear la transacción (se insertará y actualizará saldo)
                                  await ref.read(transaccionNotifierProvider.notifier).addTransaccion(
                                    Transaccion(
                                      fecha: deleted.fecha,
                                      monto: deleted.monto,
                                      descripcion: deleted.descripcion,
                                      cuentaId: deleted.cuentaId,
                                      subcategoriaId: deleted.subcategoriaId,
                                      miembroId: deleted.miembroId,
                                      tipo: deleted.tipo,
                                    ),
                                  );
                                },
                              ),
                              duration: const Duration(seconds: 4),
                            ));
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
