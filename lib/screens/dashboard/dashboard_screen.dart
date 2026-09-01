import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/machine_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../widgets/common_widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(machineProvider.notifier).loadMachines();
      ref.read(maintenanceProvider.notifier).loadMaintenances();
      ref.read(maintenanceProvider.notifier).loadChartData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final machineProv = ref.watch(machineProvider).value ?? [];
    final machineNotifier = ref.watch(machineProvider.notifier);
    final maintenanceProv = ref.watch(maintenanceProvider);
    final alerts = ref.watch(machineProvider.notifier).alerts;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(machineProvider.notifier).loadMachines();
        await ref.read(maintenanceProvider.notifier).loadMaintenances();
        await ref.read(maintenanceProvider.notifier).loadChartData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tableau de bord',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 150,
              ),
              children: [
                StatCard(
                  title: 'Machines',
                  value: '${machineProv.length}',
                  icon: Icons.precision_manufacturing_outlined,
                  color: AppColors.primary,
                ),
                StatCard(
                  title: 'Opérationnelles',
                  value: '${machineNotifier.operationalCount}',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
                StatCard(
                  title: 'Maintenance',
                  value: '${machineNotifier.maintenanceCount}',
                  icon: Icons.build_outlined,
                  color: AppColors.warning,
                ),
                StatCard(
                  title: 'Interventions',
                  value: '${maintenanceProv.totalCount}',
                  icon: Icons.engineering_outlined,
                  color: AppColors.secondary,
                ),
              ],
            ),
            if (alerts.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Alertes maintenance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...alerts.map((alert) {
                final message = alert.isOverdue
                    ? '${alert.machine.name}: Maintenance en retard (${-alert.daysRemaining} jours)'
                    : '${alert.machine.name}: Maintenance prévue dans ${alert.daysRemaining} jours';
                return AlertBanner(
                  message: message,
                  isOverdue: alert.isOverdue,
                );
              }),
            ],
            const SizedBox(height: 24),
            Text(
              'Interventions par mois',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 200,
                  child: maintenanceProv.monthlyData.isEmpty
                      ? const Center(child: Text('Aucune donnée'))
                      : _MonthlyChart(data: maintenanceProv.monthlyData),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Répartition des pannes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 200,
                  child: maintenanceProv.failureData.isEmpty
                      ? const Center(child: Text('Aucune panne enregistrée'))
                      : _FailureChart(data: maintenanceProv.failureData),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _MonthlyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data
        .map((d) => (d['count'] as int).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY + 1,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= data.length) return const SizedBox();
                final month = data[value.toInt()]['month'] as String;
                final parts = month.split('-');
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${parts[1]}/${parts[0].substring(2)}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        barGroups: List.generate(data.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: (data[i]['count'] as int).toDouble(),
                color: AppColors.primary,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _FailureChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _FailureChart({required this.data});

  static const _colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.warning,
    AppColors.success,
    AppColors.error,
    Colors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    final total = data.fold<int>(0, (sum, d) => sum + (d['count'] as int));

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: List.generate(data.length, (i) {
                final count = data[i]['count'] as int;
                return PieChartSectionData(
                  value: count.toDouble(),
                  title: '${(count / total * 100).toStringAsFixed(0)}%',
                  color: _colors[i % _colors.length],
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(data.length, (i) {
              final failure = data[i]['failure'] as String;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _colors[i % _colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        failure.length > 15
                            ? '${failure.substring(0, 15)}...'
                            : failure,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
