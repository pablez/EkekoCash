class DashboardKpis {
  final double totalIngresos;
  final double totalEgresos;
  final double totalBalance;
  final double ahorroAsignado;
  final double totalMetaFondos;

  DashboardKpis({
    required this.totalIngresos,
    required this.totalEgresos,
    required this.totalBalance,
    required this.ahorroAsignado,
    this.totalMetaFondos = 0.0,
  });
}
