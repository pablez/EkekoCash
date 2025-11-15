import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'registro_rapido_screen.dart';
import 'fondos_screen.dart';
import 'categorias_screen.dart';
import '../../app_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const RegistroRapidoScreen(),
      _CuentasPage(),
      const FondosScreen(),
      const _ReportesPage(),
      const CategoriasScreen(),
    ];

    // Read categories to show a small badge with count on the navigation icon
    final categorias = ref.watch(categoriasNotifierProvider);
    Widget categoriasIcon = Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.category),
        if (categorias.isNotEmpty)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 16),
              child: Text(
                categorias.length > 99 ? '99+' : categorias.length.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
       bottomNavigationBar: AnimatedContainer(
         duration: const Duration(milliseconds: 300),
         curve: Curves.easeInOut,
         decoration: BoxDecoration(
           color: Colors.white,
           boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12, spreadRadius: 1, offset: const Offset(0, -3)),
           ],
         ),
         child: SafeArea(
           child: BottomNavigationBar(
             type: BottomNavigationBarType.fixed,
             elevation: 0,
             backgroundColor: Colors.transparent,
             selectedItemColor: Theme.of(context).colorScheme.primary,
             unselectedItemColor: Colors.grey.shade600,
             showUnselectedLabels: true,
             selectedFontSize: 13,
             unselectedFontSize: 12,
             currentIndex: _selectedIndex,
             onTap: _onItemTapped,
             items: [
               BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Registro'),
               BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Cuentas'),
               BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Fondos'),
               BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), label: 'Reportes'),
               BottomNavigationBarItem(icon: categoriasIcon, label: 'Categorías'),
             ],
           ),
         ),
       ),
      floatingActionButton: _selectedIndex == 0
          ? null
          : FloatingActionButton(
              onPressed: () {
                // acción rápida para añadir cuenta o generar reporte
                if (_selectedIndex == 1) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Añadir cuenta (pendiente)')));
                } else if (_selectedIndex == 2) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crear fondo (usa la UI)')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generar reporte (pendiente)')));
                }
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}

class _CuentasPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentasAsync = ref.watch(cuentasListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas')),
      body: cuentasAsync.when(
        data: (cuentas) => ListView.separated(
          itemCount: cuentas.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final c = cuentas[index];
            return ListTile(
              title: Text(c.nombre),
              subtitle: Text('Saldo: ${c.saldoInicial.toStringAsFixed(2)}'),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error cargando cuentas')),
      ),
    );
  }
}

class _ReportesPage extends StatelessWidget {
  const _ReportesPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: const Center(child: Text('Próximamente: reportes y gráficos')),
    );
  }
}
