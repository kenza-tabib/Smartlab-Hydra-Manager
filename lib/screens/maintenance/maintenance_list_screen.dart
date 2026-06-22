import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_lab_hydra_manager/providers/machine_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/maintenance_provider.dart';
import '../../widgets/common_widgets.dart';
import '../reports/reports_screen.dart';
import 'maintenance_form_screen.dart';

class MaintenanceListScreen extends ConsumerStatefulWidget {
  const MaintenanceListScreen({super.key});

  @override
  ConsumerState<MaintenanceListScreen> createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends ConsumerState<MaintenanceListScreen> {
  final Map<int, String> _machineNames = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final machine = ref.read(machineProvider) ;
      final maintenanceProv = ref.read(maintenanceProvider.notifier);
    await ref.read(machineProvider.notifier).loadMachines();
    await maintenanceProv.loadMaintenances();

    for (final m in machine.value ?? []) {
      _machineNames[m.id!] = m.name;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final maintenanceProv = ref.read(maintenanceProvider);

    return Scaffold(
      body: maintenanceProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : maintenanceProv.maintenances.isEmpty
              ? EmptyState(
                  icon: Icons.build_outlined,
                  message: 'Aucune intervention enregistrée',
                  actionLabel: 'Nouvelle intervention',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MaintenanceFormScreen(),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: maintenanceProv.maintenances.length,
                    itemBuilder: (context, index) {
                      final m = maintenanceProv.maintenances[index];
                      final machineName =
                          _machineNames[m.machineId] ?? 'Machine #${m.machineId}';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: m.type ==
                                    AppConstants.maintenanceTypePreventive
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.warning.withValues(alpha: 0.15),
                            child: Icon(
                              m.type == AppConstants.maintenanceTypePreventive
                                  ? Icons.schedule
                                  : Icons.build,
                              color: m.type ==
                                      AppConstants.maintenanceTypePreventive
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                          title: Text(
                            machineName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${DateFormat('dd/MM/yyyy').format(DateTime.parse(m.date))} • ${m.type}',
                              ),
                              if (m.failure.isNotEmpty)
                                Text('Panne: ${m.failure}'),
                              Text('Technicien: ${m.technician}'),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReportsScreen(maintenance: m),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MaintenanceFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
